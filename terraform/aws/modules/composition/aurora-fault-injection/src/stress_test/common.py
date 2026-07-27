import json
import os
import base64
import logging
import time
import random
import boto3
import psycopg2
from botocore.exceptions import ClientError
from concurrent.futures import ThreadPoolExecutor, as_completed

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_secret_client = boto3.client("secretsmanager")
_kms_client = boto3.client("kms")
_secret_cache = None


def get_secret(secret_arn):
    global _secret_cache
    if _secret_cache:
        return _secret_cache
    try:
        response = _secret_client.get_secret_value(SecretId=secret_arn)
        _secret_cache = json.loads(response["SecretString"])
        return _secret_cache
    except ClientError as e:
        raise Exception(f"Failed to retrieve secret: {e}") from e


def decrypt_password(encrypted_b64, kms_key_arn):
    try:
        response = _kms_client.decrypt(
            CiphertextBlob=base64.b64decode(encrypted_b64),
            KeyId=kms_key_arn,
        )
        return response["Plaintext"].decode("utf-8")
    except ClientError as e:
        raise Exception(f"KMS decrypt failed: {e}") from e


def get_conn_params():
    secret_arn = os.environ["SECRET_ARN"]
    kms_key_arn = os.environ["KMS_KEY_ARN"]
    secret = get_secret(secret_arn)
    password = decrypt_password(secret["password"], kms_key_arn)
    params = {
        "host": os.environ.get("DB_HOST", secret.get("host")),
        "port": int(os.environ.get("DB_PORT") or secret.get("port") or 5432),
        "dbname": os.environ.get("DB_NAME", secret.get("dbname")),
        "user": os.environ.get("DB_USER", secret.get("username")),
        "password": password,
    }
    password = None
    return params


def ensure_pgbench_schema(conn_params, scale=10):
    conn = psycopg2.connect(**conn_params)
    conn.autocommit = True
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT 1 FROM pgbench_accounts LIMIT 1")
        cursor.fetchone()
        logger.info("pgbench schema already exists")
        cursor.close()
        conn.close()
        return True
    except psycopg2.Error:
        logger.info(f"Creating pgbench schema with scale factor {scale} via SQL...")
        cursor.close()
        conn.close()
        try:
            _create_pgbench_tables(conn_params, scale)
            logger.info("pgbench schema created")
            return True
        except Exception as e:
            logger.warning(f"pgbench schema creation failed: {e}")
            return False


def _create_pgbench_tables(conn_params, scale):
    conn = psycopg2.connect(**conn_params)
    conn.autocommit = True
    cursor = conn.cursor()

    tellers = scale * 10
    branches = scale
    accounts = scale * 100000

    cursor.execute("DROP TABLE IF EXISTS pgbench_history")
    cursor.execute("DROP TABLE IF EXISTS pgbench_tellers")
    cursor.execute("DROP TABLE IF EXISTS pgbench_accounts")
    cursor.execute("DROP TABLE IF EXISTS pgbench_branches")

    cursor.execute("""
        CREATE TABLE pgbench_branches (
            bid integer PRIMARY KEY,
            bbalance integer,
            filler char(88)
        )
    """)
    cursor.execute("""
        CREATE TABLE pgbench_tellers (
            tid integer PRIMARY KEY,
            bid integer,
            tbalance integer,
            filler char(84)
        )
    """)
    cursor.execute("""
        CREATE TABLE pgbench_accounts (
            aid bigint PRIMARY KEY,
            bid integer,
            abalance integer,
            filler char(84)
        )
    """)
    cursor.execute("""
        CREATE TABLE pgbench_history (
            tid integer,
            bid integer,
            aid bigint,
            delta integer,
            mtime timestamp
        )
    """)

    cursor.execute(
        "INSERT INTO pgbench_branches (bid, bbalance, filler) "
        "SELECT i, 0, repeat(' ', 88) FROM generate_series(1, %s) AS i",
        (branches,)
    )
    cursor.execute(
        "INSERT INTO pgbench_tellers (tid, bid, tbalance, filler) "
        "SELECT i, ((i - 1) / 10) + 1, 0, repeat(' ', 84) FROM generate_series(1, %s) AS i",
        (tellers,)
    )
    cursor.execute(
        "INSERT INTO pgbench_accounts (aid, bid, abalance, filler) "
        "SELECT i, ((i - 1) / 100000) + 1, 0, repeat(' ', 84) FROM generate_series(1, %s) AS i",
        (accounts,)
    )

    cursor.execute("CREATE INDEX IF NOT EXISTS pgbench_accounts_bid_idx ON pgbench_accounts(bid)")
    cursor.execute("CREATE INDEX IF NOT EXISTS pgbench_tellers_bid_idx ON pgbench_tellers(bid)")
    cursor.execute("ANALYZE pgbench_branches")
    cursor.execute("ANALYZE pgbench_tellers")
    cursor.execute("ANALYZE pgbench_accounts")

    cursor.close()
    conn.close()


def run_stress_with_workers(conn_params, worker_fn, num_clients, num_threads, duration):
    start_time = time.time()
    end_time = start_time + duration
    total_transactions = 0
    errors = []

    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = []
        for _ in range(num_clients):
            futures.append(executor.submit(worker_fn, conn_params, end_time))

        for future in as_completed(futures):
            try:
                result = future.result()
                total_transactions += result
            except Exception as e:
                errors.append(str(e))

    elapsed = time.time() - start_time
    tps = total_transactions / elapsed if elapsed > 0 else 0

    return {
        "total_transactions": total_transactions,
        "elapsed_seconds": round(elapsed, 2),
        "tps": round(tps, 2),
        "errors": errors[:10],
        "error_count": len(errors),
    }
