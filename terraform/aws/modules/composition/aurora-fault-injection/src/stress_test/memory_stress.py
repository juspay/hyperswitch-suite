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


def hold_temp_buffers_worker(conn_params, temp_buffers_mb, work_mem_mb, temp_rows, hold_duration, results, idx):
    conn = None
    try:
        conn = psycopg2.connect(**conn_params)
        conn.autocommit = True
        cursor = conn.cursor()

        cursor.execute("SET max_parallel_workers_per_gather = 0")
        cursor.execute(f"SET temp_buffers = '{temp_buffers_mb}MB'")
        cursor.execute(f"SET work_mem = '{work_mem_mb}MB'")

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS memory_stress_pin (
                id serial PRIMARY KEY,
                worker integer,
                tstamp timestamp default now()
            )
        """)
        cursor.execute("INSERT INTO memory_stress_pin (worker) VALUES (%s)", (idx,))

        cursor.execute(f"""
            CREATE TEMP TABLE mem_hog_{idx} AS
            SELECT generate_series(1, {temp_rows}) AS n, repeat('x', 80) AS payload
        """)
        cursor.execute(f"SELECT pg_size_pretty(pg_total_relation_size('mem_hog_{idx}'))")
        size = cursor.fetchone()[0]

        results[idx] = {"status": "holding", "temp_size": size, "temp_buffers_mb": temp_buffers_mb}
        logger.info(f"Worker {idx}: temp table created ({size}), holding for {hold_duration}s")

        cursor.execute(f"SELECT pg_sleep({hold_duration})")

        cursor.execute(f"DROP TABLE IF EXISTS mem_hog_{idx}")
        cursor.close()
    except Exception as e:
        logger.error(f"Temp buffer worker {idx} error: {e}")
        results[idx] = {"status": "error", "error": str(e)}
    finally:
        if conn:
            try:
                conn.close()
            except Exception:
                pass


def array_agg_worker(conn_params, agg_rows, arrays_per_worker, work_mem_mb, hold_duration, results, idx):
    conn = None
    try:
        conn = psycopg2.connect(**conn_params)
        conn.autocommit = True
        cursor = conn.cursor()

        cursor.execute("SET max_parallel_workers_per_gather = 0")
        cursor.execute(f"SET work_mem = '{work_mem_mb}MB'")

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS memory_stress_pin (
                id serial PRIMARY KEY,
                worker integer,
                tstamp timestamp default now()
            )
        """)
        cursor.execute("INSERT INTO memory_stress_pin (worker) VALUES (%s)", (idx,))

        logger.info(f"Worker {idx}: building {arrays_per_worker} arrays of {agg_rows} elements each...")
        array_vars = ", ".join(f"big_arr_{i} text[]" for i in range(arrays_per_worker))
        array_builds = "\n".join(
            f"SELECT array_agg(md5(random()::text)) INTO big_arr_{i} FROM generate_series(1, {agg_rows});"
            for i in range(arrays_per_worker)
        )
        cursor.execute(f"""
            DO $$
            DECLARE
                {array_vars}
            BEGIN
                {array_builds}
                RAISE NOTICE 'Worker {idx} done: {arrays_per_worker} arrays held, sleeping...';
                PERFORM pg_sleep({hold_duration});
            END $$;
        """)
        results[idx] = {"status": "complete", "agg_rows": agg_rows, "arrays_per_worker": arrays_per_worker}
        cursor.close()
    except Exception as e:
        logger.error(f"Array agg worker {idx} error: {e}")
        results[idx] = {"status": "error", "error": str(e)}
    finally:
        if conn:
            try:
                conn.close()
            except Exception:
                pass


