"""
Memory stress Lambda for Redis/Valkey.

Two modes:
1. Legacy flat mode fills a fixed number of keys per worker over STRESS_DURATION and
   cleans up afterwards.
2. Phased mode (default) ramps used_memory to configured percentages of maxmemory,
   holds each level for a configured duration, then cleans up.

Phased env vars mirror the aurora-fault-injection pattern:
  MEMORY_PHASE_DURATIONS="240,240,240"
  MEMORY_PHASE_TARGET_PERCENT="60,85,100"
  MEMORY_PHASE_WORKERS="8,12,24"
  MEMORY_VALUE_SIZE="512"
  MEMORY_PIPELINE_SIZE="5"
  MEMORY_WRITE_TTL="0"
  MEMORY_CLEANUP_AFTER_STRESS="true"
"""

import json
import logging
import os
import threading
import time

from redis.cluster import RedisCluster, ClusterNode
from common import get_redis_client

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _parse_csv(env_var, default=None, cast=str):
    raw = os.environ.get(env_var, default)
    if raw is None:
        return []
    return [cast(item.strip()) for item in raw.split(",") if item.strip()]


def _is_cluster_enabled(client):
    # If CLUSTER_MODE env var is explicitly "false", use a standalone client
    # even when the server has cluster mode enabled.  This guarantees all
    # traffic (writes, scans, cleanup) goes to the configured endpoint only
    # (the primary), never discovering or connecting to the replica.
    env_cluster_mode = os.environ.get("CLUSTER_MODE", "").lower()
    if env_cluster_mode == "false":
        return False
    try:
        return client.info(section="cluster").get("cluster_enabled") == 1
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

    return RedisCluster(startup_nodes=[ClusterNode(host=host, port=port)], **kwargs)


def _make_worker_client(use_cluster):
    if use_cluster:
        return _cluster_client_from_env()
    return get_redis_client()


def memory_worker(idx, key_prefix, keys_to_write, value_size_bytes, pipeline_size, write_ttl, use_cluster, results):
    worker_key_prefix = f"{key_prefix}{{:worker{idx}:}}mem:"
    payload = b"x" * value_size_bytes
    written = 0
    errors = 0
    error_samples = []

    try:
        client = _make_worker_client(use_cluster)
    except Exception as e:
        logger.error(f"Worker {idx} failed to create redis client: {e}")
        results[idx] = {
            "status": "error",
            "error": str(e),
            "keys_written": 0,
            "errors": 1,
        }
        return

    try:
        i = 0
        while i < keys_to_write:
            batch = min(pipeline_size, keys_to_write - i)
            try:
                pipe = client.pipeline()
                for j in range(batch):
                    key = f"{worker_key_prefix}{i + j}"
                    if write_ttl > 0:
                        pipe.set(key, payload, ex=write_ttl)
                    else:
                        pipe.set(key, payload)
                result = pipe.execute()
                if isinstance(result, list):
                    batch_errors = sum(1 for r in result if isinstance(r, Exception))
                    batch_ok = len(result) - batch_errors
                    written += batch_ok
                    if batch_errors > 0:
                        errors += batch_errors
                        for r in result:
                            if isinstance(r, Exception) and len(error_samples) < 3:
                                error_samples.append(str(r))
                else:
                    written += batch
            except Exception as e:
                errors += 1
                if len(error_samples) < 3:
                    error_samples.append(str(e))
                time.sleep(0.01)
            i += batch
    except Exception as e:
        logger.error(f"Memory stress worker {idx} error: {e}")
        results[idx] = {
            "status": "error",
            "error": str(e),
            "keys_written": written,
            "errors": errors + 1,
        }
        return
    finally:
        try:
            client.close()
        except Exception as e:
            logger.warning(f"Worker {idx} client close error: {e}")

    results[idx] = {
        "status": "complete",
        "keys_written": written,
        "errors": errors,
        "error_samples": error_samples,
        "bytes_written": written * value_size_bytes,
    }


