"""
Mixed workload Lambda for Redis/Valkey.

Open-loop, fixed-arrival-rate stress test that sends a configurable mix of
Redis commands (GET, SET, HGET, HSET, INCR) at a target ops/sec per phase.
Measures latency percentiles (p50/p95/p99/p99.9) and optionally emits
CloudWatch custom metrics.

Open-loop means the send schedule is based on absolute time, not on when
the previous response returned.  If Redis is slow the worker falls behind
and does NOT self-throttle or catch up -- it simply resumes at the target
rate from the current time.

Environment variables (all mapped from Terraform variables in main.tf):
  WORKLOAD_PHASE_DURATIONS="60,180,180"
  WORKLOAD_PHASE_OPS_PER_SEC="20000,35000,45000"
  WORKLOAD_COMMAND_MIX="get:60,set:20,hget:10,hset:5,incr:5"
  WORKLOAD_PIPELINE_SIZE=1
  WORKLOAD_KEY_PATTERN="stress:test:{id}"
  WORKLOAD_KEY_COUNT=100000
  WORKLOAD_VALUE_SIZE_BYTES=256
  WORKLOAD_EMIT_CLOUDWATCH_METRICS=false
  WORKLOAD_PHASE_CYCLE_PERIOD_SECONDS=2
  WORKLOAD_THREADS=32        (dedicated thread count; falls back to THREADS)
  ENVIRONMENT=sbx            (from common env, used for CW metric dimension)
"""

import json
import logging
import math
import os
import random
import threading
import time

from common import get_redis_client

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_SUPPORTED_COMMANDS = ("get", "set", "hget", "hset", "incr")

# Cap per-worker latency samples to avoid OOM on high-RPS tests.
# Reservoir sampling keeps a random subset of this size.
_MAX_LATENCY_SAMPLES = 100000


def _parse_csv(env_var, default=None, cast=str):
    raw = os.environ.get(env_var, default)
    if raw is None:
        return []
    return [cast(item.strip()) for item in raw.split(",") if item.strip()]


def _parse_command_mix(raw):
    """Parse ``get:60,set:20,hget:10,hset:5,incr:5`` into ``[(cmd, weight), ...]``.

    Weights need NOT sum to 100; they are normalised by their total at
    selection time.
    """
    pairs = []
    for item in raw.split(","):
        item = item.strip()
        if not item:
            continue
        if ":" not in item:
            raise ValueError(
                f"Invalid command mix entry '{item}': expected 'command:weight'"
            )
        cmd, weight_str = item.rsplit(":", 1)
        cmd = cmd.strip().lower()
        weight = float(weight_str.strip())
        if cmd not in _SUPPORTED_COMMANDS:
            raise ValueError(
                f"Unsupported command '{cmd}' in mix. "
                f"Supported: {', '.join(_SUPPORTED_COMMANDS)}"
            )
        if weight <= 0:
            raise ValueError(f"Weight for '{cmd}' must be positive, got {weight}")
        pairs.append((cmd, weight))
    if not pairs:
        raise ValueError(
            "WORKLOAD_COMMAND_MIX must contain at least one command:weight pair"
        )
    return pairs


def _percentile(sorted_values, pct):
    """Return the *pct*-th percentile of *sorted_values* using nearest-rank.

    Args:
        sorted_values: list of floats sorted in ascending order.
        pct: percentile in the range (0, 100].

    Returns:
        float value at the requested percentile, or 0.0 for an empty list.
    """
    if not sorted_values:
        return 0.0
    if len(sorted_values) == 1:
        return sorted_values[0]
    rank = math.ceil((pct / 100.0) * len(sorted_values))
    rank = max(1, min(rank, len(sorted_values)))
    return sorted_values[rank - 1]


def _build_command(cmd, key_pattern, key_count, value_size):
    """Return ``(method_name, args_tuple)`` for *cmd*.

    The caller invokes ``getattr(client_or_pipe, method_name)(*args)``.
    """
    key_id = random.randint(0, key_count - 1)
    key = key_pattern.replace("{id}", str(key_id))

    if cmd == "get":
        return ("get", (key,))
    if cmd == "set":
        value = os.urandom(value_size)
        return ("set", (key, value))
    if cmd == "hget":
        field = f"field:{random.randint(0, 99)}"
        return ("hget", (key, field))
    if cmd == "hset":
        field = f"field:{random.randint(0, 99)}"
        value = os.urandom(value_size)
        return ("hset", (key, field, value))
    if cmd == "incr":
        return ("incr", (key,))
    raise ValueError(f"Unsupported command: {cmd}")


