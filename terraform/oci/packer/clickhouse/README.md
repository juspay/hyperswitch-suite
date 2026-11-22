# ClickHouse custom image (OCI, Packer)

Builds the image the `clickhouse` composition module's `server_image_id` /
`keeper_image_id` inputs expect
(`../../modules/composition/clickhouse/variables.tf`), passed through by
`hyperswitch-infra:terraform/oci/catalog/units/{kafka,clickhouse}` from
`values.custom_images.clickhouse`.

Those units have **no fallback default** for the image inputs — no `try(…,
"PLACEHOLDER")` — so they fail loudly at plan time if no real image exists.
This directory is the other half of that contract.

Cloned from [`../envoy-proxy/`](../envoy-proxy) (the 12-step canonical VM-tier
template) per plan W2 of `.omo/plans/oci-kafka-clickhouse-images.md`; see the
header of `clickhouse-image.pkr.hcl` for the step-by-step delta map.

## What this builds, on top of a stock `Canonical-Ubuntu-26.04` platform image

- **ClickHouse**, from the **official** `packages.clickhouse.com` **LTS** deb
  repository (vendor signing key in a dedicated keyring, `signed-by=` pinned),
  **version-pinned** to `var.clickhouse_version` — the `clickhouse-server` /
  `clickhouse-client` / `clickhouse-common-static` trio at the same exact
  version. **Keeper ships inside the server deb** (`/usr/bin/clickhouse-keeper`
  + `clickhouse-keeper-client`/`-converter` symlinks into the multi-call
  binary, `clickhouse-keeper.service`, `keeper_config.xml` — deb-contents
  verified 2026-11-17); the standalone `clickhouse-keeper` deb **Conflicts**
  `clickhouse-server` and exists only for keeper-only nodes, so it is
  deliberately not installed (the plan's "triple" wording predates that
  discovery — the build proved the conflict). The keeper scale-up path is
  therefore fully covered by this image. Recorded 2026-11-17: **26.8.39.19**
  is the current LTS patch (plan §0 gate decision 1 takes the latest patched
  line; this supersedes the plan text's day-of 26.8.36.3). Re-check the
  channel on build day and pin the newest version in `variables.pkr.hcl`.
- **`clickhouse-server.service`** — the **deb's own unit, kept as shipped**,
  gated fail-closed by a drop-in
  (`scripts/clickhouse-server-bootstrap.conf` → `Requires=clickhouse-bootstrap.service`).
- **`clickhouse-bootstrap.service`** — oneshot, `Before=clickhouse-server.service`,
  runs `/usr/local/bin/clickhouse-bootstrap.sh` at every boot.
- **`/usr/local/bin/clickhouse-bootstrap.sh`** — the plan **section 4 boot
  contract**, read from **OCI IMDS v2 user_data**:

  ```json
  { "type": "server",
    "clusterName": "hyperswitch-clickhouse-ec2",
    "dataPaths": ["/var/lib/clickhouse/data", "/var/lib/clickhouse/data2"],
    "httpPort": 8123,
    "tcpPort": 9000 }
  ```

  Every field required. It mounts the two persistent data volumes **by
  filesystem LABEL** (`CH-DATA` → `dataPaths[0]`, `CH-DATA2` → `dataPaths[1]`,
  format-if-blank on first boot, fail-fast if absent), brings up the module's
  reserved secondary private IPs (OCI's DHCP only configures the primary
  address on a VNIC — same in-guest step the kafka contract needs for its
  advertised IP), renders `config.d/overrides.xml` (both paths as a two-disk
  default policy, listen host, ports) and `users.d/overrides.xml`
  (network-layer auth parity with the AWS security-group model), then starts
  the server. **Fail-closed**: no user_data, bad JSON, or a missing volume
  leaves `clickhouse-server` stopped and logs loudly.

  The catalog unit's `server_user_data_template` MUST emit exactly this JSON
  (plan W3.1 adapts the AWS-side
  `terraform/catalog/units/data-stack/clickhouse/templates/server-userdata.json`
  — keep the cluster naming, drop the replication/keeper blocks, add the two
  paths and the ports). This image is the contract owner.

- **`oci-metadata.service`** — writes `/etc/default/metadata` from IMDS so
  `vector.toml`'s `get_env_var("METADATA_*")` calls resolve (shared script).
- **The OCI CLI** (`../shared/scripts/install-oci-cli.sh`).
- **Vector** with a ClickHouse-flavoured `vector.toml` (journald + server logs
  → tagged metrics/logs; host metrics; `prometheus_exporter` on 9273). 9273 is
  **not** opened in ufw — nothing scrapes a clickhouse node yet.
- **`ufw`**, default-deny incoming, allowing **8123** (HTTP / LB health),
  **9000** (native / interserver), **9181** (keeper — unused in the
  single-node cut, open for the documented scale-up) and **22 from the prod
  VCN CIDR** `10.91.0.0/16` (`values.vcn_cidr_prefix = "10.91"`).

## The build asserts the image works before capturing it

Step 8 of the template checks, on the live build instance:

1. **The fail-closed gate, against the real IMDS.** The build instance has
   IMDS but no user_data — exactly the failure mode of a node launched without
   the contract. `systemctl start clickhouse-server` must **fail** and the
   server must stay inactive. A dropped drop-in or a fail-open bootstrap can
   never be captured.
2. **The shipped default config smoke** (plan W2 step 8): the deb's default
   config serves `GET /ping` → `Ok.` on loopback and `clickhouse-client
   --query "SELECT 1"` → `1`; `clickhouse-keeper --version` present and pinned.
   Run as the server binary directly on purpose — the systemd unit is
   correctly gated on user_data (assertion 1), so this asserts the software,
   not the boot contract.
3. **Clean state** — no test data left in `/var/lib/clickhouse` for the image
   to carry; the two mountpoint dirs from Step 3 are recreated empty.

The full first-boot path (real user_data + real attached data volumes + the
reserved IP) is exercised on a throwaway instance from the built image — see
"Test it out" below.

## Build (operator-assisted)

```bash
cd terraform/oci/packer/build-network
OCI_CLI_PROFILE=produser COMPARTMENT_ID=ocid1.compartment.oc1..aaaaaaaaw23… ./create.sh
# (shared with the kafka build - one build VCN per session, destroy after BOTH)

cd ../clickhouse
cp dev.auto.pkrvars.hcl.example dev.auto.pkrvars.hcl   # fill in the three OCIDs
packer init .
packer validate .        # runs the builder's Prepare() - catches a stale oci session in seconds
packer build .
```

Defaults in `variables.pkr.hcl` are the **prod build defaults** (plan gate
decision 2 — direct in prod, no promotion ladder): `region = "us-phoenix-1"`,
`access_cfg_file_account = "produser"`, `environment = "prod"`,
`image_name_prefix = "hyperswitch-clickhouse"`, boot volume 50 GB.

The image OCID is in `packer-manifest.json` (`builds[].artifact_id`); OCI has
no image-family concept, so `values.custom_images.clickhouse` takes a literal
OCID. Reports land in `trivy-reports/` (Trivy JSON + SBOM + snaps variant +
the CIS ansible log). **The Trivy gate is advisory-only** (user direction
2026-11-17: stop iterating on CVE cleanliness, 100% hardening is never
achievable) — the scan runs and is archived, but findings do not fail the
build. Deliberate deviation from the envoy recipe's gate.

## Test it out (post-build smoke)

Launch a throwaway instance from the built image OCID in the build VCN, with:

- two block volumes attached (data 100 GB, data2 20 GB — blank; the bootstrap
  formats+labels them on first boot, matching the catalog unit's sizing),
- `user_data` = the contract JSON above with the instance's own reserved
  private address pinned as in W3 (`server_reserved_ip_addresses`),

then verify: `curl http://127.0.0.1:8123/ping` → `Ok.`,
`clickhouse-client --query "SELECT version()"`, both mounts present
(`findmnt /var/lib/clickhouse/data /var/lib/clickhouse/data2`, labels
`CH-DATA`/`CH-DATA2`), the reserved IP on the interface, `ufw` active,
`vector` active, and the gate (reboot with bad user_data → server stays
stopped). Terminate afterwards — the build VCN is disposable.

## Notes

- The build subnet needs outbound internet: apt, `packages.clickhouse.com`,
  the Vector repo and the OCI CLI installer are all reached during the build.
- `clickhouse_version` is a deb version triple from the LTS channel, not a
  docker tag.
- `var.clickhouse_http_port` must match the clickhouse unit's `clickhouse_port`
  (8123). A mismatch surfaces as a permanently unhealthy LB backend set, not as
  an error.
- First-boot volume mapping (documented in `clickhouse-bootstrap.sh`):
  LABEL-first (`CH-DATA`/`CH-DATA2`); on first boot the blank volumes are
  mapped by size-desc/name-asc to the two `dataPaths` — deterministic for the
  unit's 100 GB / 20 GB sizing, and ambiguous counts **fail** rather than
  guess. After first boot the labels are authoritative and device naming
  (paravirtualized vs iscsi) never matters (check-sheet 9.2 stays moot).
- Kept intentionally minimal, like the envoy image — Vector is included, but
  none of the CloudWatch/Wazuh layers the AWS AMI's userdata adds.
