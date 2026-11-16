#!/bin/bash
set -euo pipefail

# =============================================================================
# Pull envoy.yaml (and, if present, vector.toml) from OCI Object Storage.
# =============================================================================
# THIS SCRIPT HAS NO GCP COUNTERPART IN THE IMAGE, AND THAT IS THE DIVERGENCE
# WORTH UNDERSTANDING BEFORE CHANGING ANYTHING HERE.
#
# GCP's envoy image deliberately bakes in NO config fetch. Its README records
# the decision and the date: "Config delivery - moved to the live layer
# (2026-08-20)... pulling envoy.yaml/vector.toml from the config bucket and
# restarting the services is now the consuming live-layer unit's job, via a GCE
# startup-script wired through the composition module's
# `custom_startup_script` variable - exactly mirroring the AWS AMI +
# templates/userdata.sh split." That was a good decision for GCP: it moves
# orchestration logic out of a thing that needs a rebuild and into a thing that
# needs an edit.
#
# IT DOES NOT PORT, because the seam it depends on does not exist on OCI:
#   * terraform/oci/modules/composition/envoy-proxy has no
#     `custom_startup_script`. It has `custom_user_data`, and the catalog unit
#     (hyperswitch-infra:terraform/catalog/units/oci/envoy-proxy) does not set
#     it - there is no live-layer script anywhere in the OCI tree.
#   * The module instead puts `config_bucket`, `config_namespace` and
#     `envoy_region` into `metadata` (locals.tf, `base_metadata`), which is ai
#     statement that the IMAGE is expected to read them. Its squid sibling says
#     so in as many words next to the same block: "The image's boot script and
#     its 15-minute refresh timer read these off the metadata service rather
#     than having the bucket baked in, which is what lets one image serve every
#     environment."
#
# So on OCI the fetch belongs in the image. If a `custom_user_data`-driven live
# layer is ever added to the OCI envoy-proxy unit, this script is the first
# thing that should move out to it, and this comment is the argument for doing
# so.
#
# AUTHENTICATION EXISTS TODAY, THROUGH AN INSTANCE PRINCIPAL. Since
# 2026-09-10 each composition module creates its own dynamic group and policy
# (composition/envoy-proxy/identity.tf), so `oci os object get --auth
# instance_principal` succeeds at boot. The fail-soft path below is therefore
# no longer the normal code path - it is kept only to tolerate a genuinely
# missing config object (e.g. a fresh fleet whose bucket object has not been
# populated yet), in which case this script leaves the baked-in default
# envoy.yaml in place, which answers 503 to everything including the load
# balancer's health check. See scripts/envoy.yaml.default for why an honest
# unhealthy instance beats both a crash loop and a lying 200.
# =============================================================================

IMDS="http://169.254.169.254/opc/v2/instance/metadata"
HDR="Authorization: Bearer Oracle"

md() { curl -sf -H "${HDR}" "${IMDS}/$1" 2>/dev/null | tr -d '"' || true; }

CONFIG_BUCKET=$(md config_bucket)
CONFIG_NAMESPACE=$(md config_namespace)
CONFIG_OBJECT=$(md envoy_config_object)
CONFIG_OBJECT="${CONFIG_OBJECT:-envoy.yaml}"

if [ -z "${CONFIG_BUCKET}" ] || [ -z "${CONFIG_NAMESPACE}" ]; then
  echo "fetch-envoy-config: no config_bucket/config_namespace metadata set, leaving baked-in /etc/envoy/envoy.yaml in place" >&2
  exit 0
fi

fetch() {
  # $1 object name, $2 destination file. Returns non-zero and prints nothing
  # useful on failure; every caller decides for itself whether that is fatal.
  oci os object get \
    --auth instance_principal \
    --namespace "${CONFIG_NAMESPACE}" \
    --bucket-name "${CONFIG_BUCKET}" \
    --name "$1" \
    --file "$2" >/dev/null 2>&1
}

TMP_ENVOY=$(mktemp)
TMP_VECTOR=$(mktemp)
trap 'rm -f "${TMP_ENVOY}" "${TMP_VECTOR}"' EXIT

if ! fetch "${CONFIG_OBJECT}" "${TMP_ENVOY}"; then
  echo "fetch-envoy-config: could not fetch ${CONFIG_OBJECT} from ${CONFIG_BUCKET} (no instance principal yet?), leaving baked-in config in place" >&2