def _pick_command(mix, total_weight):
    """Pick a command from the weighted *mix* using cumulative weights."""
    r = random.uniform(0, total_weight)
    cumulative = 0.0
    for cmd, weight in mix:
        cumulative += weight
        if r <= cumulative:
            return cmd
    return mix[-1][0]


def _emit_cloudwatch_metrics(environment, phase_idx, operations, errors,
                             p50_ms, p99_ms):
    """Emit CloudWatch custom metrics for a completed phase."""
    try:
        import boto3

        cw = boto3.client(
            "cloudwatch",
            region_name=os.environ.get("AWS_REGION", "us-east-1"),
        )
        dimensions = [
            {"Name": "StressType", "Value": "mixed_workload"},
            {"Name": "Environment", "Value": environment},
        ]
        cw.put_metric_data(
            Namespace="Hyperswitch/ElastiCacheStress",
            MetricData=[
                {
                    "MetricName": "Operations",
                    "Value": operations,
                    "Unit": "Count",
                    "Dimensions": dimensions,
                },
                {
                    "MetricName": "Errors",
                    "Value": errors,
                    "Unit": "Count",
                    "Dimensions": dimensions,
                },
                {
                    "MetricName": "P50Latency",
                    "Value": p50_ms,
                    "Unit": "Milliseconds",
                    "Dimensions": dimensions,
                },
                {
                    "MetricName": "P99Latency",
                    "Value": p99_ms,
                    "Unit": "Milliseconds",
                    "Dimensions": dimensions,
                },
            ],
        )
        logger.info(
            "Emitted CloudWatch metrics for phase %d: ops=%d, errors=%d, "
            "p50=%.2fms, p99=%.2fms",
            phase_idx + 1, operations, errors, p50_ms, p99_ms,
        )
    except Exception as exc:
        logger.warning(
            "Failed to emit CloudWatch metrics for phase %d: %s",
            phase_idx + 1, exc,
        )


def _ping_with_retry(client_factory, attempts=3, backoff_seconds=5):
    last_error = None
    for attempt in range(1, attempts + 1):
        client = None
        try:
            client = client_factory()
            client.ping()
            client.close()
            logger.info("Redis connectivity check passed on attempt %d", attempt)
            return True
        except Exception as exc:
            last_error = exc
            logger.warning(
                "Redis connectivity check attempt %d failed: %s", attempt, exc
            )
            if client is not None:
                try:
                    client.close()
                except Exception:
                    pass
            if attempt < attempts:
                time.sleep(backoff_seconds)
    logger.error(
        "Redis connectivity check failed after %d attempts: %s",
        attempts, last_error,
    )
    return False