def _legacy_run(context, key_prefix, cleanup_after):
    duration = int(os.environ.get("STRESS_DURATION", "300"))
    workers = int(os.environ.get("MEMORY_WORKERS", "24"))
    keys_per_worker = int(os.environ.get("MEMORY_KEYS_PER_WORKER", "5000"))
    value_size_kb = int(os.environ.get("MEMORY_VALUE_SIZE", "4096"))
    pipeline_size = int(os.environ.get("MEMORY_PIPELINE_SIZE", "5"))
    write_ttl = int(os.environ.get("MEMORY_WRITE_TTL", "0"))
    value_size_bytes = value_size_kb * 1024
    total_target_bytes = workers * keys_per_worker * value_size_bytes
    total_target_gb = round(total_target_bytes / (1024 ** 3), 2)

    logger.info(
        f"Memory stress (flat): {workers} workers x {keys_per_worker} keys x {value_size_kb}KB "
        f"(pipeline={pipeline_size}, ttl={write_ttl}) = {total_target_gb}GB target over {duration}s"
    )

    info_client = get_redis_client()
    try:
        info_client.ping()
        info_before = info_client.info()
        used_memory_before = info_before.get("used_memory_human", "?")
        used_memory_bytes_before = info_before.get("used_memory", 0)
        maxmemory = info_before.get("maxmemory", 0)
        eviction_policy = info_before.get("eviction_policy", "?")
    finally:
        try:
            info_client.close()
        except Exception as e:
            logger.warning(f"info_client close error: {e}")

    results = [None] * workers
    threads = []
    end_time = time.time() + duration

    initial_client = get_redis_client()
    use_cluster = _is_cluster_enabled(initial_client)
    initial_client.close()

    for i in range(workers):
        t = threading.Thread(
            target=memory_worker,
            args=(i, key_prefix, keys_per_worker, value_size_bytes, pipeline_size, write_ttl, use_cluster, results),
        )
        t.daemon = True
        t.start()
        threads.append(t)

    for t in threads:
        t.join(timeout=duration + 120)

    info_after, used_memory_after, evicted_keys, keyspace_hits, keyspace_misses, connected_clients = _read_info_metrics()

    total_written = sum(r["keys_written"] for r in results if r and r.get("status") == "complete") if results else 0
    total_errors = sum(r["errors"] for r in results if r) if results else 0
    total_bytes = sum(r.get("bytes_written", 0) for r in results if r) if results else 0
    total_gb_written = round(total_bytes / (1024 ** 3), 2)
    worker_errors = sum(1 for r in results if r and r.get("status") == "error")

    keys_cleaned = 0
    if cleanup_after:
        keys_cleaned = _cleanup_stress_keys(context, key_prefix)
        logger.info(f"Cleaned {keys_cleaned} stress keys")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "mode": "flat",
            "stress_type": os.environ.get("STRESS_TYPE", "memory_stress"),
            "workers": workers,
            "keys_per_worker": keys_per_worker,
            "value_size_kb": value_size_kb,
            "pipeline_size": pipeline_size,
            "write_ttl": write_ttl,
            "total_keys_written": total_written,
            "total_bytes_written_gb": total_gb_written,
            "write_errors": total_errors,
            "worker_errors": worker_errors,
            "keys_cleaned": keys_cleaned,
            "used_memory_before": used_memory_before,
            "used_memory_after": used_memory_after,
            "maxmemory": maxmemory,
            "eviction_policy": eviction_policy,
            "evicted_keys": evicted_keys,
            "keyspace_hits": keyspace_hits,
            "keyspace_misses": keyspace_misses,
            "connected_clients": connected_clients,
            "elapsed_seconds": duration,
        }),
    }


def _read_info_metrics():
    info_client = get_redis_client()
    try:
        info_after = info_client.info()
        used_memory_after = info_after.get("used_memory_human", "?")
        evicted_keys = info_after.get("evicted_keys", 0)
        keyspace_hits = info_after.get("keyspace_hits", 0)
        keyspace_misses = info_after.get("keyspace_misses", 0)
        connected_clients = info_after.get("connected_clients", 0)
        return info_after, used_memory_after, evicted_keys, keyspace_hits, keyspace_misses, connected_clients
    finally:
        try:
            info_client.close()
        except Exception as e:
            logger.warning(f"info_client close error: {e}")


