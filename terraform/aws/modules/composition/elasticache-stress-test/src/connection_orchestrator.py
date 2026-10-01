import os
import json
import time
import logging
import math
import boto3

from common import get_redis_client

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _safe_close(client):
    try:
        client.close()
    except Exception:
        pass


def _info_with_retry(attempts=3, backoff_seconds=5):
    last_error = None
    for attempt in range(1, attempts + 1):
        client = None
        try:
            client = get_redis_client()
            client.ping()
            info = client.info()
            connected = info.get("connected_clients", "?")
            maxclients = info.get("maxclients", "?")
            rejected = info.get("rejected_connections", 0)
            logger.info(f"INFO attempt {attempt}/{attempts}: connected={connected}, maxclients={maxclients}, rejected={rejected}")
            return connected, maxclients, rejected
        except Exception as e:
            last_error = e
            logger.warning(f"INFO attempt {attempt}/{attempts} failed: {e}")
            if attempt < attempts:
                time.sleep(backoff_seconds)
        finally:
            if client is not None:
                _safe_close(client)
    logger.error(f"INFO failed after {attempts} attempts: {last_error}")
    return "?", "?", 0


def lambda_handler(event, context):
    worker_function_name = os.environ.get("WORKER_FUNCTION_NAME", "")
    worker_region = os.environ.get("WORKER_REGION", os.environ.get("AWS_REGION", "us-east-1"))

    worker_count = int(event.get("worker_count", os.environ.get("ORCHESTRATOR_WORKER_COUNT", "84")))
    desired_total = int(event.get("desired_total", os.environ.get("ORCHESTRATOR_DESIRED_TOTAL", "70000")))
    max_per_worker = int(event.get("max_per_worker", os.environ.get("ORCHESTRATOR_MAX_PER_WORKER", "850")))
    duration = int(event.get("duration", os.environ.get("ORCHESTRATOR_DURATION", "600")))
    worker_threads = int(event.get("worker_threads", os.environ.get("ORCHESTRATOR_WORKER_THREADS", "16")))
    worker_batch_size = int(event.get("worker_batch_size", os.environ.get("ORCHESTRATOR_WORKER_BATCH_SIZE", "10")))

    worker_target_total = int(event.get("worker_target_total", math.ceil(desired_total / worker_count)))
    if worker_target_total > max_per_worker:
        capped = worker_target_total
        worker_target_total = max_per_worker
        effective_total = worker_target_total * worker_count
        logger.warning(
            f"Per-worker target {capped} exceeds safe fd limit {max_per_worker}; "
            f"capping to {max_per_worker}. Effective plateau = {effective_total}"
        )

    effective_total = worker_target_total * worker_count
    logger.info(
        f"Connection orchestrator: workers={worker_count}, desired_total={desired_total}, "
        f"worker_target_total={worker_target_total}, max_per_worker={max_per_worker}, "
        f"effective_total={effective_total}, duration={duration}s"
    )

    lambda_client = boto3.client("lambda", region_name=worker_region)

    connected_before, maxclients, _ = _info_with_retry()
    logger.info(f"Before: connected_clients={connected_before}, maxclients={maxclients}")

    payload = json.dumps({
        "target_total": worker_target_total,
        "threads": worker_threads,
        "batch_size": worker_batch_size,
        "duration": duration,
        "rapid_churn": False,
    })

    invocation_results = []
    for i in range(worker_count):
        try:
            resp = lambda_client.invoke(
                FunctionName=worker_function_name,
                InvocationType="Event",
                Payload=payload,
            )
            invocation_results.append({"worker": i + 1, "status_code": resp.get("StatusCode")})
            if (i + 1) % 10 == 0 or i + 1 == worker_count:
                logger.info(f"Invoked {i + 1}/{worker_count} workers")
        except Exception as e:
            logger.error(f"Failed to invoke worker {i + 1}: {e}")
            invocation_results.append({"worker": i + 1, "error": str(e)})

    sleep_seconds = duration + 60
    logger.info(f"Waiting {sleep_seconds}s for workers to hold connections")
    time.sleep(sleep_seconds)

    connected_after, _, rejected = _info_with_retry(attempts=5, backoff_seconds=10)
    logger.info(f"After: connected_clients={connected_after}, rejected_connections={rejected}")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "orchestrator": True,
            "worker_count": worker_count,
            "desired_total": desired_total,
            "worker_target_total": worker_target_total,
            "effective_total": effective_total,
            "max_per_worker": max_per_worker,
            "worker_function_name": worker_function_name,
            "maxclients": maxclients,
            "connected_before": connected_before,
            "connected_after": connected_after,
            "rejected_connections": rejected,
            "invocations": invocation_results,
        }),
    }