def _worker(worker_id, client_factory, phase_idx, phase_start, phase_end,
            per_thread_ops_sec, mix, total_weight, key_pattern, key_count,
            value_size, pipeline_size, jitter_max, phase_latencies,
            results, index_in_results):
    """Open-loop worker: sends commands at fixed intervals.

    The schedule is based on absolute wall-clock time.  If the worker falls
    behind because Redis is slow, it does NOT self-throttle or catch up --
    it simply resumes at the target rate from the current time.
    """
    client = None
    ops = 0
    errors = 0
    local_latencies = []
    latency_sample_count = 0

    try:
        client = client_factory()
    except Exception as exc:
        logger.exception("[mixed-w%d] failed to create Redis client", worker_id)
        results[index_in_results] = {
            "worker": worker_id,
            "phase": phase_idx + 1,
            "error": str(exc),
            "operations": 0,
            "errors": 0,
            "latency_ms": {},
        }
        return

    try:
        sleep_to_start = phase_start - time.time()
        if sleep_to_start > 0:
            time.sleep(sleep_to_start)

        if jitter_max > 0:
            time.sleep(random.uniform(0, jitter_max))

        # Each loop iteration sends one pipeline batch (pipeline_size commands).
        # Schedule batches so the per-thread ops/sec matches the target.
        interval = (
            pipeline_size / per_thread_ops_sec
            if per_thread_ops_sec > 0 else 0
        )
        next_send = time.time()

        logger.info(
            "[mixed-w%d] phase %d started: %.1f ops/sec, interval=%.5fs, "
            "pipeline=%d",
            worker_id, phase_idx + 1, per_thread_ops_sec, interval,
            pipeline_size,
        )

        while time.time() < phase_end:
            now = time.time()
            if now < next_send:
                time.sleep(next_send - now)

            start_ts = time.perf_counter()
            try:
                if pipeline_size > 1:
                    pipe = client.pipeline()
                    for _ in range(pipeline_size):
                        cmd = _pick_command(mix, total_weight)
                        method_name, args = _build_command(
                            cmd, key_pattern, key_count, value_size
                        )
                        getattr(pipe, method_name)(*args)
                    pipe.execute()
                    ops += pipeline_size
                else:
                    cmd = _pick_command(mix, total_weight)
                    method_name, args = _build_command(
                        cmd, key_pattern, key_count, value_size
                    )
                    getattr(client, method_name)(*args)
                    ops += 1
            except Exception as exc:
                errors += 1
                logger.warning(
                    "[mixed-w%d] command failed: %s", worker_id, exc
                )
            finally:
                elapsed_ms = (time.perf_counter() - start_ts) * 1000.0
                latency_sample_count += 1
                if len(local_latencies) < _MAX_LATENCY_SAMPLES:
                    local_latencies.append(elapsed_ms)
                else:
                    # Reservoir sampling: keep a random fixed-size subset so
                    # high-RPS tests don't OOM while still computing percentiles.
                    idx = random.randint(0, latency_sample_count - 1)
                    if idx < _MAX_LATENCY_SAMPLES:
                        local_latencies[idx] = elapsed_ms

            next_send += interval
            if next_send < time.time():
                next_send = time.time()

    except Exception as exc:
        logger.exception(
            "[mixed-w%d] unhandled exception in phase %d",
            worker_id, phase_idx + 1,
        )
        results[index_in_results] = {
            "worker": worker_id,
            "phase": phase_idx + 1,
            "error": str(exc),
            "operations": ops,
            "errors": errors,
            "latency_ms": {},
        }
    finally:
        if client is not None:
            try:
                client.close()
            except Exception:
                pass

        phase_latencies.extend(local_latencies)

        local_latencies.sort()
        results[index_in_results] = {
            "worker": worker_id,
            "phase": phase_idx + 1,
            "operations": ops,
            "errors": errors,
            "latency_samples": latency_sample_count,
            "latency_ms": {
                "p50": round(_percentile(local_latencies, 50), 3),
                "p95": round(_percentile(local_latencies, 95), 3),
                "p99": round(_percentile(local_latencies, 99), 3),
                "p99.9": round(_percentile(local_latencies, 99.9), 3),
            },
        }