def _run_phased(context, key_prefix, cleanup_after):
    durations = _parse_csv("MEMORY_PHASE_DURATIONS", default="240,240,240", cast=int)
    target_percents = _parse_csv("MEMORY_PHASE_TARGET_PERCENT", default="60,85,100", cast=float)
    worker_counts = _parse_csv("MEMORY_PHASE_WORKERS", default="8,12,24", cast=int)

    if not (len(durations) == len(target_percents) == len(worker_counts)):
        raise ValueError("MEMORY_PHASE_DURATIONS, MEMORY_PHASE_TARGET_PERCENT and MEMORY_PHASE_WORKERS must all have the same length")
    if not durations:
        raise ValueError("At least one phase is required when MEMORY_PHASE_TARGET_PERCENT is set")
    if any(d <= 0 for d in durations):
        raise ValueError("All MEMORY_PHASE_DURATIONS values must be positive integers")
    if any(p <= 0 or p > 100 for p in target_percents):
        raise ValueError("All MEMORY_PHASE_TARGET_PERCENT values must be in (0, 100]")
    if any(w <= 0 for w in worker_counts):
        raise ValueError("All MEMORY_PHASE_WORKERS values must be positive integers")

    value_size_kb = int(os.environ.get("MEMORY_VALUE_SIZE", "512"))
    pipeline_size = int(os.environ.get("MEMORY_PIPELINE_SIZE", "5"))
    write_ttl = int(os.environ.get("MEMORY_WRITE_TTL", "0"))
    value_size_bytes = value_size_kb * 1024

    info_client = get_redis_client()
    try:
        info_client.ping()
        info_before = info_client.info()
        used_memory_before = info_before.get("used_memory_human", "?")
        used_memory_bytes_before = info_before.get("used_memory", 0)
        maxmemory = info_before.get("maxmemory", 0)
        eviction_policy = info_before.get("eviction_policy", "?")
        use_cluster = _is_cluster_enabled(info_client)
    finally:
        try:
            info_client.close()
        except Exception as e:
            logger.warning(f"info_client close error: {e}")

    if maxmemory <= 0:
        raise RuntimeError("maxmemory is not configured or reported as zero; cannot compute phased memory targets")

    start_ts = time.time()
    current_used = used_memory_bytes_before
    phase_summaries = []
    cumulative_offset = 0.0

    for phase_idx, phase_duration in enumerate(durations):
        phase_start = start_ts + cumulative_offset
        phase_end = phase_start + phase_duration
        cumulative_offset += phase_duration

        target_pct = target_percents[phase_idx]
        target_bytes = int(maxmemory * target_pct / 100.0)
        bytes_to_add = max(0, target_bytes - current_used)
        keys_to_add = bytes_to_add // value_size_bytes
        workers = worker_counts[phase_idx]

        logger.info(
            f"Phase {phase_idx + 1}: target {target_pct}% of maxmemory ({target_bytes} bytes), "
            f"currently {current_used} bytes, adding {bytes_to_add} bytes ({keys_to_add} keys) via {workers} workers"
        )

        results = [None] * workers
        if keys_to_add > 0 and workers > 0:
            base = keys_to_add // workers
            extra = keys_to_add % workers
            threads = []
            for worker_idx in range(workers):
                worker_keys = base + (1 if worker_idx < extra else 0)
                if worker_keys <= 0:
                    results[worker_idx] = {"status": "complete", "keys_written": 0, "errors": 0, "bytes_written": 0}
                    continue
                t = threading.Thread(
                    target=memory_worker,
                    args=(worker_idx, key_prefix, worker_keys, value_size_bytes, pipeline_size, write_ttl, use_cluster, results),
                )
                t.daemon = True
                t.start()
                threads.append(t)

            for t in threads:
                t.join(timeout=phase_duration + 120)

            phase_keys_written = sum(r["keys_written"] for r in results if r and r.get("status") == "complete")
            phase_errors = sum(r["errors"] for r in results if r)
            phase_bytes = sum(r.get("bytes_written", 0) for r in results if r)
        else:
            phase_keys_written = 0
            phase_errors = 0
            phase_bytes = 0

        for fill_attempt in range(5):
            fill_check = get_redis_client()
            try:
                actual_used = fill_check.info().get("used_memory", 0)
            finally:
                try:
                    fill_check.close()
                except Exception:
                    pass

            if actual_used >= target_bytes:
                logger.info(
                    f"Phase {phase_idx + 1}: target reached "
                    f"({actual_used}/{target_bytes} bytes)"
                )
                break

            gap = target_bytes - actual_used
            fill_keys = max(1, gap // value_size_bytes)
            logger.info(
                f"Phase {phase_idx + 1}: fill attempt {fill_attempt + 1}, "
                f"used={actual_used}, target={target_bytes}, gap={gap}, "
                f"writing {fill_keys} more keys"
            )

            fill_results = [None]
            fill_id = 900 + phase_idx * 10 + fill_attempt
            ft = threading.Thread(
                target=memory_worker,
                args=(fill_id, key_prefix, fill_keys, value_size_bytes,
                      pipeline_size, write_ttl, use_cluster, fill_results),
            )
            ft.daemon = True
            ft.start()
            ft.join(timeout=120)

            fr = fill_results[0]
            if fr and fr.get("status") == "complete":
                phase_keys_written += fr.get("keys_written", 0)
                phase_bytes += fr.get("bytes_written", 0)
                phase_errors += fr.get("errors", 0)
                if fr.get("keys_written", 0) == 0:
                    logger.warning(
                        f"Phase {phase_idx + 1}: fill wrote 0 keys, stopping"
                    )
                    break
            else:
                logger.warning(
                    f"Phase {phase_idx + 1}: fill failed, stopping"
                )
                break

        _, used_memory_str, *_ = _read_info_metrics()
        next_client = get_redis_client()
        try:
            current_used = next_client.info().get("used_memory", current_used)
        finally:
            try:
                next_client.close()
            except Exception:
                pass

        phase_summaries.append({
            "phase": phase_idx + 1,
            "target_percent": target_pct,
            "target_bytes": target_bytes,
            "workers": workers,
            "keys_written": phase_keys_written,
            "bytes_written": phase_bytes,
            "errors": phase_errors,
            "used_memory_after": used_memory_str,
        })

        now = time.time()
        if now < phase_end:
            time.sleep(phase_end - now)

    info_after, used_memory_after, evicted_keys, keyspace_hits, keyspace_misses, connected_clients = _read_info_metrics()

    total_keys_written = sum(p["keys_written"] for p in phase_summaries)
    total_errors = sum(p["errors"] for p in phase_summaries)
    total_bytes = sum(p["bytes_written"] for p in phase_summaries)
    total_gb_written = round(total_bytes / (1024 ** 3), 2)

    keys_cleaned = 0
    if cleanup_after:
        keys_cleaned = _cleanup_stress_keys(context, key_prefix)
        logger.info(f"Cleaned {keys_cleaned} stress keys")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "mode": "phased",
            "stress_type": os.environ.get("STRESS_TYPE", "memory_stress"),
            "phases": phase_summaries,
            "value_size_kb": value_size_kb,
            "pipeline_size": pipeline_size,
            "write_ttl": write_ttl,
            "total_keys_written": total_keys_written,
            "total_bytes_written_gb": total_gb_written,
            "write_errors": total_errors,
            "keys_cleaned": keys_cleaned,
            "used_memory_before": used_memory_before,
            "used_memory_after": used_memory_after,
            "maxmemory": maxmemory,
            "eviction_policy": eviction_policy,
            "evicted_keys": evicted_keys,
            "keyspace_hits": keyspace_hits,
            "keyspace_misses": keyspace_misses,
            "connected_clients": connected_clients,
            "elapsed_seconds": int(time.time() - start_ts),
        }),
    }


