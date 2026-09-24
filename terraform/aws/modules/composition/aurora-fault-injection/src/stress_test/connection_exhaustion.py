import os
import time
import logging
import json
import psycopg2
import threading
from common import get_conn_params

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def parse_csv(env_var, default, cast=int):
    val = os.environ.get(env_var, default)
    return [cast(x) for x in val.split(",")]


def connect_hold_worker(conn_params, end_time, batch_size, hold_seconds, ramp_seconds, results, idx):
    start_time = time.time()
    connections_held = 0
    transactions = 0
    errors = 0
    held_conns = []

    # Spread connection openings across ramp_seconds to avoid a steep spike.
    # After the ramp, connections are held until the global end time.
    ramp_end = min(end_time, start_time + ramp_seconds)

    for i in range(batch_size):
        if time.time() >= end_time:
            break

        remaining_connections = batch_size - i
        remaining_ramp_time = ramp_end - time.time()
        if remaining_ramp_time > 0 and remaining_connections > 0 and i > 0:
            time.sleep(remaining_ramp_time / remaining_connections)

        try:
            conn = psycopg2.connect(**conn_params)
            conn.autocommit = True
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchone()
            cursor.close()
            held_conns.append(conn)
            connections_held += 1
            transactions += 1
        except psycopg2.Error:
            errors += 1

    # Hold until the global end time. Sleep in small chunks so we remain
    # responsive and can keep the Python GIL from blocking other threads.
    while time.time() < end_time:
        time.sleep(min(1.0, end_time - time.time()))

    for conn in held_conns:
        try:
            conn.close()
        except Exception:
            pass

    results[idx] = {
        "connections_held": connections_held,
        "transactions": transactions,
        "errors": errors,
    }


def lambda_handler(event, context):
    durations = parse_csv("PHASE_DURATIONS", "240,300,300", int)
    phase_threads = parse_csv("CONN_PHASE_THREADS", "20,40,56", int)
    batch_size = int(os.environ.get("CONN_BATCH_SIZE", "30"))
    hold_seconds = int(os.environ.get("CONN_HOLD_SECONDS", "5"))
    ramp_seconds = int(os.environ.get("CONN_RAMP_SECONDS", "60"))
    stress_type = os.environ.get("STRESS_TYPE", "connection_exhaustion")

    total_duration = sum(durations)
    logger.info(
        f"Staged connection exhaustion: {len(durations)} phases, {total_duration}s total, "
        f"batch={batch_size}, hold={hold_seconds}s, ramp={ramp_seconds}s"
    )
    for i, (d, t) in enumerate(zip(durations, phase_threads)):
        peak = t * batch_size
        logger.info(f"  Phase {i+1}: {d}s, {t} threads, peak concurrent ~{peak}")

    conn_params = get_conn_params()

    phase_starts = []
    cumulative = 0
    for d in durations:
        phase_starts.append(cumulative)
        cumulative += d

    now = time.time()
    total_end = now + total_duration

    all_threads = []
    all_results = []

    for phase_i in range(len(durations)):
        phase_start_abs = now + phase_starts[phase_i]
        target_threads = phase_threads[phase_i]
        prev_threads = phase_threads[phase_i - 1] if phase_i > 0 else 0
        new_threads = target_threads - prev_threads

        time.sleep(max(0, phase_start_abs - time.time()))
        logger.info(
            f"Phase {phase_i+1} starting: +{new_threads} threads "
            f"(total {target_threads}, peak ~{target_threads * batch_size})"
        )

        results_slot = [None] * new_threads
        all_results.append(results_slot)

        for j in range(new_threads):
            t = threading.Thread(
                target=connect_hold_worker,
                args=(conn_params, total_end, batch_size, hold_seconds, ramp_seconds, results_slot, j),
            )
            t.daemon = True
            t.start()
            all_threads.append(t)

    logger.info(f"All phases launched. Waiting for {total_duration}s...")

    for t in all_threads:
        t.join(timeout=total_duration + 60)

    total_held = 0
    total_txns = 0
    total_errors = 0
    phase_results = []

    for phase_i, results_slot in enumerate(all_results):
        phase_held = sum(r["connections_held"] for r in results_slot if r) if results_slot else 0
        phase_txns = sum(r["transactions"] for r in results_slot if r) if results_slot else 0
        phase_errors = sum(r["errors"] for r in results_slot if r) if results_slot else 0
        total_held += phase_held
        total_txns += phase_txns
        total_errors += phase_errors

        new_threads = phase_threads[phase_i] - (phase_threads[phase_i - 1] if phase_i > 0 else 0)
        phase_results.append({
            "phase": phase_i + 1,
            "new_threads": new_threads,
            "total_threads": phase_threads[phase_i],
            "peak_concurrent": phase_threads[phase_i] * batch_size,
            "connections_held": phase_held,
            "errors": phase_errors,
        })

    return {
        "statusCode": 200,
        "body": json.dumps({
            "stress_type": stress_type,
            "total_connections_opened": total_held,
            "total_connect_cycles": total_txns,
            "total_errors": total_errors,
            "elapsed_seconds": total_duration,
            "batch_size": batch_size,
            "hold_seconds": hold_seconds,
            "phases": phase_results,
        }),
    }
