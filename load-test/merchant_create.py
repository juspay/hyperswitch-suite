import os
import json
import time
import subprocess
import sys
import logging
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

# Check if debug mode is enabled
DEBUG_MODE = os.getenv("DEBUG_MODE", "false").lower() == "true"

def setup_logging():
    """Setup logging for merchant_create.py"""
    if DEBUG_MODE:
        log_file = Path("output/debug_logs/load_test_debug.log")
        log_file.parent.mkdir(parents=True, exist_ok=True)
        logging.basicConfig(
            level=logging.DEBUG,
            format='%(asctime)s - MERCHANT_CREATE - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file, mode='a'),
            ]
        )
        logging.info("=== Merchant Create Debug Session Started ===")

def debug_log(message, *args):
    """Log debug message if debug mode is enabled."""
    if DEBUG_MODE:
        logging.debug(message, *args)

def log_api_call(method, url, payload=None, response=None, status_code=None):
    """Log API call details in debug mode."""
    if DEBUG_MODE:
        logging.info("API Call: %s %s", method, url)
        if payload:
            logging.debug("Request Payload: %s", json.dumps(payload, indent=2))
        if response and status_code:
            logging.info("Response Status: %s", status_code)
            logging.debug("Response Body: %s", response)

setup_logging()

HYPERSWITCH_HOST_URL = os.getenv("HYPERSWITCH_HOST_URL")
ADMIN_API_KEY = os.getenv("ADMIN_API_KEY")

def run_curl(command):
    debug_log("Executing curl command: %s", command)
    result = subprocess.run(command, shell=True, capture_output=True, text=True)

    if result.returncode == 0:
        response_data = json.loads(result.stdout)
        debug_log("Curl command successful. Response: %s", json.dumps(response_data, indent=2))
        return response_data
    else:
        error_msg = f"\033[91mError: {result.stderr}\033[0m"
        debug_log("Curl command failed: %s", result.stderr)
        raise RuntimeError(error_msg)

def get_webhook_details():
    if len(sys.argv) < 2:
        print("Error: webhook_url is required")
        sys.exit(1)

    webhook_url = sys.argv[1]
    webhook_username = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else None
    webhook_password = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else None

    webhook_details = {
        "webhook_version": "1.0.1",
        "webhook_url": webhook_url,
        "payment_created_enabled": True,
        "payment_succeeded_enabled": True,
        "payment_failed_enabled": True
    }

    if webhook_username:
        webhook_details["webhook_username"] = webhook_username
    if webhook_password:
        webhook_details["webhook_password"] = webhook_password

    return webhook_details

def merchant_account_create():
    debug_log("Starting merchant account creation")
    webhook_details = get_webhook_details()
    debug_log("Webhook details collected: %s", webhook_details)

    merchant_id = f"merchant_{int(time.time())}"
    payload_dict = {
        "merchant_id": merchant_id,
        "locker_id": "m0010",
        "merchant_name": "NewAge Retailer",
        "merchant_details": {
            "primary_contact_person": "John Test",
            "primary_email": "JohnTest@test.com",
            "primary_phone": "sunt laborum",
            "secondary_contact_person": "John Test2",
            "secondary_email": "JohnTest2@test.com",
            "secondary_phone": "cillum do dolor id",
            "website": "https://www.example.com",
            "about_business": "Online Retail with a wide selection of organic products for North America",
            "address": {
                "line1": "1467",
                "line2": "Harrison Street",
                "city": "San Francisco",
                "state": "California",
                "zip": "94122",
                "country": "US",
                "first_name": "john",
                "last_name": "Doe"
            }
        },
        "return_url": "https://google.com/success",
        "webhook_details": webhook_details,
        "sub_merchants_enabled": False,
        "parent_merchant_id": "merchant_123",
        "metadata": {"city": "NY", "unit": "245"},
        "primary_business_details": [{"country": "US", "business": "default"}]
    }

    payload = json.dumps(payload_dict)
    url = f"{HYPERSWITCH_HOST_URL}/accounts"

    log_api_call("POST", url, payload_dict)

    command = f"curl --silent --show-error --fail --request POST {url} --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'api-key: {ADMIN_API_KEY}' --data '{payload}'"

    try:
        response = run_curl(command)
        log_api_call("POST", url, response=response, status_code=200)
        debug_log("Merchant account created successfully with ID: %s", response.get("merchant_id"))
        return response["merchant_id"] if response else None
    except Exception as e:
        debug_log("Failed to create merchant account: %s", str(e))
        raise

def api_key_create(m_id):
    debug_log("Starting API key creation for merchant: %s", m_id)

    payload_dict = {
        "name": "API Key 1",
        "description": None,
        "expiration": "2038-01-19T03:14:08.000Z"
    }
    payload = json.dumps(payload_dict)
    url = f"{HYPERSWITCH_HOST_URL}/api_keys/{m_id}"

    log_api_call("POST", url, payload_dict)

    command = f"curl --silent --show-error --fail --request POST {url} --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'api-key: {ADMIN_API_KEY}' --data '{payload}'"

    try:
        response = run_curl(command)
        log_api_call("POST", url, response=response, status_code=200)
        debug_log("API key created successfully: %s", response.get("api_key", "N/A"))
        return response["api_key"] if response else None
    except Exception as e:
        debug_log("Failed to create API key: %s", str(e))
        raise

def get_api_key_from_env():
    return "test_key"

def connector_create(merchant_id):
    api_key_from_env = get_api_key_from_env()
    payload = json.dumps({
        "connector_type": "payment_processor",
        "connector_name": "stripe_test",
        "connector_account_details": {
            "auth_type": "HeaderKey",
            "api_key": api_key_from_env
        },
        "test_mode": True,
        "disabled": False,
        "payment_methods_enabled": [{
            "payment_method": "card",
            "payment_method_types": [{
                "payment_method_type": "credit",
                "card_networks": ["Visa", "Mastercard"],
                "minimum_amount": 1,
                "maximum_amount": 68607706,
                "recurring_enabled": True,
                "installment_payment_enabled": True,
                "accepted_countries": {"type": "disable_only", "list": ["HK"]},
                "accepted_currencies": {"type": "enable_only", "list": ["USD", "GBP", "INR"]}
            }]
        }],
        "metadata": {"city": "NY", "unit": "245"},
        "connector_webhook_details": {"merchant_secret": "MyWebhookSecret"},
        "business_country": "US",
        "business_label": "default"
    })
    command = f"curl --silent --show-error --fail --request POST {HYPERSWITCH_HOST_URL}/account/{merchant_id}/connectors --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'api-key: {api_key}' --data '{payload}'"
    run_curl(command)

def main():
    global merchant_id, api_key
    print("Creating Merchant Account...")
    merchant_id = merchant_account_create()
    if merchant_id:
        print(f"Merchant ID: {merchant_id}")
        api_key = api_key_create(merchant_id)
        if api_key:
            with open(".secrets.env", "w") as f:
                f.write(f"{api_key}\n")
            print("Merchant ID and API key saved!")
            print("Creating connector...")
            connector_create(merchant_id)
            print("Merchant Account created successfully!")
        else:
            print("Failed to create API Key.")
    else:
        print("Failed to create Merchant Account.")

if __name__ == "__main__":
    main()