def lambda_handler(event, context):
    _ = event
    _ = context

    durations = _parse_csv(
        "WORKLOAD_PHASE_DURATIONS", default="60,180,180", cast=int
    )
    ops_per_sec = _parse_csv(
        "WORKLOAD_PHASE_OPS_PER_SEC", default="20000,35000,45000", cast=int
    )
    command_mix_raw = os.environ.get(
        "WORKLOAD_COMMAND_MIX", "get:60,set:20,hget:10,hset:5,incr:5"
    )
    pipeline_size = int(os.environ.get("WORKLOAD_PIPELINE_SIZE", "1"))
    key_pattern = os.environ.get("WORKLOAD_KEY_PATTERN", "stress:test:{id}")
    key_count = int(os.environ.get("WORKLOAD_KEY_COUNT", "100000"))
    value_size = int(os.environ.get("WORKLOAD_VALUE_SIZE_BYTES", "256"))
    emit_cw = os.environ.get(
        "WORKLOAD_EMIT_CLOUDWATCH_METRICS", "false"
    ).lower() == "true"
    jitter_max = int(os.environ.get(
        "WORKLOAD_PHASE_CYCLE_PERIOD_SECONDS", "2"
    ))
    num_threads = int(
        os.environ.get("WORKLOAD_THREADS", os.environ.get("THREADS", "4"))
    )
    environment = os.environ.get("ENVIRONMENT", "unknown")

    if len(durations) != len(ops_per_sec):
        raise ValueError(
            "WORKLOAD_PHASE_DURATIONS and WORKLOAD_PHASE_OPS_PER_SEC must "
            "have the same length"
        )
    if not durations:
        raise ValueError("At least one phase is required")
    if any(d <= 0 for d in durations):
        raise ValueError("All WORKLOAD_PHASE_DURATIONS values must be positive")
    if any(o <= 0 for o in ops_per_sec):
        raise ValueError(
            "All WORKLOAD_PHASE_OPS_PER_SEC values must be positive"
        )
    if pipeline_size < 1:
        raise ValueError("WORKLOAD_PIPELINE_SIZE must be >= 1")
    if key_count < 1:
        raise ValueError("WORKLOAD_KEY_COUNT must be >= 1")
    if value_size < 1:
        raise ValueError("WORKLOAD_VALUE_SIZE_BYTES must be >= 1")
    if jitter_max < 0:
        raise ValueError("WORKLOAD_PHASE_CYCLE_PERIOD_SECONDS must be >= 0")
    if num_threads < 1:
        raise ValueError("STRESS_THREADS must be >= 1")

    mix = _parse_command_mix(command_mix_raw)
    total_weight = sum(w for _, w in mix)

    _ping_with_retry(get_redis_client)

    total_duration = sum(durations)
    start_ts = time.time()
    results_by_phase = [None] * len(durations)
    phase_latency_lists = [None] * len(durations)
    threads = []
    cumulative_offset = 0.0

    for phase_idx, phase_duration in enumerate(durations):
        phase_start = start_ts + cumulative_offset
        phase_end = phase_start + phase_duration
        cumulative_offset += phase_duration

        target_ops = ops_per_sec[phase_idx]
        per_thread_ops_sec = target_ops / num_threads

        phase_latencies = []
        phase_latency_lists[phase_idx] = phase_latencies
        phase_results = [None] * num_threads
        results_by_phase[phase_idx] = {
            "phase": phase_idx + 1,
            "duration_seconds": phase_duration,
            "target_ops_per_sec": target_ops,
            "threads": num_threads,
            "per_thread_ops_per_sec": round(per_thread_ops_sec, 2),
            "pipeline_size": pipeline_size,
            "jitter_max_seconds": jitter_max,
            "command_mix": command_mix_raw,
            "workers": phase_results,
        }

        for worker_idx in range(num_threads):
            t = threading.Thread(
                target=_worker,
                args=(
                    worker_idx,
                    get_redis_client,
                    phase_idx,
                    phase_start,
                    phase_end,
                    per_thread_ops_sec,
                    mix,
                    total_weight,
                    key_pattern,
                    key_count,
                    value_size,
                    pipeline_size,
                    jitter_max,
                    phase_latencies,
                    phase_results,
                    worker_idx,
                ),
            )
            t.daemon = True
            t.start()
            threads.append(t)

        logger.info(
            "Scheduled phase %d: %d threads, %ss duration, %d ops/sec target "
            "(%.1f/thread), pipeline=%d",
            phase_idx + 1, num_threads, phase_duration, target_ops,
            per_thread_ops_sec, pipeline_size,
        )

    deadline = start_ts + total_duration + 120
    for t in threads:
        remaining = max(0, deadline - time.time())
        t.join(timeout=remaining)

    for phase_idx in range(len(durations)):
        phase_data = results_by_phase[phase_idx]
        if phase_data is None:
            continue

        workers = phase_data["workers"]
        total_ops = sum(w.get("operations", 0) for w in workers if w)
        total_errors = sum(w.get("errors", 0) for w in workers if w)

        phase_latencies = phase_latency_lists[phase_idx]
        phase_latencies.sort()
        p50 = _percentile(phase_latencies, 50)
        p95 = _percentile(phase_latencies, 95)
        p99 = _percentile(phase_latencies, 99)
        p999 = _percentile(phase_latencies, 99.9)

        phase_data["total_operations"] = total_ops
        phase_data["total_errors"] = total_errors
        phase_data["ops_per_sec"] = (
            round(total_ops / durations[phase_idx], 2)
            if durations[phase_idx] > 0 else 0
        )
        phase_data["latency_ms"] = {
            "p50": round(p50, 3),
            "p95": round(p95, 3),
            "p99": round(p99, 3),
            "p99.9": round(p999, 3),
        }
        phase_data["latency_samples"] = len(phase_latencies)

        if emit_cw:
            _emit_cloudwatch_metrics(
                environment, phase_idx, total_ops, total_errors, p50, p99
            )

    return {
        "statusCode": 200,
        "mode": "phased",
        "total_duration_seconds": total_duration,
        "phases": results_by_phase,
        "command_mix": command_mix_raw,
        "pipeline_size": pipeline_size,
        "key_pattern": key_pattern,
        "key_count": key_count,
        "value_size_bytes": value_size,
        "emit_cloudwatch_metrics": emit_cw,
    }


if __name__ == "__main__":
    print(json.dumps(lambda_handler({}, None)))
