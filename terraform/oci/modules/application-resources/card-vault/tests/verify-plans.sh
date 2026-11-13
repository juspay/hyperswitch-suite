#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
python3 - <<'PY'
import json
import subprocess

result = subprocess.run(
    ["terraform", "test", "-filter=tests/database.tftest.hcl", "-json", "-verbose"],
    capture_output=True,
    text=True,
)
events = [json.loads(line) for line in result.stdout.splitlines() if line.strip()]
for event in events:
    if event.get("type") in {"diagnostic", "test_summary"}:
        print(event.get("@message", event))
if result.returncode:
    print(result.stderr)
    raise SystemExit(result.returncode)

plans = {
    event["@testrun"]: event["test_plan"]
    for event in events
    if event.get("type") == "test_plan"
}
assert set(plans) == {"default_without_backup", "supplied_backup", "database_disabled"}, plans.keys()

for name, plan in plans.items():
    changes = plan.get("resource_changes", [])
    databases = [change for change in changes if change["type"] == "oci_psql_db_system"]
    assert not any(
        change["type"] in {"random_password", "oci_vault_secret"}
        or "secret" in change["type"] and change["mode"] == "data"
        for change in changes
    ), f"{name}: must not generate, create, or retrieve secrets"
    if name == "database_disabled":
        assert not changes, f"{name}: must not create database resources or read data"
        print(f"PASS {name}: no nested resources or data reads")
        continue

    assert len(databases) == 1, f"{name}: expected exactly one database owner"
    database = databases[0]
    assert database["address"] == "module.database[0].oci_psql_db_system.this", database["address"]
    values = database["change"]["after"]
    if name == "default_without_backup":
        assert values.get("source", []) == [], f"{name}: expected no source block"
        subnet = "ocid1.subnet.oc1.phx.test-original"
    else:
        assert len(values["source"]) == 1, f"{name}: expected one backup source block"
        source, = values["source"]
        assert source["source_type"] == "BACKUP", source
        assert source["backup_id"] == "ocid1.postgresqlbackup.oc1.phx.test", source
        subnet = "ocid1.subnet.oc1.phx.test-requested"
    assert values["network_details"][0]["subnet_id"] == subnet, values["network_details"]
    credentials, = values["credentials"]
    assert credentials["username"] == "test_admin", credentials
    password, = credentials["password_details"]
    assert password["password_type"] == "VAULT_SECRET", password
    assert password["secret_id"] == "ocid1.vaultsecret.oc1.phx.test", password
    assert password["secret_version"] == "2", password
    assert password.get("password") in {None, ""}, "Password value must not be supplied"
    print(f"PASS {name}: exact nested owner, source, subnet and external Vault metadata")
PY
