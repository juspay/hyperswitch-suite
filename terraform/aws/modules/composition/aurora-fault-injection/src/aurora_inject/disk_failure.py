from common import execute_injection


def lambda_handler(event, context):
    return execute_injection(
        "SELECT aurora_inject_disk_failure(50, 0, false, 20);"
    )
