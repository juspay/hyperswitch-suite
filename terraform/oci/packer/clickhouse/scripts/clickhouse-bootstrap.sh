#!/bin/bash
set -euo pipefail

# =============================================================================
# clickhouse-bootstrap.sh - render a ClickHouse node from OCI IMDS user_data
# =============================================================================
# THE CONTRACT (plan .omo/plans/oci-kafka-clickhouse-images.md section 4 - this
# image is the contract owner; the catalog unit's user_data template MUST match):
#
#   user_data JSON (base64-encoded in the instance metadata, delivered by the
#   composition module's server_user_data_template):
#
#     { "type": "server",
#       "clusterName": "hyperswitch-clickhouse-ec2",
#       "dataPaths": ["/var/lib/clickhouse/data", "/var/lib/clickhouse/data2"],
#       "httpPort": 8123,
#       "tcpPort": 9000 }
#
# Runs at every boot (idempotent), before clickhouse-server.service (ordering +
# gating owned by clickhouse-bootstrap.service and the Requires= drop-in in
# clickhouse-server-bootstrap.conf). FAIL CLOSED: on any missing/invalid field,
# any absent volume, or any render problem, this script logs loudly and exits
# non-zero, and the systemd gate keeps clickhouse-server stopped. A node with no
# delivered user_data never serves - it never silently runs on its root disk.
#
# What it does, in order:
#   1. Fetch user_data from IMDS v2 (http://169.254.169.254/opc/v2, the same
#      mechanism as ../shared/scripts/populate-oci-metadata.sh) and validate it
#      against the contract above. Every field is REQUIRED - fail-closed.
#   2. Bring up reserved secondary private IPs (the composition module pins
#      oci_core_private_ip addresses onto the primary VNIC; OCI DHCP only
#      configures the primary address, so the stable server_private_ips
#      identity needs an in-guest `ip addr add`, same reason as the kafka
#      contract's advertisedIp handling). Idempotent.
#   3. Mount the two persistent data volumes BY FILESYSTEM LABEL (CH-DATA,
#      CH-DATA2) at dataPaths[0]/dataPaths[1], format-if-blank on first boot,
#      fail-fast if absent. Labels, never device paths: paravirtualized vs
#      iscsi naming differs (check-sheet 9.2), and after first boot the LABEL
#      is the only stable identity.
#   4. Render /etc/clickhouse-server/config.d/overrides.xml (paths -> the
#      mounted volumes as a two-disk default policy, listen host, ports) and
#      users.d/overrides.xml (network-layer auth parity - see the render).
#   5. Start clickhouse-server (`systemctl --no-block` - the blocking form
#      deadlocks against this unit's own Requires= gate from inside ExecStart).
# =============================================================================

log() { echo "clickhouse-bootstrap: $*" >&2; logger -t clickhouse-bootstrap "$*" 2>/dev/null || true; }
fail() { log "FAIL: $*"; exit 1; }

IMDS="http://169.254.169.254/opc/v2"
HDR="Authorization: Bearer Oracle"
LABELS=(CH-DATA CH-DATA2)

# ---------------------------------------------------------------------------
# 1. user_data: IMDS v2 only. No fixture/override mode on purpose - the
#    contract is IMDS, and a second input path is a second thing to keep
#    fail-closed. (In-build self-testing instead proves the gate FAILS on a
#    build instance, which has IMDS but no user_data.)
# ---------------------------------------------------------------------------
[ "${1:-}" = "" ] || fail "this script takes no arguments; user_data comes from IMDS v2 only"
command -v curl >/dev/null || fail "curl is required"
command -v python3 >/dev/null || fail "python3 is required"
command -v blkid >/dev/null || fail "blkid is required"

UD_B64=""
for i in $(seq 1 30); do
  UD_B64=$(curl -sf -H "$HDR" "$IMDS/instance/metadata/user_data" 2>/dev/null || true)
  [ -n "$UD_B64" ] && break
  log "user_data not yet at IMDS (try $i/30) - waiting for the metadata service"
  sleep 2
done
[ -n "$UD_B64" ] || fail "no user_data at IMDS $IMDS/instance/metadata/user_data after 60s - refusing to configure (fail-closed). Deliver the contract JSON via the instance's user_data."

UD_FILE=$(mktemp /var/tmp/clickhouse-userdata.XXXXXX)
VARS_FILE=$(mktemp /var/tmp/clickhouse-vars.XXXXXX)
trap 'rm -f "$UD_FILE" "$VARS_FILE"' EXIT

printf '%s' "$UD_B64" | base64 -d >"$UD_FILE" 2>/dev/null \
  || fail "user_data is not valid base64"

# Validate against the contract and emit shell assignments. Every field is
# required; type must be "server"; dataPaths must be exactly two absolute
# paths; ports must be integers.
python3 - "$UD_FILE" "$VARS_FILE" <<'PY' || fail "user_data failed contract validation (errors above)"
import json, sys

