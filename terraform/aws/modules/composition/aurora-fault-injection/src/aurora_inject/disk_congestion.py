from common import execute_injection


def lambda_handler(event, context):
    return execute_injection(
        "SELECT aurora_inject_disk_congestion(100, 0, true, 60, 30.0, 100.0);"
    )
