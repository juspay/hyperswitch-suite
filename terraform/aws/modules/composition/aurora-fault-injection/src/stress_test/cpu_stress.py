import os
import time
import random
import logging
import json
import threading
import psycopg2
from common import get_conn_params, ensure_pgbench_schema

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def parse_csv(env_var, default, cast=float):
    val = os.environ.get(env_var, default)
    return [cast(x.strip()) for x in val.split(",")]


def _to_bool(raw):
    return str(raw).strip().lower() in ("true", "1", "yes", "on")


def _short_cpu_query(cursor, series_count):
    """Fixed-cost CPU-bound query. Tune series_count so one execution takes
    ~10-30 ms on the target instance."""
    cursor.execute(
        "SELECT count(*) FROM generate_series(1, %s) AS x WHERE md5(x::text) <> ''",
        (series_count,),
    )
    cursor.fetchone()


def controlled_full_worker(conn_params, phase_start, phase_end, series_count, results, idx):
    """Always-active worker: consumes ~100% of one DB vCPU."""
    time.sleep(max(0, phase_start - time.time()))
    logger.info(f"Controlled worker {idx}: always active")

    queries = 0
    conn = None
    try:
        conn = psycopg2.connect(**conn_params)
        conn.autocommit = True
        cursor = conn.cursor()
        while time.time() < phase_end:
            _short_cpu_query(cursor, series_count)
            queries += 1
        cursor.close()
    except Exception as e:
        logger.error(f"Controlled full worker {idx} error: {e}")
        results[idx] = {"queries": queries, "error": str(e)}
        return
    finally:
        if conn is not None:
            try:
                conn.close()
            except Exception:
                pass

    results[idx] = {"queries": queries}


def controlled_duty_worker(conn_params, phase_start, phase_end, series_count, duty, results, idx):
    """Fractional worker: runs queries for on_seconds, then sleeps for off_seconds.

    This is connection-level duty cycling, NOT query-level. The query is short
    (~10-30 ms) so the ON/OFF windows are honored.
    """
    time.sleep(max(0, phase_start - time.time()))
    logger.info(f"Controlled worker {idx}: fractional duty {duty*100:.0f}%")

    on_seconds = 2.0
    off_seconds = on_seconds * (1.0 / duty - 1.0) if duty > 0 else 0.0

    queries = 0
    conn = None
    try:
        conn = psycopg2.connect(**conn_params)
        conn.autocommit = True
        cursor = conn.cursor()
        while time.time() < phase_end:
            on_deadline = time.time() + on_seconds
            while time.time() < on_deadline and time.time() < phase_end:
                _short_cpu_query(cursor, series_count)
                queries += 1
            if time.time() >= phase_end:
                break
            remaining = phase_end - time.time()
            if off_seconds > 0 and remaining > 0:
                time.sleep(min(off_seconds, remaining))
        cursor.close()
    except Exception as e:
        logger.error(f"Controlled duty worker {idx} error: {e}")
        results[idx] = {"queries": queries, "error": str(e)}
        return
    finally:
        if conn is not None:
            try:
                conn.close()
            except Exception:
                pass

    results[idx] = {"queries": queries}