ud_path, vars_path = sys.argv[1], sys.argv[2]

def die(msg: str) -> None:
    print(f"clickhouse-bootstrap: CONTRACT: {msg}", file=sys.stderr)
    sys.exit(1)

try:
    with open(ud_path) as f:
        ud = json.load(f)
except Exception as e:
    die(f"user_data is not valid JSON: {e}")

if not isinstance(ud, dict):
    die("user_data must be a JSON object")

for field in ("type", "clusterName", "dataPaths", "httpPort", "tcpPort"):
    if field not in ud:
        die(f"missing required field '{field}'")

if ud["type"] != "server":
    die(f"type must be 'server', got {ud['type']!r}")

cluster = ud["clusterName"]
if not isinstance(cluster, str) or not cluster:
    die("clusterName must be a non-empty string")

paths = ud["dataPaths"]
if not isinstance(paths, list) or len(paths) != 2:
    die(f"dataPaths must be a list of exactly 2 paths, got {paths!r}")
for p in paths:
    if not isinstance(p, str) or not p.startswith("/") or " " in p:
        die(f"dataPaths entries must be absolute paths without spaces, got {p!r}")

ports = {}
for field in ("httpPort", "tcpPort"):
    v = ud[field]
    if not isinstance(v, int) or not (1 <= v <= 65535):
        die(f"{field} must be an integer port, got {v!r}")
    ports[field] = v

def sh(s: str) -> str:
    return "'" + s.replace("'", "'\"'\"'") + "'"

with open(vars_path, "w") as f:
    f.write(f"CH_CLUSTER={sh(cluster)}\n")
    f.write(f"CH_DATA_PATH_1={sh(paths[0])}\n")
    f.write(f"CH_DATA_PATH_2={sh(paths[1])}\n")
    f.write(f"CH_HTTP_PORT={ports['httpPort']}\n")
    f.write(f"CH_TCP_PORT={ports['tcpPort']}\n")
PY

# shellcheck disable=SC1090
source "$VARS_FILE"
log "contract ok: cluster=$CH_CLUSTER paths=$CH_DATA_PATH_1,$CH_DATA_PATH_2 http=$CH_HTTP_PORT tcp=$CH_TCP_PORT"

# ---------------------------------------------------------------------------
# 2. Reserved secondary private IPs (the module's oci_core_private_ip pins).
#    Ground truth (IMDS v2, us-phoenix-1): the vnic object at $IMDS/vnics/0/
#    carries .secondaryPrivateIps as a list of plain address strings. There
#    is NO $IMDS/vnics/0/privateIps endpoint - it 404s. DHCP configures only
#    the primary, so add each secondary with the primary's prefix on the
#    primary NIC. The reserved-IP attach lands seconds after the instance
#    exists (oci_core_private_ip depends on oci_core_instance), so the read
#    is a bounded wait like the volume attach below. FAIL CLOSED: any read or
#    parse error, or an empty list after the wait, stops the boot - a node
#    silently serving without its stable server_private_ips identity is the
#    bug this step exists to prevent.
# ---------------------------------------------------------------------------
PRIMARY_IP=$(curl -sf -H "$HDR" "$IMDS/vnics/0/privateIp" 2>/dev/null | tr -d '"') \
  || fail "cannot read the primary private IP from IMDS"
PRIMARY_DEV=$(ip -4 -o addr show | awk -v ip="$PRIMARY_IP" '$0 ~ "inet " ip "/" {print $2; exit}')
[ -n "$PRIMARY_DEV" ] || fail "cannot find the interface holding $PRIMARY_IP"
PFX=$(ip -4 -o addr show dev "$PRIMARY_DEV" | awk -v ip="$PRIMARY_IP" '$0 ~ "inet " ip "/" {print $4}' | cut -d/ -f2)
[ -n "$PFX" ] || fail "cannot determine the prefix length of $PRIMARY_IP"

