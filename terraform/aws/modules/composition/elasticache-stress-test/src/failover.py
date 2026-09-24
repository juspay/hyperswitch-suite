"""Elasticache Valkey failover stress test Lambda.

Triggers an ``elasticache:TestFailover`` on the target replication group's
node group and polls ``describe_replication_groups`` until the replication
group returns to ``available``. This exercises shard-level primary/replica
failover without needing a direct Redis connection (no redis-py layer).

Pre-flight checks (any failure returns statusCode 400):
  a. Replication group status must be ``available``.
  b. Target node group must have at least 2 members (primary + replica).
  c. Every replica in the node group must have ``ReplicaLag`` <= 30 seconds
     (skipped when the metric is absent).
  d. No node replacement/failover already in progress (status must be available).

Environment variables:
  REDIS_REPLICATION_GROUP_ID  - Replication group ID (default ``sbx-test-redis``)
  REDIS_NODE_GROUP_ID         - Node group / shard ID (default ``0001``)
  AWS_REGION                  - AWS region (auto-set by Lambda)
"""

import json
import os
import time
import logging
from typing import Any, Dict, List, Optional

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

POLL_INTERVAL_SECONDS = 15
MAX_WAIT_SECONDS = 600
MAX_REPLICA_LAG_SECONDS = 30


def _get_config() -> Dict[str, str]:
    """Read configuration from environment variables with sensible defaults."""
    return {
        "replication_group_id": os.environ.get("REDIS_REPLICATION_GROUP_ID", "sbx-test-redis"),
        "node_group_id": os.environ.get("REDIS_NODE_GROUP_ID", "0001"),
        "region": os.environ.get("AWS_REGION", os.environ.get("AWS_DEFAULT_REGION", "")),
    }


def _get_elasticache_client(region: str):
    """Build an Elasticache boto3 client for the given region."""
    return boto3.client("elasticache", region_name=region)


def _describe_replication_group(client, replication_group_id: str) -> Dict[str, Any]:
    """Fetch the replication group description, returning the inner dict.

    Raises ``RuntimeError`` if the replication group is not found.
    """
    response = client.describe_replication_groups(ReplicationGroupId=replication_group_id)
    groups: List[Dict[str, Any]] = response.get("ReplicationGroups", [])
    if not groups:
        raise RuntimeError(f"Replication group '{replication_group_id}' not found")
    return groups[0]


def _find_node_group(replication_group: Dict[str, Any], node_group_id: str) -> Optional[Dict[str, Any]]:
    """Return the node group dict matching ``node_group_id`` or ``None``."""
    for ng in replication_group.get("NodeGroups", []):
        if ng.get("NodeGroupId") == node_group_id:
            return ng
    return None


def _preflight_checks(client, replication_group_id: str, node_group_id: str) -> Dict[str, Any]:
    """Run all pre-flight checks and return the initial replication group state.

    Raises ``RuntimeError`` on any check failure.
    """
    rg = _describe_replication_group(client, replication_group_id)
    status: str = rg.get("Status", "unknown")

    # Check (a) + (d): replication group must be available (no failover/replacement in progress)
    if status != "available":
        raise RuntimeError(
            f"Replication group '{replication_group_id}' status is '{status}', "
            f"expected 'available'. A failover or replacement may already be in progress."
        )

    node_group = _find_node_group(rg, node_group_id)
    if node_group is None:
        raise RuntimeError(
            f"Node group '{node_group_id}' not found in replication group '{replication_group_id}'. "
            f"Available node groups: {[ng.get('NodeGroupId') for ng in rg.get('NodeGroups', [])]}"
        )

    # Check (b): at least 2 members (primary + replica)
    members: List[Dict[str, Any]] = node_group.get("NodeGroupMembers", [])
    if len(members) < 2:
        raise RuntimeError(
            f"Node group '{node_group_id}' has only {len(members)} member(s); "
            f"at least 2 (primary + replica) are required for failover."
        )

    # Check (c): every replica must have ReplicaLag <= 30s (skip if absent)
    for member in members:
        role = member.get("CurrentRole", "")
        if role.lower() != "replica":
            continue
        lag = member.get("ReadReplicaLag") or member.get("ReplicaLag")
        if lag is None:
            logger.info(
                f"Replica '{member.get('CacheClusterId', '?')}' has no ReplicaLag metric; skipping lag check."
            )
            continue
        # lag can be a string like "0" or a number
        try:
            lag_seconds = float(lag)
        except (TypeError, ValueError):
            logger.warning(
                f"Replica '{member.get('CacheClusterId', '?')}' has unparseable ReplicaLag '{lag}'; skipping."
            )
            continue
        if lag_seconds > MAX_REPLICA_LAG_SECONDS:
            raise RuntimeError(
                f"Replica '{member.get('CacheClusterId', '?')}' ReplicaLag is {lag_seconds}s, "
                f"exceeds maximum allowed {MAX_REPLICA_LAG_SECONDS}s."
            )

    logger.info(
        f"Pre-flight checks passed: replication_group='{replication_group_id}' status='{status}', "
        f"node_group='{node_group_id}' members={len(members)}"
    )
    return rg


