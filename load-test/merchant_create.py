import os
import json
import time
import subprocess
from dotenv import load_dotenv

load_dotenv()

HYPERSWITCH_HOST_URL = os.getenv("HYPERSWITCH_HOST_URL")
ADMIN_API_KEY = os.getenv("ADMIN_API_KEY")

def run_curl(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        return json.loads(result.stdout)
    else:
        raise RuntimeError(f"\033[91mError: {result.stderr}\033[0m")

def merchant_account_create():
    payload = json.dumps({
        "merchant_id": f"merchant_{int(time.time())}",
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
        "webhook_details": {
            "webhook_version": "1.0.1",
            "webhook_username": "ekart_retail",
            "webhook_password": "password_ekart@123",
            "webhook_url": "https://webhook.site",
            "payment_created_enabled": True,
            "payment_succeeded_enabled": True,
            "payment_failed_enabled": True
        },
        "sub_merchants_enabled": False,
        "parent_merchant_id": "merchant_123",
        "metadata": {"city": "NY", "unit": "245"},
        "primary_business_details": [{"country": "US", "business": "default"}]
    })
    command = f"curl --silent --show-error --fail --request POST {HYPERSWITCH_HOST_URL}/accounts --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'api-key: {ADMIN_API_KEY}' --data '{payload}'"
    response = run_curl(command)
    return response["merchant_id"] if response else None

def api_key_create(m_id):
    payload = json.dumps({
        "name": "API Key 1",
        "description": None,
        "expiration": "2038-01-19T03:14:08.000Z"
    })
    command = f"curl --silent --show-error --fail --request POST {HYPERSWITCH_HOST_URL}/api_keys/{m_id} --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'api-key: {ADMIN_API_KEY}' --data '{payload}'"
    response = run_curl(command)
    return response["api_key"] if response else None

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
    command = f"curl --silent --show-error --fail --request POST {HYPERSWITCH_HOST_URL}/account/{merchant_id}/connectors --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'api-key: {ADMIN_API_KEY}' --data '{payload}'"
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