EXTRA_IPS=""
for w in $(seq 1 30); do
  VNIC_JSON=$(curl -sf -H "$HDR" "$IMDS/vnics/0/" 2>/dev/null || true)
  if [ -n "$VNIC_JSON" ]; then
    EXTRA_IPS=$(printf '%s' "$VNIC_JSON" | python3 -c 'import json,sys
v = json.load(sys.stdin)
ips = v.get("secondaryPrivateIps") or []
if not isinstance(ips, list):
    sys.exit("secondaryPrivateIps must be a list in IMDS vnic 0, got %r" % (type(ips).__name__,))
for e in ips:
    a = e.get("address") if isinstance(e, dict) else e
    if isinstance(a, str) and a:
        print(a)
    else:
        sys.exit("bad secondaryPrivateIps entry: %r" % (e,))') \
      || fail "cannot parse secondaryPrivateIps from IMDS vnic metadata"
  fi
  [ -n "$EXTRA_IPS" ] && break
  log "waiting for reserved secondary IPs at IMDS vnic 0 (try $w/30) - reserved-IP attach may still be in flight"
  sleep 2
done
[ -n "$EXTRA_IPS" ] || fail "no reserved secondary IPs at IMDS vnic 0 after 60s - refusing to run without this node's stable server_private_ips identity (fail-closed)"

for ip in $EXTRA_IPS; do
  [ "$ip" = "$PRIMARY_IP" ] && continue
  if ! ip -4 addr show | grep -q "inet ${ip}/"; then
    ip addr add "${ip}/${PFX}" dev "$PRIMARY_DEV" \
      || fail "cannot bring up reserved secondary IP ${ip}/${PFX} on $PRIMARY_DEV"
    log "brought up reserved secondary IP ${ip}/${PFX} on $PRIMARY_DEV"
  fi
done

# ---------------------------------------------------------------------------
# 3. Data volumes by LABEL (CH-DATA -> dataPaths[0], CH-DATA2 -> dataPaths[1]).
#    First boot: the volumes are blank, so there is no label to find yet.
#    Deterministic blank-device mapping: candidates are unmounted, unformatted
#    whole disks (type=disk only - snap loop devices carry squashfs and are
#    never blank), sorted by SIZE DESC then NAME ASC, assigned to the missing
#    labels in dataPaths order. The catalog unit sizes data 100 GB / data2
#    20 GB (plan W3.1), so the mapping is unambiguous; after first boot the
#    LABELS are authoritative and this branch never runs again. Ambiguity
#    (wrong count of blank disks) FAILS rather than guessing.
# ---------------------------------------------------------------------------
root_src=$(findmnt -n -o SOURCE /)
root_disk=$(lsblk -no PKNAME "$root_src" 2>/dev/null | head -1 || true)
[ -n "$root_disk" ] || root_disk=$(basename "$root_src")

blank_disks() {
  lsblk -bdno NAME,SIZE,TYPE | awk '$3 == "disk" {print $1, $2}' | sort -k2,2nr -k1,1 \
    | while read -r name size; do
        base=$(basename "$name")
        [ "$base" = "$root_disk" ] && continue
        if lsblk -nrpo MOUNTPOINT "/dev/$base" 2>/dev/null | grep -q '[^[:space:]]'; then continue; fi
        if blkid "/dev/$base" >/dev/null 2>&1; then continue; fi
        if lsblk -nrpo TYPE "/dev/$base" 2>/dev/null | grep -q '^part$'; then continue; fi
        echo "/dev/$base"
      done
}

DATA_PATHS=("$CH_DATA_PATH_1" "$CH_DATA_PATH_2")
MISSING_LABELS=()
MISSING_PATHS=()
BLANKS=()

# resolve_volumes: mount anything already carrying its label; collect what is
# still missing and which blank disks are available. Re-runnable while a
# late-attached volume is still in flight (attach lands seconds after launch).
resolve_volumes() {
  MISSING_LABELS=()
  MISSING_PATHS=()
  mapfile -t BLANKS < <(blank_disks)
  for i in 0 1; do
    label="${LABELS[$i]}"
    path="${DATA_PATHS[$i]}"
    mkdir -p "$path"
    chown clickhouse:clickhouse "$path"
    dev=$(blkid -L "$label" 2>/dev/null || true)
    if [ -n "$dev" ] && mountpoint -q "$path"; then
      log "$label ($dev) already mounted at $path"
    elif [ -n "$dev" ] && mount "$dev" "$path" 2>/dev/null; then
      log "mounted $label ($dev) at $path"
    else
      # Either the volume has not appeared yet, or it has appeared but the
      # device is still settling (PV hot-attach enumerates before udev is
      # done) - treat as not-yet and let the bounded retry loop ask again.
      MISSING_LABELS+=("$label")
      MISSING_PATHS+=("$path")
    fi
  done
}

resolve_volumes
for w in $(seq 1 24); do
  if [ "${#MISSING_LABELS[@]}" -eq 0 ]; then break; fi
  if [ "${#BLANKS[@]}" -eq "${#MISSING_LABELS[@]}" ]; then break; fi
  log "waiting for data volumes (missing labels: ${#MISSING_LABELS[@]}, blanks: ${#BLANKS[@]}) - try $w/24 (attach may still be in flight)"
  sleep 5
  resolve_volumes
done

if [ "${#MISSING_LABELS[@]}" -gt 0 ]; then
  [ "${#BLANKS[@]}" -eq "${#MISSING_LABELS[@]}" ] \
    || fail "first-boot volume mapping: expected exactly ${#MISSING_LABELS[@]} blank data disk(s) for ${MISSING_LABELS[*]}, found ${#BLANKS[@]} (${BLANKS[*]-none}). Refusing to guess - attach the data volumes or check for stray unformatted disks."
  for i in "${!MISSING_LABELS[@]}"; do
    dev="${BLANKS[$i]}"
    label="${MISSING_LABELS[$i]}"
    path="${MISSING_PATHS[$i]}"
    log "first boot: formatting $dev as $label -> $path"
    mkfs.ext4 -qF -L "$label" "$dev"
    mount "$dev" "$path"
  done
fi

for i in 0 1; do
  path="${DATA_PATHS[$i]}"
  mountpoint -q "$path" || fail "expected mount absent after mount/format: $path (${LABELS[$i]})"
  chown clickhouse:clickhouse "$path"
done
log "data volumes ready: ${DATA_PATHS[*]}"

# ---------------------------------------------------------------------------
# 4. Render config.d/overrides.xml + users.d/overrides.xml
# ---------------------------------------------------------------------------
python3 - "$CH_CLUSTER" "$CH_DATA_PATH_1" "$CH_DATA_PATH_2" "$CH_HTTP_PORT" "$CH_TCP_PORT" <<'PY' || fail "config render failed"
import sys
from xml.sax.saxutils import escape

cluster, p1, p2, http_port, tcp_port = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
e = escape

# config.d/overrides.xml - shipped config.xml stays untouched (the deb owns
# it); these are the contract overrides. Both dataPaths become disks of the
# default policy so neither volume class is stranded (the AWS layout's two
# data volumes, plan section 4 'paths').
config = f"""<clickhouse>
    <!-- Rendered by /usr/local/bin/clickhouse-bootstrap.sh from IMDS
         user_data. Do not edit - it is rewritten on every boot. -->
    <listen_host>0.0.0.0</listen_host>
    <http_port>{http_port}</http_port>
    <tcp_port>{tcp_port}</tcp_port>
    <display_name>{e(cluster)}</display_name>
    <path>{e(p1)}/</path>
    <tmp_path>{e(p1)}/tmp/</tmp_path>
    <user_files_path>{e(p1)}/user_files/</user_files_path>
    <format_schema_path>{e(p1)}/format_schemas/</format_schema_path>
    <access_control_path>{e(p1)}/access/</access_control_path>
    <storage_configuration>
        <disks>
            <!-- data1 is intentionally absent: a custom disk path must not
                 coincide with the server's <path> (ClickHouse rejects the
                 config and the server exits after creating its layout).
                 The main path IS volume 1; data2 is volume 2. -->
            <data2><path>{e(p2)}/</path></data2>
        </disks>
        <policies>
            <default>
                <volumes>
                    <main>
                        <disk>default</disk>
                        <disk>data2</disk>
                    </main>
                </volumes>
            </default>
        </policies>
    </storage_configuration>
</clickhouse>
"""

# users.d/overrides.xml - the AWS deployment authenticates at the security
# group layer (the module delivers no credentials in user_data and the AMI
# runs the default user); this keeps that model explicit on OCI: the default
# user has an empty password and NSGs + ufw are the boundary. The catalog
# unit's security rules (plan W3.3: LB -> 8123, app-tier -> LB, 9000
# self/interserver) are the access control, same as AWS's security_group_rules.
users = f"""<clickhouse>
    <!-- Rendered by /usr/local/bin/clickhouse-bootstrap.sh from IMDS
         user_data. Do not edit - it is rewritten on every boot. -->
    <users>
        <default>
            <password></password>
            <networks>
                <ip>::/0</ip>
            </networks>
            <profile>default</profile>
            <quota>default</quota>
        </default>
    </users>
</clickhouse>
"""

with open("/etc/clickhouse-server/config.d/overrides.xml", "w") as f:
    f.write(config)
with open("/etc/clickhouse-server/users.d/overrides.xml", "w") as f:
    f.write(users)
PY
log "rendered /etc/clickhouse-server/config.d/overrides.xml and users.d/overrides.xml"

# ---------------------------------------------------------------------------
# 5. Start the server. --no-block is load-bearing: clickhouse-server carries
#    Requires=clickhouse-bootstrap.service, so a blocking start from inside
#    this unit's own ExecStart waits on this unit forever.
# ---------------------------------------------------------------------------
# Do NOT start clickhouse-server from in here: this unit is its own
# Requires= gate (see clickhouse-server-bootstrap.conf), so a start request
# made while this unit is still activating fails with 'dependency' and
# poisons the server's boot-pending job. The server is enabled and ordered
# After=/Requires= this unit, so systemd starts it as soon as this unit
# completes successfully.
log "contract config in place; clickhouse-server will be started by systemd (enabled, gated on this unit)"
