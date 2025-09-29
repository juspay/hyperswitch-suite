from locust import HttpUser, task, constant, SequentialTaskSet
import json
import os
import sys
import logging
from pathlib import Path

# Check if debug mode is enabled
DEBUG_MODE = os.getenv("DEBUG_MODE", "false").lower() == "true"

# Get testing mode from environment variable
TESTING_MODE = os.getenv("TESTING_MODE", "basic").lower()

# Define testing modes and their API call sequences
TESTING_MODES = {
    "basic": ["payment_create", "payment_confirm"],
    "advanced": ["payment_create", "payment_confirm", "payment_retrieve"],
    "comprehensive": ["payment_create", "payment_confirm", "payment_retrieve", "payment_update", "payment_capture"]
}

def setup_logging():
    """Setup logging for locustfile.py"""
    if DEBUG_MODE:
        log_file = Path("output/debug_logs/load_test_debug.log")
        log_file.parent.mkdir(parents=True, exist_ok=True)
        logging.basicConfig(
            level=logging.DEBUG,
            format='%(asctime)s - LOCUST - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file, mode='a'),
            ]
        )
        logging.info("=== Locust Debug Session Started ===")

def debug_log(message, *args):
    """Log debug message if debug mode is enabled."""
    if DEBUG_MODE:
        logging.debug(message, *args)

def log_request(method, url, payload=None, response=None, status_code=None, user_id=None):
    """Log request details in debug mode."""
    if DEBUG_MODE:
        user_prefix = f"[User {user_id}] " if user_id else ""
        logging.info("%s%s %s - Status: %s", user_prefix, method, url, status_code)
        if payload:
            logging.debug("%sRequest Payload: %s", user_prefix, json.dumps(payload, indent=2))
        if response:
            try:
                response_json = json.loads(response) if isinstance(response, str) else response
                logging.debug("%sResponse Body: %s", user_prefix, json.dumps(response_json, indent=2))
            except:
                logging.debug("%sResponse Body: %s", user_prefix, str(response))

setup_logging()

class APICalls(SequentialTaskSet):
    payment_id = ""

    def on_start(self):
        """Initialize the task sequence based on testing mode."""
        self.task_sequence = TESTING_MODES.get(TESTING_MODE, TESTING_MODES["basic"])
        self.current_task_index = 0
        user_id = getattr(self.user, 'user_id', 'unknown')
        debug_log("User %s initialized with testing mode: %s, task sequence: %s", user_id, TESTING_MODE, self.task_sequence)

    @task
    def execute_next_task(self):
        """Execute the next task in the sequence based on testing mode."""
        if self.current_task_index < len(self.task_sequence):
            task_name = self.task_sequence[self.current_task_index]
            user_id = getattr(self.user, 'user_id', 'unknown')
            debug_log("User %s executing task %d: %s", user_id, self.current_task_index + 1, task_name)

            # Execute the appropriate method
            method = getattr(self, task_name, None)
            if method:
                method()
                self.current_task_index += 1
            else:
                debug_log("User %s: Task method %s not found", user_id, task_name)
        else:
            # Reset to start sequence again
            self.current_task_index = 0

    def payment_create(self):
        user_id = getattr(self.user, 'user_id', 'unknown')
        debug_log("User %s starting payment_create task", user_id)

        payload_dict = {
            "amount": 6540,
            "currency": "USD",
            "confirm": False,
            "capture_method": "automatic",
            "capture_on": "2022-09-10T10:11:12Z",
            "amount_to_capture": 6540,
            "setup_future_usage": "on_session",
            "customer_id": "DummyCustomer",
            "email": "guest@example.com",
            "name": "John Doe",
            "phone": "999999999",
            "phone_country_code": "+65",
            "description": "Its my first payment request",
            "authentication_type": "no_three_ds",
            "return_url": "https://hyperswitch.io/",
            "billing": {
                "address": {
                    "line1": "1467",
                    "line2": "Harrison Street",
                    "line3": "Harrison Street",
                    "city": "San Fransico",
                    "state": "California",
                    "zip": "94122",
                    "country": "US",
                    "first_name": "PiX",
                    "last_name": "Pix"
                }
            },
            "shipping": {
                "address": {
                    "line1": "1467",
                    "line2": "Harrison Street",
                    "line3": "Harrison Street",
                    "city": "San Fransico",
                    "state": "California",
                    "zip": "94122",
                    "country": "US",
                    "first_name": "PiX"
                }
            },
            "statement_descriptor_name": "joseph",
            "statement_descriptor_suffix": "JS"
        }

        payload = json.dumps(payload_dict)
        headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'api-key': api_key
        }

        debug_log("User %s making payment_create request", user_id)
        response = self.client.post('/payments', data=payload, headers=headers)

        log_request("POST", "/payments", payload_dict, response.text, response.status_code, user_id)

        if response.status_code == 200:
            self.payment_id = json.loads(response.text)["payment_id"]
            debug_log("User %s payment created successfully. Payment ID: %s", user_id, self.payment_id)
        else:
            error_message = response.json().get("error", "Unknown error")
            debug_log("User %s payment creation failed: %s", user_id, error_message)
            print(error_message)

    def payment_confirm(self):
        user_id = getattr(self.user, 'user_id', 'unknown')
        debug_log("User %s starting payment_confirm task with payment_id: %s", user_id, self.payment_id)

        payload_dict = {
            "payment_method": "card",
            "payment_method_type": "credit",
            "payment_method_data": {
                "card": {
                    "card_number": "4242424242424242",
                    "card_exp_month": "10",
                    "card_exp_year": "25",
                    "card_holder_name": "joseph Doe",
                    "card_cvc": "123"
                }
            },
            "customer_acceptance": {
            "acceptance_type": "online",
            "accepted_at": "1963-05-03T04:07:52.723Z",
            "online": {
                "ip_address": "127.0.0.1",
                "user_agent": "amet irure esse"
                }
            },
        }

        payload = json.dumps(payload_dict)
        headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'api-key': api_key,
            'x-hs-latency': 'True'
        }

        url = f'/payments/{self.payment_id}/confirm'
        debug_log("User %s making payment_confirm request to %s", user_id, url)

        response = self.client.post(url, name='/payments/payment_id/confirm', data=payload, headers=headers)

        log_request("POST", url, payload_dict, response.text, response.status_code, user_id)

        latency = response.headers.get('x-hs-latency')
        if latency:
            debug_log("User %s received latency header: %s", user_id, latency)
            print(latency)

        if response.status_code == 200:
            status = json.loads(response.text)["status"]
            debug_log("User %s payment confirmed successfully. Status: %s", user_id, status)
            print("Payment status: ", status)
        else:
            error_message = response.json().get("error", "Unknown error")
            debug_log("User %s payment confirmation failed: %s", user_id, error_message)
            print(error_message)


class TestUser(HttpUser):
    wait_time = constant(0)
    tasks = [APICalls]

    def on_start(self):
        global api_key
        # Assign a unique user ID for debugging
        self.user_id = id(self)
        debug_log("User %s starting session", self.user_id)

        try:
            with open(".secrets.env", "r") as f:
                api_key = f.read().strip()
            debug_log("User %s loaded API key: %s", self.user_id, api_key[:10] + "..." if len(api_key) > 10 else api_key)
        except Exception as e:
            debug_log("User %s failed to load API key: %s", self.user_id, str(e))
            raise

