import os
import json
import logging

import redis
from redis.cluster import RedisCluster, ClusterNode
from common import get_redis_client

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _unlink_keys_safely(client, keys):
    pipe = client.pipeline()
    for key in keys:
        pipe.unlink(key)
    pipe.execute()


def _is_cluster_enabled(client):
    try:
        info = client.info(section="cluster")
        return info.get("cluster_enabled") == 1
    except Exception:
        return False


def _cluster_client_from_env():
    host = os.environ.get("REDIS_HOST", "")
    port = int(os.environ.get("REDIS_PORT", "6379"))
    auth_token = os.environ.get("REDIS_AUTH_TOKEN", "")
    use_tls = os.environ.get("REDIS_USE_TLS", "false").lower() == "true"

    kwargs = {
        "decode_responses": True,
        "socket_timeout": 30,
        "socket_connect_timeout": 10,
        "retry_on_timeout": True,
        "skip_full_coverage_check": True,
    }
    if auth_token:
        kwargs["password"] = auth_token
    if use_tls:
        kwargs["ssl"] = True

    startup_node = ClusterNode(host=host, port=port)
    return RedisCluster(startup_nodes=[startup_node], **kwargs)


def _cleanup_with_cluster(cluster_client, key_prefix, batch_size, min_remaining_ms, context):
    deleted = 0
    keys_batch = []
    for key in cluster_client.scan_iter(match=f"{key_prefix}*", count=batch_size):
        keys_batch.append(key)
        if len(keys_batch) >= batch_size:
            _unlink_keys_safely(cluster_client, keys_batch)
            deleted += len(keys_batch)
            keys_batch = []
            if context.get_remaining_time_in_millis() < min_remaining_ms:
                logger.info("Stopping cleanup: nearing Lambda timeout")
                return deleted
    if keys_batch:
        _unlink_keys_safely(cluster_client, keys_batch)
        deleted += len(keys_batch)
    return deleted


def _cleanup_with_standalone(client, key_prefix, batch_size, min_remaining_ms, context):
    deleted = 0
    keys_batch = []
    for key in client.scan_iter(match=f"{key_prefix}*", count=batch_size):
        keys_batch.append(key)
        if len(keys_batch) >= batch_size:
            _unlink_keys_safely(client, keys_batch)
            deleted += len(keys_batch)
            keys_batch = []
            if context.get_remaining_time_in_millis() < min_remaining_ms:
                logger.info("Stopping cleanup: nearing Lambda timeout")
                return deleted
    if keys_batch:
        _unlink_keys_safely(client, keys_batch)
        deleted += len(keys_batch)
    return deleted


def lambda_handler(event, context):
    key_prefix = os.environ.get("KEY_PREFIX", "stress:test:")
    batch_size = 1000
    min_remaining_ms = 30000

    logger.info(f"Cleaning up all keys with prefix: {key_prefix}")

    initial_client = None
    cluster_client = None
    deleted = 0

    try:
        initial_client = get_redis_client()
        initial_client.ping()
        cluster_enabled = _is_cluster_enabled(initial_client)

        if cluster_enabled:
            logger.info("Cluster mode detected; using RedisCluster for cleanup")
            cluster_client = _cluster_client_from_env()
            deleted = _cleanup_with_cluster(
                cluster_client, key_prefix, batch_size, min_remaining_ms, context
            )
        else:
            logger.info("Standalone mode detected")
            deleted = _cleanup_with_standalone(
                initial_client, key_prefix, batch_size, min_remaining_ms, context
            )

        logger.info(f"Unlinked {deleted} keys with prefix {key_prefix}")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "status": "complete",
                "keys_deleted": deleted,
                "key_prefix": key_prefix,
                "cluster_enabled": cluster_enabled,
            }),
        }
    except Exception as e:
        logger.error(f"Cleanup error: {e}", exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "status": "error",
                "error": str(e),
            }),
        }
    finally:
        for c in (initial_client, cluster_client):
            if c is not None:
                try:
                    c.close()
                except Exception:
                    pass