def lambda_handler(event, context):
    durations_raw = os.environ.get("MEM_PHASE_DURATIONS", os.environ.get("PHASE_DURATIONS", "240,300,300"))
    durations = [int(x.strip()) for x in durations_raw.split(",")]
    phase_idle = parse_csv("MEM_PHASE_IDLE", "50,150,300", int)
    phase_sort = parse_csv("MEM_PHASE_SORT", "5,10,20", int)
    phase_temp_mb = parse_csv("MEM_PHASE_TEMP_MB", "256,512,1024", int)
    phase_agg_rows = parse_csv("MEM_PHASE_AGG_ROWS", "5000000,10000000,20000000", int)
    work_mem_mb = int(os.environ.get("MEM_WORK_MEM_MB", "512"))
    agg_rows_max = int(os.environ.get("MEM_AGG_ROWS_MAX", "20000000"))
    arrays_per_worker = int(os.environ.get("MEM_ARRAYS_PER_WORKER", "3"))
    temp_rows_max = int(os.environ.get("MEM_TEMP_ROWS_MAX", "5000000"))
    stress_type = os.environ.get("STRESS_TYPE", "memory_stress")

    total_duration = sum(durations)
    logger.info(f"Staged memory stress: {len(durations)} phases, {total_duration}s total")
    logger.info(f"work_mem={work_mem_mb}MB, agg_rows_max={agg_rows_max}, arrays_per_worker={arrays_per_worker}, temp_rows_max={temp_rows_max}")
    for i in range(len(durations)):
        logger.info(
            f"  Phase {i+1}: {durations[i]}s, "
            f"idle={phase_idle[i]}, sort={phase_sort[i]}, "
            f"temp={phase_temp_mb[i]}MB, agg_rows={phase_agg_rows[i]}, arrays={arrays_per_worker}"
        )

    conn_params = get_conn_params()

    all_idle_conns = []
    all_threads = []
    all_results = []

    phase_starts = []
    cumulative = 0
    for d in durations:
        phase_starts.append(cumulative)
        cumulative += d

    now = time.time()
    prev_idle = 0
    prev_sort = 0

    for phase_i in range(len(durations)):
        phase_start_abs = now + phase_starts[phase_i]
        remaining_hold = total_duration - phase_starts[phase_i]

        target_idle = phase_idle[phase_i]
        target_sort = phase_sort[phase_i]
        new_idle = target_idle - prev_idle
        new_sort = target_sort - prev_sort

        time.sleep(max(0, phase_start_abs - time.time()))
        logger.info(
            f"Phase {phase_i+1} starting: +{new_idle} idle conns (total {target_idle}), "
            f"+{new_sort} sort sessions (total {target_sort})"
        )

        for _ in range(new_idle):
            try:
                conn = psycopg2.connect(**conn_params)
                all_idle_conns.append(conn)
            except psycopg2.Error as e:
                logger.warning(f"Idle conn failed: {e}")

        results_slot = [None] * (new_sort * 2)
        all_results.append(results_slot)

        for j in range(new_sort):
            temp_mb = phase_temp_mb[phase_i]
            temp_rows = min(phase_agg_rows[phase_i], temp_rows_max)
            t = threading.Thread(
                target=hold_temp_buffers_worker,
                args=(conn_params, temp_mb, work_mem_mb, temp_rows, remaining_hold, results_slot, j),
            )
            t.daemon = True
            t.start()
            all_threads.append(t)

        for j in range(new_sort):
            agg_rows = min(phase_agg_rows[phase_i], agg_rows_max)
            t = threading.Thread(
                target=array_agg_worker,
                args=(conn_params, agg_rows, arrays_per_worker, work_mem_mb, remaining_hold, results_slot, new_sort + j),
            )
            t.daemon = True
            t.start()
            all_threads.append(t)

        logger.info(f"Phase {phase_i+1}: started {new_sort} temp_buffer + {new_sort} array_agg workers")
        prev_idle = target_idle
        prev_sort = target_sort

    logger.info(f"All phases launched. Waiting for {total_duration}s total duration...")

    for t in all_threads:
        t.join(timeout=total_duration + 60)

    for conn in all_idle_conns:
        try:
            conn.close()
        except Exception:
            pass

    total_temp_ok = 0
    total_temp_err = 0
    total_agg_ok = 0
    total_agg_err = 0
    phase_results = []

    for phase_i, results_slot in enumerate(all_results):
        sort_count = phase_sort[phase_i] - (phase_sort[phase_i - 1] if phase_i > 0 else 0)
        temp_ok = sum(
            1 for r in results_slot[:sort_count]
            if r and r.get("status") in ("holding", "complete")
        )
        temp_err = sum(
            1 for r in results_slot[:sort_count]
            if r and r.get("status") == "error"
        )
        agg_ok = sum(
            1 for r in results_slot[sort_count:]
            if r and r.get("status") in ("holding", "complete")
        )
        agg_err = sum(
            1 for r in results_slot[sort_count:]
            if r and r.get("status") == "error"
        )
        total_temp_ok += temp_ok
        total_temp_err += temp_err
        total_agg_ok += agg_ok
        total_agg_err += agg_err
        phase_results.append({
            "phase": phase_i + 1,
            "idle_conns_total": phase_idle[phase_i],
            "sort_sessions_total": phase_sort[phase_i],
            "temp_buffer_ok": temp_ok,
            "temp_buffer_err": temp_err,
            "array_agg_ok": agg_ok,
            "array_agg_err": agg_err,
        })

    temp_mem_gb = round(
        sum(total_temp_ok * mb for mb in phase_temp_mb) / 1024, 1
    )
    agg_mem_gb = round(
        sum(total_agg_ok * rows * 40 for rows in phase_agg_rows) / (1024 ** 3), 1
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "stress_type": stress_type,
            "idle_connections_held": len(all_idle_conns),
            "temp_buffer_sessions_ok": total_temp_ok,
            "temp_buffer_errors": total_temp_err,
            "array_agg_sessions_ok": total_agg_ok,
            "array_agg_errors": total_agg_err,
            "temp_memory_gb": temp_mem_gb,
            "array_agg_memory_gb": agg_mem_gb,
            "total_potential_memory_gb": round(temp_mem_gb + agg_mem_gb, 1),
            "elapsed_seconds": total_duration,
            "phases": phase_results,
        }),
    }
