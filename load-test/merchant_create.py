import os
import json
import time
import uuid
import requests
from dotenv import load_dotenv

load_dotenv()

HYPERSWITCH_HOST_URL = os.getenv("HYPERSWITCH_HOST_URL")
ADMIN_API_KEY = os.getenv("ADMIN_API_KEY")

BASE_HEADERS = {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "x-Tenant-ID": "public",
}

MAX_RETRIES = 5
RETRY_BACKOFF = 5
REQUEST_TIMEOUT = 45

def retry_request(method, url, **kwargs):
    kwargs.setdefault("timeout", REQUEST_TIMEOUT)
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = method(url, **kwargs)
            response.raise_for_status()
            return response
        except requests.exceptions.HTTPError as e:
            if response.status_code in (502, 503, 504) and attempt < MAX_RETRIES:
                wait = RETRY_BACKOFF * attempt
                print(f"  ⚠ {e} — retrying in {wait}s (attempt {attempt}/{MAX_RETRIES})...")
                time.sleep(wait)
                continue
            try:
                detail = response.json()
                print(f"  ❌ {response.status_code} {response.reason}: {json.dumps(detail)}")
            except Exception:
                print(f"  ❌ {response.status_code} {response.reason}: {response.text[:500]}")
            raise
        except requests.exceptions.ConnectionError as e:
            if attempt < MAX_RETRIES:
                wait = RETRY_BACKOFF * attempt
                print(f"  ⚠ Connection error — retrying in {wait}s (attempt {attempt}/{MAX_RETRIES})...")
                time.sleep(wait)
                continue
            raise

def merchant_account_create():
    uid = uuid.uuid4().hex[:8]
    payload = {
        "merchant_id": f"merchant_{int(time.time())}_{uid}",
        "locker_id": f"m{uid[:4]}",
        "merchant_name": f"LoadTest_{uid}",
        "merchant_details": {
            "primary_contact_person": f"John Test {uid}",
            "primary_email": f"JohnTest_{uid}@test.com",
            "primary_phone": "sunt laborum",
            "secondary_contact_person": f"John Test2 {uid}",
            "secondary_email": f"JohnTest2_{uid}@test.com",
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
        "metadata": {"city": "NY", "unit": "245"},
        "primary_business_details": [{"country": "US", "business": "default"}]
    }
    headers = {**BASE_HEADERS, "api-key": ADMIN_API_KEY}
    response = retry_request(requests.post, f"{HYPERSWITCH_HOST_URL}/accounts", json=payload, headers=headers)
    return response.json().get("merchant_id")

def api_key_create(m_id):
    payload = {
        "name": "API Key 1",
        "description": None,
        "expiration": "2038-01-19T03:14:08.000Z"
    }
    headers = {**BASE_HEADERS, "api-key": ADMIN_API_KEY}
    response = retry_request(requests.post, f"{HYPERSWITCH_HOST_URL}/api_keys/{m_id}", json=payload, headers=headers)
    return response.json().get("api_key")

def get_api_key_from_env():
    return "test_key"

def connector_create(merchant_id, api_key):
    api_key_from_env = get_api_key_from_env()
    payload = {
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
    }
    headers = {**BASE_HEADERS, "api-key": api_key}
    retry_request(requests.post, f"{HYPERSWITCH_HOST_URL}/account/{merchant_id}/connectors", json=payload, headers=headers)

def main():
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
            connector_create(merchant_id, api_key)
            print("Merchant Account created successfully!")
        else:
            print("Failed to create API Key.")
    else:
        print("Failed to create Merchant Account.")

if __name__ == "__main__":
    main()