def tpcb_staged_worker(conn_params, phase_num, phase_start, phase_end, duty_cycle, results, idx):
    time.sleep(max(0, phase_start - time.time()))
    logger.info(f"Phase {phase_num} worker {idx}: now active at {duty_cycle*100:.0f}% duty")

    conn = None
    transactions = 0
    try:
        conn = psycopg2.connect(**conn_params)
        conn.autocommit = False
        cursor = conn.cursor()

        while time.time() < phase_end:
            aid = random.randint(1, 100000)
            bid = random.randint(1, 10)
            tid = random.randint(1, 100)
            delta = random.randint(1, 1000)

            tx_start = time.time()
            try:
                cursor.execute(
                    "UPDATE pgbench_accounts SET abalance = abalance + %s WHERE aid = %s",
                    (delta, aid),
                )
                cursor.execute(
                    "SELECT abalance FROM pgbench_accounts WHERE aid = %s", (aid,)
                )
                cursor.fetchone()
                cursor.execute(
                    "UPDATE pgbench_tellers SET tbalance = tbalance + %s WHERE tid = %s",
                    (delta, tid),
                )
                cursor.execute(
                    "UPDATE pgbench_branches SET bbalance = bbalance + %s WHERE bid = %s",
                    (delta, bid),
                )
                cursor.execute(
                    "INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (%s, %s, %s, %s, CURRENT_TIMESTAMP)",
                    (tid, bid, aid, delta),
                )
                conn.commit()
                transactions += 1
            except psycopg2.Error:
                conn.rollback()
                raise

            tx_elapsed = time.time() - tx_start
            if duty_cycle < 1.0 and tx_elapsed > 0:
                sleep_time = tx_elapsed * (1.0 / duty_cycle - 1.0)
                time.sleep(sleep_time)

        cursor.close()
    except Exception as e:
        logger.error(f"Worker {idx} error: {e}")
        results[idx] = {"transactions": transactions, "error": str(e)}
        return
    else:
        results[idx] = {"transactions": transactions}

    if conn:
        try:
            conn.close()
        except Exception:
            pass


def generate_series_staged_worker(conn_params, phase_num, phase_start, phase_end, duty_cycle, results, idx):
    time.sleep(max(0, phase_start - time.time()))
    logger.info(f"Phase {phase_num} worker {idx}: now active at {duty_cycle*100:.0f}% duty")

    conn = None
    txns = 0
    try:
        conn = psycopg2.connect(**conn_params)
        conn.autocommit = True
        cursor = conn.cursor()

        while time.time() < phase_end:
            q_start = time.time()
            cursor.execute("""
                SELECT count(*) FROM generate_series(1, 1000000) AS x
                WHERE (x::float8 * x::float8 + sqrt(x::float8))::bigint % 13 = 0
            """)
            cursor.fetchone()
            txns += 1

            q_elapsed = time.time() - q_start
            if duty_cycle < 1.0 and q_elapsed > 0:
                sleep_time = q_elapsed * (1.0 / duty_cycle - 1.0)
                time.sleep(sleep_time)

        cursor.close()
    except Exception as e:
        logger.error(f"Worker {idx} error: {e}")
        results[idx] = {"transactions": txns, "error": str(e)}
        return
    else:
        results[idx] = {"transactions": txns}

    if conn:
        try:
            conn.close()
        except Exception:
            pass


