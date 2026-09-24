import json
import logging
from common import get_conn_params
import psycopg2

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    conn_params = get_conn_params()
    conn = psycopg2.connect(**conn_params)
    conn.autocommit = True
    cursor = conn.cursor()

    dropped = []

    tables = [
        "pgbench_history",
        "pgbench_tellers",
        "pgbench_accounts",
        "pgbench_branches",
    ]

    for table in tables:
        try:
            cursor.execute(f"SELECT count(*) FROM {table}")
            count = cursor.fetchone()[0]
            cursor.execute(f"DROP TABLE IF EXISTS {table} CASCADE")
            dropped.append(f"{table} ({count} rows)")
            logger.info(f"Dropped {table} with {count} rows")
        except psycopg2.Error:
            logger.info(f"{table} does not exist, skipping")

    cursor.close()
    conn.close()

    logger.info(f"Cleanup complete: {len(dropped)} tables dropped")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "action": "cleanup",
            "dropped_tables": dropped,
            "message": "pgbench schema removed — DB is clean",
        }),
    }
