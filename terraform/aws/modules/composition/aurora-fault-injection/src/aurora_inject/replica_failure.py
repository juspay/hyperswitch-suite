from common import execute_injection


def lambda_handler(event, context):
    return execute_injection(
        "SELECT aurora_inject_replica_failure(100, 30);"
    )