def pure_cpu_staged_worker(conn_params, phase_num, phase_start, phase_end, duty_cycle, series_count, queries_per_loop, results, idx):
    time.sleep(max(0, phase_start - time.time()))
    logger.info(f"Phase {phase_num} worker {idx}: pure CPU burn active at {duty_cycle*100:.0f}% duty")

    conn = None
    queries = 0
    try:
        conn = psycopg2.connect(**conn_params)
        conn.autocommit = True
        cursor = conn.cursor()

        while time.time() < phase_end:
            loop_start = time.time()
            for _ in range(queries_per_loop):
                count_this_query = series_count + random.randint(-series_count // 10, series_count // 10)
                count_this_query = max(100000, count_this_query)
                cursor.execute(
                    """
                    SELECT count(*)
                    FROM generate_series(1, %s) AS x
                    WHERE md5(x::text) <> ''
                    """,
                    (count_this_query,),
                )
                cursor.fetchone()
                queries += 1

            loop_elapsed = time.time() - loop_start
            if duty_cycle < 1.0 and loop_elapsed > 0:
                sleep_time = loop_elapsed * (1.0 / duty_cycle - 1.0)
                remaining = phase_end - time.time()
                time.sleep(min(sleep_time, remaining))

        cursor.close()
    except Exception as e:
        logger.error(f"Pure CPU worker {idx} error: {e}")
        results[idx] = {"queries": queries, "error": str(e)}
        return
    else:
        results[idx] = {"queries": queries}

    if conn:
        try:
            conn.close()
        except Exception:
            pass


def lambda_handler(event, context):
    durations = parse_csv("PHASE_DURATIONS", "240,300,300", int)
    phase_threads = parse_csv("CPU_PHASE_THREADS", "2,2,16", int)
    phase_duty = parse_csv("CPU_PHASE_DUTY", "0.6,0.8,1.0", float)
    phase_pure_cpu = [_to_bool(x) for x in parse_csv("CPU_PHASE_PURE_CPU", "false,false,true", str)]
    pure_cpu_series_count = int(os.environ.get("CPU_PURE_CPU_SERIES_COUNT", "1000000"))
    pure_cpu_queries_per_loop = int(os.environ.get("CPU_PURE_CPU_QUERIES_PER_LOOP", "10"))
    stress_type = os.environ.get("STRESS_TYPE", "cpu_stress")

    cpu_phase_targets_raw = os.environ.get("CPU_PHASE_TARGETS", "").strip()
    phase_targets = []
    if cpu_phase_targets_raw:
        phase_targets = [
            float(entry.strip()) if entry.strip() else None
            for entry in cpu_phase_targets_raw.split(",")
        ]
    vcpus = int(os.environ.get("CPU_VCPUS", "4"))

    baseline_pct = float(os.environ.get("CPU_PHASE_BASELINE_PCT", "87.0"))
    phase_extra_threads = parse_csv("CPU_PHASE_EXTRA_THREADS", "0,0,0", int)

    total_duration = sum(durations)
    logger.info(f"Staged CPU stress: {len(durations)} phases, {total_duration}s total")
    logger.info(f"TPC-B baseline estimate: {baseline_pct}%, vCPUs: {vcpus}")
    for i, d in enumerate(durations):
        target = phase_targets[i] if i < len(phase_targets) else None
        t = phase_threads[i] if i < len(phase_threads) else 0
        duty = phase_duty[i] if i < len(phase_duty) else 0.0
        pure = phase_pure_cpu[i] if i < len(phase_pure_cpu) else False
        extra_t = phase_extra_threads[i] if i < len(phase_extra_threads) else 0
        if target is not None:
            boost = max(0.0, target - baseline_pct)
            eff = boost / 100.0 * vcpus
            logger.info(f"  Phase {i+1}: {d}s, TPC-B {t} threads + boost {boost:.1f}% ({eff:.2f} conn) + {extra_t} extra pure-CPU threads")
        else:
            logger.info(f"  Phase {i+1}: {d}s, legacy {t} threads, {duty*100:.0f}% duty, pure_cpu={pure}, extra={extra_t}")

    conn_params = get_conn_params()
    schema_ready = ensure_pgbench_schema(conn_params, scale=10)

    def choose_legacy_worker_fn(pure_cpu_flag):
        if pure_cpu_flag:
            return pure_cpu_staged_worker
        return tpcb_staged_worker if schema_ready else generate_series_staged_worker

    phase_starts = []
    cumulative = 0
    for d in durations:
        phase_starts.append(cumulative)
        cumulative += d

    now = time.time()
    all_threads = []
    all_results = []

    for phase_i in range(len(durations)):
        phase_start_abs = now + phase_starts[phase_i]
        phase_end_abs = now + phase_starts[phase_i] + durations[phase_i]
        target_pct = phase_targets[phase_i] if phase_i < len(phase_targets) else None

        num_threads = phase_threads[phase_i]
        duty = phase_duty[phase_i]
        pure_cpu = phase_pure_cpu[phase_i] if phase_i < len(phase_pure_cpu) else False
        worker_fn = choose_legacy_worker_fn(pure_cpu)

        extra_effective = 0.0
        if target_pct is not None:
            extra_pct = max(0.0, target_pct - baseline_pct)
            extra_effective = extra_pct / 100.0 * vcpus

        full_extra = int(extra_effective)
        fractional_extra = extra_effective - full_extra
        num_extra = full_extra + (1 if fractional_extra > 0.01 else 0)
        extra_threads_this_phase = phase_extra_threads[phase_i] if phase_i < len(phase_extra_threads) else 0
        total_workers = num_threads + num_extra + extra_threads_this_phase

        results_slot = [None] * total_workers
        all_results.append(results_slot)

        for j in range(num_threads):
            if pure_cpu:
                t = threading.Thread(
                    target=worker_fn,
                    args=(conn_params, phase_i + 1, phase_start_abs, phase_end_abs, duty, pure_cpu_series_count, pure_cpu_queries_per_loop, results_slot, j),
                )
            else:
                t = threading.Thread(
                    target=worker_fn,
                    args=(conn_params, phase_i + 1, phase_start_abs, phase_end_abs, duty, results_slot, j),
                )
            t.daemon = True
            t.start()
            all_threads.append(t)

        for j in range(full_extra):
            t = threading.Thread(
                target=controlled_full_worker,
                args=(conn_params, phase_start_abs, phase_end_abs, pure_cpu_series_count, results_slot, num_threads + j),
            )
            t.daemon = True
            t.start()
            all_threads.append(t)

        if fractional_extra > 0.01:
            t = threading.Thread(
                target=controlled_duty_worker,
                args=(conn_params, phase_start_abs, phase_end_abs, pure_cpu_series_count, fractional_extra, results_slot, num_threads + full_extra),
            )
            t.daemon = True
            t.start()
            all_threads.append(t)

        for j in range(extra_threads_this_phase):
            t = threading.Thread(
                target=controlled_full_worker,
                args=(conn_params, phase_start_abs, phase_end_abs, pure_cpu_series_count, results_slot, num_threads + num_extra + j),
            )
            t.daemon = True
            t.start()
            all_threads.append(t)

        logger.info(
            f"Phase {phase_i+1}: scheduled {num_threads} legacy + {num_extra} boost + {extra_threads_this_phase} extra workers, "
            f"target={target_pct}%, baseline={baseline_pct}%, boost={extra_effective:.2f} effective"
        )

    total_duration = sum(durations)
    for t in all_threads:
        t.join(timeout=total_duration + 60)

    total_ops = 0
    errors = []
    phase_results = []
    for phase_i, results_slot in enumerate(all_results):
        phase_ops = sum((r.get("transactions", 0) + r.get("queries", 0)) for r in results_slot if r) if results_slot else 0
        phase_errors = [r["error"] for r in results_slot if r and "error" in r]
        total_ops += phase_ops
        errors.extend(phase_errors)
        result = {
            "phase": phase_i + 1,
            "duration_s": durations[phase_i],
            "operations": phase_ops,
            "errors": len(phase_errors),
        }
        if phase_i < len(phase_targets) and phase_targets[phase_i] is not None:
            result["mode"] = "tpcb_plus_boost" if not phase_pure_cpu[phase_i] else "legacy_plus_boost"
            result["target_cpu_pct"] = phase_targets[phase_i]
            result["baseline_cpu_pct"] = baseline_pct
            result["threads"] = phase_threads[phase_i]
            result["duty_cycle"] = phase_duty[phase_i]
            result["pure_cpu_legacy"] = phase_pure_cpu[phase_i] if phase_i < len(phase_pure_cpu) else False
            result["boost_effective_connections"] = max(0.0, (phase_targets[phase_i] - baseline_pct) / 100.0 * vcpus)
            result["extra_pure_cpu_threads"] = phase_extra_threads[phase_i] if phase_i < len(phase_extra_threads) else 0
        else:
            result["mode"] = "tpcb_like" if not phase_pure_cpu[phase_i] else "pure_cpu_legacy"
            result["threads"] = phase_threads[phase_i]
            result["duty_cycle"] = phase_duty[phase_i]
            result["pure_cpu"] = phase_pure_cpu[phase_i] if phase_i < len(phase_pure_cpu) else False
            result["extra_pure_cpu_threads"] = phase_extra_threads[phase_i] if phase_i < len(phase_extra_threads) else 0
        phase_results.append(result)

    phase_modes = {
        phase_results[i]["mode"]
        for i in range(len(phase_results))
    }
    overall_mode = "mixed" if len(phase_modes) > 1 else (next(iter(phase_modes)) if phase_modes else "unknown")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "stress_type": stress_type,
            "mode": overall_mode,
            "total_operations": total_ops,
            "pure_cpu_series_count": pure_cpu_series_count,
            "elapsed_seconds": total_duration,
            "phases": phase_results,
            "error_count": len(errors),
            "errors": errors[:10],
        }),
    }
