import os
import time
import json
import logging
import socket
import threading

from common import get_redis_client, discover_primary_host

logger = logging.getLogger()
logger.setLevel(logging.INFO)

PING_REQ = b"*1\r\n$4\r\nPING\r\n"
PONG = b"+PONG\r\n"


def open_and_handshake(host, port, timeout=10):
    """Open a raw TCP socket to Redis, send RESP PING, read +PONG.

    Returns the open socket on success or None on failure. Using raw sockets
    instead of redis-py clients minimises per-connection memory/CPU overhead so
    thousands of connections can be held within a single Lambda invocation.
    """
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        sock.connect((host, port))
        sock.sendall(PING_REQ)
        resp = sock.recv(64)
        if resp != PONG:
            logger.warning(f"Unexpected PING response: {resp!r}")
            sock.close()
            return None
        return sock
    except Exception as e:
        try:
            sock.close()
        except Exception:
            pass
        return None


def connection_worker(idx, host, port, end_time, batch_size, target_total,
                      rapid_churn, shared_state, results):
    """Per-thread connection exhaustion worker.

    Opens raw TCP/RESP sockets in batches until the global held-pool reaches
    ``target_total``, then optionally churns (open/handshake/close repeatedly)
    while still holding the pool, until ``end_time``.
    """
    held = []
    opened = 0
    errors = 0
    churn_opened = 0
    last_log = 0

    try:
        while time.time() < end_time:
            with shared_state["lock"]:
                total_held = shared_state["total_held"]

            if total_held < target_total:
                remaining = target_total - total_held
                batch = min(batch_size, remaining)
                for _ in range(batch):
                    with shared_state["lock"]:
                        if shared_state["total_held"] >= target_total:
                            break
                    sock = open_and_handshake(host, port)
                    if sock is not None:
                        held.append(sock)
                        opened += 1
                        with shared_state["lock"]:
                            shared_state["total_held"] += 1
                    else:
                        errors += 1
                if opened - last_log >= 250:
                    with shared_state["lock"]:
                        global_held = shared_state["total_held"]
                    logger.info(
                        f"Worker {idx}: opened {opened} "
                        f"(total held={global_held})"
                    )
                    last_log = opened
                time.sleep(0.05)
            elif rapid_churn:
                sock = open_and_handshake(host, port)
                if sock is not None:
                    churn_opened += 1
                    try:
                        sock.close()
                    except Exception:
                        pass
                else:
                    errors += 1
                time.sleep(0.05)
            else:
                time.sleep(1.0)
    except Exception as e:
        logger.error(f"Worker {idx} error: {e}")
        errors += 1
    finally:
        for s in held:
            try:
                s.close()
            except Exception:
                pass
        with shared_state["lock"]:
            shared_state["total_held"] -= len(held)
        results[idx] = {
            "connections_opened": opened,
            "churn_opened": churn_opened,
            "errors": errors,
            "held_at_exit": len(held),
        }


def lambda_handler(event, context):
    duration = int(event.get("duration", os.environ.get("DURATION", "300")))
    threads = int(event.get("threads", os.environ.get("CONNECTION_THREADS", "48")))
    batch_size = int(event.get("batch_size", os.environ.get("CONNECTION_BATCH_SIZE", "100")))
    target_total = int(event.get("target_total", os.environ.get("CONNECTION_TARGET_TOTAL", "5000")))
    rapid_churn = str(event.get("rapid_churn", os.environ.get("CONNECTION_RAPID_CHURN", "false"))).lower() == "true"
    redis_host = discover_primary_host()
    redis_port = int(os.environ.get("REDIS_PORT", "6379"))
    stress_type = os.environ.get("STRESS_TYPE", "connection_exhaustion")

    logger.info(
        f"Connection exhaustion: threads={threads}, batch={batch_size}, "
        f"target_total={target_total}, rapid_churn={rapid_churn}, "
        f"duration={duration}s"
    )

    info_client = get_redis_client()
    try:
        info_client.ping()
        info_before = info_client.info()
        maxclients_before = info_before.get("maxclients", "?")
        connected_before = info_before.get("connected_clients", "?")
        logger.info(
            f"Before: connected_clients={connected_before}, maxclients={maxclients_before}"
        )
    finally:
        try:
            info_client.close()
        except Exception as e:
            logger.warning(f"info_client close error: {e}")

    shared_state = {"total_held": 0, "lock": threading.Lock()}
    results = [None] * threads
    thread_list = []
    end_time = time.time() + duration

    for i in range(threads):
        t = threading.Thread(
            target=connection_worker,
            args=(
                i, redis_host, redis_port, end_time, batch_size,
                target_total, rapid_churn, shared_state, results,
            ),
        )
        t.daemon = True
        t.start()
        thread_list.append(t)

    for t in thread_list:
        t.join(timeout=duration + 60)

    total_opened = sum(r["connections_opened"] for r in results if r)
    total_churn = sum(r["churn_opened"] for r in results if r)
    total_errors = sum(r["errors"] for r in results if r)

    info_client = None
    connected_after = "?"
    rejected = 0
    maxclients_after = "?"
    for attempt in range(1, 4):
        try:
            info_client = get_redis_client()
            info_after = info_client.info()
            connected_after = info_after.get("connected_clients", "?")
            rejected = info_after.get("rejected_connections", 0)
            maxclients_after = info_after.get("maxclients", "?")
            logger.info(
                f"After (attempt {attempt}/3): connected_clients={connected_after}, "
                f"rejected_connections={rejected}, maxclients={maxclients_after}"
            )
            break
        except Exception as e:
            logger.warning(f"After INFO attempt {attempt}/3 failed: {e}")
            if info_client is not None:
                try:
                    info_client.close()
                except Exception:
                    pass
                info_client = None
            if attempt < 3:
                time.sleep(5)
    if info_client is not None:
        try:
            info_client.close()
        except Exception as e:
            logger.warning(f"info_client close error: {e}")

    logger.info(
        f"Connection exhaustion complete: opened={total_opened}, "
        f"churn={total_churn}, errors={total_errors}"
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "stress_type": stress_type,
            "threads": threads,
            "batch_size": batch_size,
            "target_total": target_total,
            "rapid_churn": rapid_churn,
            "total_connections_opened": total_opened,
            "total_churn_opened": total_churn,
            "total_errors": total_errors,
            "connected_before": connected_before,
            "connected_after": connected_after,
            "rejected_connections": rejected,
            "maxclients_before": maxclients_before,
            "maxclients_after": maxclients_after,
            "elapsed_seconds": duration,
        }),
    }