else
  # Validate BEFORE installing. `envoy --mode validate` fully parses and
  # bootstraps the config without binding any listener, so a broken config
  # pushed to the bucket cannot take the fleet down on the next boot - the
  # instance keeps serving whatever it was serving. Neither the AWS userdata
  # nor GCP's startup-script does this check.
  # THE CANDIDATE PATH MUST END IN .yaml. Envoy selects its config PARSER from
  # the file extension, not from the content: `.yaml`/`.yml` parse as YAML,
  # everything else falls through to JSON/protobuf. A candidate named
  # `envoy.yaml.candidate` ends in `.candidate`, so Envoy tried to parse the
  # YAML as JSON and ALWAYS failed:
  #   error initializing configuration '/etc/envoy/envoy.yaml.candidate':
  #   Unable to parse JSON as proto (INVALID_ARGUMENT: invalid JSON in
  #   envoy.config.bootstrap.v3.Bootstrap, near 1:1 (offset 0):
  #   unexpected character: '#'; expected '{')
  #
  # That made this validation gate unpassable for EVERY config, so the fetch
  # path could never install anything and the fleet served the baked-in 503
  # forever - while the fetch itself, the instance principal, the policy and
  # the object content were all perfectly fine. Diagnosed 2026-09-10 by
  # tracing this script on a live instance (`bash -x`) and then reproducing
  # both extensions against envoyproxy/envoy:v1.39-latest:
  #   envoy.yaml           -> configuration OK
  #   envoy.yaml.candidate -> Unable to parse JSON as proto
  #
  # `.candidate.yaml` keeps the "this is not the live file yet" signal in the
  # name while giving Envoy the extension it needs.
  install -o root -g envoy -m 0640 "${TMP_ENVOY}" /etc/envoy/envoy.candidate.yaml
  if envoy -c /etc/envoy/envoy.candidate.yaml --mode validate >/dev/null 2>&1; then
    cp -a /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml.old 2>/dev/null || true
    install -o root -g envoy -m 0640 /etc/envoy/envoy.candidate.yaml /etc/envoy/envoy.yaml

    # `--mode validate` OPENS the access-log files named in the config, and
    # this script runs as root - so validating a config whose access_log path
    # does not exist yet CREATES it owned by root:root. envoy.service runs as
    # `User=envoy` and then cannot write it, so the process dies a second or
    # two after a restart that systemd reports as successful. Confirmed on a
    # live instance 2026-09-10 (restart "succeeded", then Connection refused
    # on :8080). Harmless when the path already exists as envoy:envoy, which
    # is why the baked-in default never tripped it.
    chown -R envoy:envoy /var/log/envoy 2>/dev/null || true

    # Control 12c: the delivered config is root-owned (group envoy) so the
    # envoy user cannot rewrite its own config, and /etc/envoy is root:envoy
    # 0750 (envoy needs group read+traverse, not ownership).
    chown root:envoy /etc/envoy 2>/dev/null || true
    chmod 0750 /etc/envoy 2>/dev/null || true

    echo "fetch-envoy-config: installed ${CONFIG_OBJECT} from ${CONFIG_BUCKET}"
  else
    echo "fetch-envoy-config: fetched config FAILED 'envoy --mode validate', refusing to install it; keeping the previous /etc/envoy/envoy.yaml" >&2
  fi
  rm -f /etc/envoy/envoy.candidate.yaml
fi

# vector.toml is optional: the envoy-proxy unit ships envoy.yaml through
# `envoy_config_content` and would only ship a vector.toml through
# `additional_config_files`, which no environment sets today. A missing object
# is not an error.
if fetch vector.toml "${TMP_VECTOR}"; then
  if /usr/bin/vector validate "${TMP_VECTOR}" >/dev/null 2>&1; then
    install -o root -g vector -m 0640 "${TMP_VECTOR}" /etc/vector/vector.toml
    echo "fetch-envoy-config: installed vector.toml from ${CONFIG_BUCKET}"
    systemctl restart --no-block vector.service || true
  else
    echo "fetch-envoy-config: fetched vector.toml failed 'vector validate', keeping the baked-in one" >&2
  fi
fi

# Same --no-block reasoning as the squid image's fetch script, and it applies
# here for the identical structural reason: envoy-config-fetch.service carries
# Before=envoy.service, so a BLOCKING `systemctl restart envoy.service` from
# inside this script deadlocks against its own ordering constraint. At boot
# there is nothing to restart anyway - envoy.service starts immediately after
# this unit and reads whatever is on disk.
if systemctl is-active --quiet envoy.service; then
  systemctl restart --no-block envoy.service
fi
