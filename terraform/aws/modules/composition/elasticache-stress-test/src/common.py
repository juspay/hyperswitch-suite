import os
import time
import logging
import json
from concurrent.futures import ThreadPoolExecutor, as_completed

import redis
from redis.cluster import RedisCluster, ClusterNode

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _redis_kwargs(host, port, auth_token, use_tls, decode=False):
    kwargs = {
        "host": host,
        "port": port,
        "decode_responses": decode,
        "socket_timeout": 30,
        "socket_connect_timeout": 30,
        "retry_on_timeout": True,
    }
    if auth_token:
        kwargs["password"] = auth_token
    if use_tls:
        kwargs["ssl"] = True
    return kwargs


def discover_primary_host():
    host = os.environ.get("REDIS_HOST", "")
    port = int(os.environ.get("REDIS_PORT", "6379"))
    auth_token = os.environ.get("REDIS_AUTH_TOKEN", "")
    use_tls = os.environ.get("REDIS_USE_TLS", "false").lower() == "true"
    target_primary = os.environ.get("TARGET_PRIMARY_ONLY", "true").lower() == "true"
    if not target_primary:
        return host
    discovered = _discover_primary_node(host, port, auth_token, use_tls)
    return discovered if discovered else host


def _discover_primary_node(host, port, auth_token, use_tls):
    probe = redis.Redis(**_redis_kwargs(host, port, auth_token, use_tls, decode=True))
    try:
        probe.ping()
        try:
            raw = probe.execute_command("CLUSTER", "NODES")
            if isinstance(raw, bytes):
                raw = raw.decode()
            for line in raw.strip().splitlines():
                parts = line.split()
                if len(parts) < 8:
                    continue
                flags = parts[2].split(",")
                if "master" not in flags:
                    continue
                addr = parts[1]
                node_host = addr.rsplit("@", 1)[0].rsplit(":", 1)[0]
                logger.info(f"Discovered primary node: {node_host} (flags={parts[2]})")
                return node_host
        except redis.ResponseError:
            pass

        info = probe.info(section="replication")
        if info.get("role") == "master":
            logger.info("Node is already primary (standalone mode)")
            return None
        master_host = info.get("master_host", "")
        if master_host:
            logger.info(f"Discovered primary via INFO replication: {master_host}")
            return master_host
    finally:
        try:
            probe.close()
        except Exception:
            pass
    return None


def get_redis_client():
    host = os.environ.get("REDIS_HOST", "")
    port = int(os.environ.get("REDIS_PORT", "6379"))
    cluster_mode = os.environ.get("CLUSTER_MODE", "true").lower() == "true"
    auth_token = os.environ.get("REDIS_AUTH_TOKEN", "")
    use_tls = os.environ.get("REDIS_USE_TLS", "false").lower() == "true"
    target_primary = os.environ.get("TARGET_PRIMARY_ONLY", "true").lower() == "true"

    logger.info(
        f"Creating Redis client: host={host}, port={port}, cluster_mode={cluster_mode}, "
        f"use_tls={use_tls}, has_auth={bool(auth_token)}, target_primary_only={target_primary}"
    )

    if not cluster_mode and target_primary:
        primary_host = _discover_primary_node(host, port, auth_token, use_tls)
        if primary_host:
            logger.info(f"Redirecting client to primary node: {primary_host}:{port}")
            host = primary_host

    try:
        if cluster_mode:
            startup_node = ClusterNode(host=host, port=port)
            logger.info(f"Initializing RedisCluster with startup_node {host}:{port}")
            client = RedisCluster(
                startup_nodes=[startup_node],
                **{k: v for k, v in _redis_kwargs(host, port, auth_token, use_tls).items()
                   if k != "host" and k != "port"},
            )
            logger.info("RedisCluster initialized successfully")
        else:
            logger.info(f"Initializing standalone redis.Redis client to {host}:{port}")
            client = redis.Redis(**_redis_kwargs(host, port, auth_token, use_tls))
            logger.info("Standalone Redis client initialized successfully")
    except Exception as e:
        logger.error(
            f"Failed to create Redis client: host={host}, port={port}, "
            f"cluster_mode={cluster_mode}, error={e}",
            exc_info=True,
        )
        raise

    return client


def run_stress_with_workers(worker_fn, num_clients, num_threads, duration):
    start_time = time.time()
    end_time = start_time + duration
    total_operations = 0
    errors = []

    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = []
        for _ in range(num_clients):
            futures.append(executor.submit(worker_fn, end_time))

        for future in as_completed(futures):
            try:
                result = future.result()
                total_operations += result
            except Exception as e:
                errors.append(str(e))

    elapsed = time.time() - start_time
    ops_per_sec = total_operations / elapsed if elapsed > 0 else 0

    return {
        "total_operations": total_operations,
        "elapsed_seconds": round(elapsed, 2),
        "ops_per_sec": round(ops_per_sec, 2),
        "errors": errors[:10],
        "error_count": len(errors),
    }