def _unlink_keys_safely(client, keys):
    pipe = client.pipeline()
    for key in keys:
        pipe.unlink(key)
    pipe.execute()


def _cleanup_stress_keys(context, key_prefix):
    cluster_client = None
    standalone_client = None
    deleted = 0
    batch_size = 1000
    min_remaining_ms = 30000
    keys_batch = []

    try:
        try:
            cluster_client = _cluster_client_from_env()
            client = cluster_client
            logger.info("Cleanup: using RedisCluster client to scan all nodes")
        except Exception as e:
            logger.warning(f"Cleanup: cluster client failed ({e}), falling back to standalone")
            standalone_client = get_redis_client()
            client = standalone_client

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
    finally:
        for c in (cluster_client, standalone_client):
            if c is not None:
                try:
                    c.close()
                except Exception:
                    pass

    return deleted


def lambda_handler(event, context):
    cleanup_after = os.environ.get("MEMORY_CLEANUP_AFTER_STRESS", "true").lower() == "true"
    key_prefix = os.environ.get("KEY_PREFIX", "stress:test:")

    if os.environ.get("MEMORY_PHASE_TARGET_PERCENT", "").strip():
        return _run_phased(context, key_prefix, cleanup_after)

    return _legacy_run(context, key_prefix, cleanup_after)
