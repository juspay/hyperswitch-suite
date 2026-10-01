"""
CPU stress Lambda for Redis/Valkey.

Supports two modes:
1. Legacy flat mode: one constant-intensity burn window controlled by STRESS_DURATION,
   STRESS_THREADS, CPU_BURN_ITERATIONS and CPU_MIXED_MODE.
2. Phased mode (default): a sequence of plateaus, each lasting a configurable duration
   and using configurable thread count + duty cycle to produce ~60% / ~85% / ~100%
   CPU load. Set CPU_PHASE_DURATIONS to an empty string to fall back to legacy mode.

Phased environment variables mirror the aurora-fault-injection pattern:
  CPU_PHASE_DURATIONS="240,240,240"
  CPU_PHASE_THREADS="8,16,32"
  CPU_PHASE_DUTY="0.6,0.85,1.0"
  CPU_BURN_ITERATIONS="500000"
  CPU_MIXED_MODE="false"
"""

import json
import logging
import os
import random
import threading
import time
import uuid

from common import get_redis_client

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_LUA_CPU_BURN = """
local result = 0
local n = tonumber(ARGV[1])
for i = 1, n do
    result = result + math.floor(math.sqrt(i) * 3.14159265358979 / 2.71828182845905)
end
return result
"""


def _parse_csv(env_var, default=None, cast=str):
    raw = os.environ.get(env_var, default)
    if raw is None:
        return []
    return [cast(item.strip()) for item in raw.split(",") if item.strip()]


def _run_flat_burn(key_prefix, mixed_mode):
    duration_seconds = int(os.environ.get("STRESS_DURATION", "300"))
    worker_count = int(os.environ.get("STRESS_THREADS", "1"))
    cpu_burn_iterations = int(os.environ.get("CPU_BURN_ITERATIONS", "500000"))
    end_time = time.time() + duration_seconds
    lock_key = f"{key_prefix}lock:cpu:{uuid.uuid4()}"
    results = {}
    threads = []

    def worker(worker_id):
        client = get_redis_client()
        ops = 0
        try:
            while time.time() < end_time:
                client.eval(_LUA_CPU_BURN, 0, cpu_burn_iterations)
                if mixed_mode:
                    client.set(f"{key_prefix}cpu:{worker_id}:{ops}", str(time.time()))
                    client.get(f"{key_prefix}cpu:{worker_id}:{ops}")
                    client.incr(f"{key_prefix}counter:{worker_id}")
                ops += 1
            results[worker_id] = {"operations": ops}
        except Exception as exc:
            logger.exception("Worker %s failed", worker_id)
            results[worker_id] = {"error": str(exc)}
        finally:
            try:
                client.delete(lock_key)
                client.close()
            except Exception:
                pass

    for i in range(worker_count):
        t = threading.Thread(target=worker, args=(i,))
        t.daemon = True
        t.start()
        threads.append(t)

    for t in threads:
        t.join(timeout=duration_seconds + 60)

    return {
        "statusCode": 200,
        "mode": "flat",
        "duration_seconds": duration_seconds,
        "workers": worker_count,
        "results": results,
    }


def _phase_worker(client_factory, worker_label, lua_script, phase_index, phase_start, phase_end, aggregate_duty, num_threads, jitter_max, mixed_mode, key_prefix, results, index_in_results):
    client = None
    cpu_burn_iterations = int(os.environ.get("CPU_BURN_ITERATIONS", "500000"))
    try:
        client = client_factory()
    except Exception as exc:
        logger.exception("[%s] failed to create Redis client", worker_label)
        results[index_in_results] = {"worker": worker_label, "error": str(exc)}
        return

    if aggregate_duty >= 1.0 or num_threads <= 1:
        personal_duty = aggregate_duty
    else:
        # Linear per-worker duty for a single-server queue. Redis/Valkey has
        # one engine thread; the aggregate offered load is what matters. The
        # Bernoulli-style formula oversubscribes the engine and causes 100%
        # spikes when multiple workers happen to be active at once.
        personal_duty = aggregate_duty / num_threads

    ops = 0
    try:
        sleep_to_start = phase_start - time.time()
        if sleep_to_start > 0:
            time.sleep(sleep_to_start)

        if jitter_max > 0:
            time.sleep(random.uniform(0, jitter_max))

        logger.info(
            "[%s] phase %d aggregate duty %.2f, personal duty %.3f, %d threads",
            worker_label, phase_index + 1, aggregate_duty, personal_duty, num_threads,
        )

        while time.time() < phase_end:
            loop_start = time.time()
            try:
                client.eval(lua_script, 0, cpu_burn_iterations)
                if mixed_mode:
                    key = f"{key_prefix}cpu:{worker_label}:{ops}"
                    client.set(key, str(time.time()))
                    client.get(key)
                    client.incr(f"{key_prefix}counter:{worker_label}")
                ops += 1
            except Exception as exc:
                logger.warning("[%s] operation failed: %s", worker_label, exc)

            if personal_duty < 1.0:
                elapsed = time.time() - loop_start
                if elapsed > 0:
                    sleep_for = elapsed * ((1.0 / personal_duty) - 1.0)
                    # Per-cycle jitter desynchronizes workers without the long
                    # startup ramp that distorts CloudWatch 1-minute averages.
                    sleep_for *= random.uniform(0.85, 1.15)
                    remaining = phase_end - time.time()
                    time.sleep(min(sleep_for, remaining))
    except Exception as exc:
        logger.exception("[%s] unhandled exception in phase %d", worker_label, phase_index + 1)
        results[index_in_results] = {"worker": worker_label, "phase": phase_index + 1, "error": str(exc)}
    finally:
        if client is not None:
            try:
                client.close()
            except Exception:
                pass
        results[index_in_results] = {"worker": worker_label, "phase": phase_index + 1, "operations": ops}


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
            logger.warning("Redis connectivity check attempt %d failed: %s", attempt, exc)
            if client is not None:
                try:
                    client.close()
                except Exception:
                    pass
            if attempt < attempts:
                time.sleep(backoff_seconds)
    logger.error("Redis connectivity check failed after %d attempts: %s", attempts, last_error)
    return False


