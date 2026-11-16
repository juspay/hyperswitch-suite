[sources.squid_logs]
  type = "file"
  include = [ "/var/log/squid/access.log" ]
  read_from = "end"

[api]
  enabled = true

[sinks.sink_loki]
type = "loki"
inputs = ["squid_logs"]
endpoint = "${loki_endpoint}"
encoding.codec = "json"
labels.job = "vector/squid-${environment}"
labels.service = "squid"
labels.cloud = "oci"
# Without this, Vector's startup healthcheck for this sink is fatal to the
# whole process if the endpoint is unreachable ("vector validate" exits
# 78/CONFIG and systemd never starts the service at all - confirmed on the
# GCP side by a real live failure on 2026-08-20 while loki_endpoint pointed
# at a not-yet-reachable Loki). Disabling it lets Vector start and tail the
# log locally regardless of sink reachability, retrying delivery in the
# background instead of blocking startup - the right default even once a
# real, usually-reachable endpoint is wired in.
#
# It matters MORE on OCI than it did on GCP: there is no Loki deployed
# anywhere in this OCI environment at all yet (loki is a phase-3 application
# unit and phase 3 currently has exactly one unit, oke-workload-identity), so
# the default endpoint below is guaranteed unreachable, not merely likely to
# be.
healthcheck.enabled = false