def _poll_until_available(client, replication_group_id: str, max_wait: int = MAX_WAIT_SECONDS,
                          poll_interval: int = POLL_INTERVAL_SECONDS) -> str:
    """Poll ``describe_replication_groups`` until status is ``available``.

    Returns the final status string. Raises ``RuntimeError`` on timeout.
    """
    deadline = time.time() + max_wait
    last_status = "unknown"
    while time.time() < deadline:
        rg = _describe_replication_group(client, replication_group_id)
        last_status = rg.get("Status", "unknown")
        logger.info(
            f"Polling replication group '{replication_group_id}': status='{last_status}'"
        )
        if last_status == "available":
            return last_status
        time.sleep(poll_interval)
    raise RuntimeError(
        f"Replication group '{replication_group_id}' did not return to 'available' "
        f"within {max_wait}s (last status: '{last_status}')."
    )


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Trigger a TestFailover on the Valkey replication group and poll until available.

    Args:
        event: Lambda event payload (unused).
        context: Lambda runtime context (unused).

    Returns:
        A dict with ``statusCode`` and a JSON ``body`` containing
        ``replication_group_id``, ``node_group_id``, ``initial_status``,
        ``final_status``, and ``failover_initiated``.
    """
    config = _get_config()
    replication_group_id = config["replication_group_id"]
    node_group_id = config["node_group_id"]
    region = config["region"]

    if not region:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "error": "AWS_REGION environment variable is not set",
            }),
        }

    logger.info(
        f"Failover test: replication_group_id='{replication_group_id}', "
        f"node_group_id='{node_group_id}', region='{region}'"
    )

    client = _get_elasticache_client(region)

    try:
        rg = _preflight_checks(client, replication_group_id, node_group_id)
        initial_status = rg.get("Status", "unknown")

        logger.info(
            f"Initiating TestFailover on replication group '{replication_group_id}' "
            f"node group '{node_group_id}'"
        )
        client.test_failover(
            ReplicationGroupId=replication_group_id,
            NodeGroupId=node_group_id,
        )
        logger.info("TestFailover initiated successfully")

        final_status = _poll_until_available(
            client, replication_group_id,
            max_wait=MAX_WAIT_SECONDS,
            poll_interval=POLL_INTERVAL_SECONDS,
        )

        logger.info(
            f"Failover complete: replication_group='{replication_group_id}' "
            f"initial_status='{initial_status}' final_status='{final_status}'"
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "replication_group_id": replication_group_id,
                "node_group_id": node_group_id,
                "initial_status": initial_status,
                "final_status": final_status,
                "failover_initiated": True,
            }),
        }

    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        error_msg = e.response.get("Error", {}).get("Message", str(e))
        logger.error(f"ClientError [{error_code}]: {error_msg}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "replication_group_id": replication_group_id,
                "node_group_id": node_group_id,
                "error": error_msg,
                "error_code": error_code,
                "failover_initiated": False,
            }),
        }
    except RuntimeError as e:
        logger.error(f"Pre-flight or polling error: {e}")
        return {
            "statusCode": 400,
            "body": json.dumps({
                "replication_group_id": replication_group_id,
                "node_group_id": node_group_id,
                "error": str(e),
                "failover_initiated": False,
            }),
        }
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "replication_group_id": replication_group_id,
                "node_group_id": node_group_id,
                "error": str(e),
                "failover_initiated": False,
            }),
        }