def _run_phased_burn(key_prefix, mixed_mode):
    durations = _parse_csv("CPU_PHASE_DURATIONS", default="240,240,240", cast=int)
    thread_counts = _parse_csv("CPU_PHASE_THREADS", default="8,16,32", cast=int)
    duties = _parse_csv("CPU_PHASE_DUTY", default="0.6,0.85,1.0", cast=float)
    jitter_max = int(os.environ.get("CPU_PHASE_CYCLE_PERIOD_SECONDS", "10"))

    if not (len(durations) == len(thread_counts) == len(duties)):
        raise ValueError("CPU_PHASE_DURATIONS, CPU_PHASE_THREADS and CPU_PHASE_DUTY must all have the same length")
    if not durations:
        raise ValueError("At least one phase is required when CPU_PHASE_DURATIONS is set")
    if any(d <= 0 for d in durations):
        raise ValueError("All CPU_PHASE_DURATIONS values must be positive integers")
    if any(duty <= 0 or duty > 1.0 for duty in duties):
        raise ValueError("All CPU_PHASE_DUTY values must be in (0, 1.0]")
    if any(t <= 0 for t in thread_counts):
        raise ValueError("All CPU_PHASE_THREADS values must be positive integers")
    if jitter_max <= 0:
        raise ValueError("CPU_PHASE_CYCLE_PERIOD_SECONDS must be a positive integer")

    _ping_with_retry(get_redis_client)

    total_duration = sum(durations)
    start_ts = time.time()
    results_by_phase = [None] * len(durations)
    threads = []
    cumulative_offset = 0.0

    for phase_idx, phase_duration in enumerate(durations):
        phase_start = start_ts + cumulative_offset
        phase_end = phase_start + phase_duration
        cumulative_offset += phase_duration

        num_threads = thread_counts[phase_idx]
        duty = duties[phase_idx]
        phase_results = [None] * num_threads
        results_by_phase[phase_idx] = {
            "phase": phase_idx + 1,
            "threads": num_threads,
            "duty": duty,
            "jitter_max_seconds": jitter_max,
            "duration_seconds": phase_duration,
            "scheduled_start": phase_start,
            "scheduled_end": phase_end,
            "workers": phase_results,
        }

        for worker_idx in range(num_threads):
            worker_label = f"p{phase_idx + 1}-w{worker_idx}"
            t = threading.Thread(
                target=_phase_worker,
                args=(
                    get_redis_client,
                    worker_label,
                    _LUA_CPU_BURN,
                    phase_idx,
                    phase_start,
                    phase_end,
                    duty,
                    num_threads,
                    jitter_max,
                    mixed_mode,
                    key_prefix,
                    phase_results,
                    worker_idx,
                ),
            )
            t.daemon = True
            t.start()
            threads.append(t)

        logger.info(
            "Scheduled phase %d: %d threads, %ss duration, %.0f%% duty, %ss jitter",
            phase_idx + 1,
            num_threads,
            phase_duration,
            duty * 100,
            jitter_max,
        )

    deadline = start_ts + total_duration + 60
    for t in threads:
        remaining = max(0, deadline - time.time())
        t.join(timeout=remaining)

    return {
        "statusCode": 200,
        "mode": "phased",
        "total_duration_seconds": total_duration,
        "phases": results_by_phase,
        "cpu_burn_iterations": int(os.environ.get("CPU_BURN_ITERATIONS", "500000")),
        "cpu_phase_jitter_max_seconds": jitter_max,
        "mixed_mode": mixed_mode,
    }


def lambda_handler(event, context):
    _ = event
    _ = context
    key_prefix = os.environ.get("KEY_PREFIX", "stress:test:")
    mixed_mode = os.environ.get("CPU_MIXED_MODE", "false").lower() == "true"

    if os.environ.get("CPU_PHASE_DURATIONS", "").strip():
        return _run_phased_burn(key_prefix, mixed_mode)

    return _run_flat_burn(key_prefix, mixed_mode)


if __name__ == "__main__":
    print(json.dumps(lambda_handler({}, None)))
