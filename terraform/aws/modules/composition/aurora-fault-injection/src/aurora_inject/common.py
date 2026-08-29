import json
import os
import base64
import logging
import boto3
import psycopg2
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_secret_client = boto3.client("secretsmanager")
_kms_client = boto3.client("kms")
_secret_cache = None

CRASH_FAULT_TYPES = {"crash_instance", "crash_dispatcher", "crash_node"}


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


def get_connection(secret):
    kms_key_arn = os.environ["KMS_KEY_ARN"]
    encrypted_password = secret["password"]

    password = decrypt_password(encrypted_password, kms_key_arn)

    try:
        conn = psycopg2.connect(
            host=secret.get("host", os.environ.get("DB_HOST")),
            port=int(secret.get("port", os.environ.get("DB_PORT", 5432))),
            dbname=secret.get("dbname", os.environ.get("DB_NAME")),
            user=secret.get("username", os.environ.get("DB_USER")),
            password=password,
            connect_timeout=10,
        )
        conn.autocommit = True
        return conn
    except psycopg2.OperationalError as e:
        logger.error(f"DB connection failed: {e}")
        raise
    finally:
        password = None


def execute_injection(query, params=None):
    secret_arn = os.environ["SECRET_ARN"]
    fault_type = os.environ.get("FAULT_TYPE", "unknown")

    logger.info(f"Executing fault injection: {fault_type}")
    logger.info(f"Query: {query}")

    secret = get_secret(secret_arn)
    conn = get_connection(secret)

    try:
        cursor = conn.cursor()
        try:
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            result = cursor.fetchone()
            cursor.close()
            logger.info(f"Injection completed. Result: {result}")
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "fault_type": fault_type,
                    "query": query,
                    "result": str(result) if result else "executed",
                }),
            }
        except psycopg2.OperationalError as e:
            if fault_type in CRASH_FAULT_TYPES:
                logger.info(f"Expected connection drop for {fault_type}: {e}")
                return {
                    "statusCode": 200,
                    "body": json.dumps({
                        "fault_type": fault_type,
                        "query": query,
                        "result": "crash_injected",
                        "note": "connection dropped as expected — instance crashed",
                    }),
                }
            raise
    except Exception as e:
        logger.error(f"Injection failed: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "fault_type": fault_type,
                "error": str(e),
            }),
        }
    finally:
        try:
            conn.close()
        except Exception:
            pass
