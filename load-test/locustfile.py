from locust import HttpUser, task, constant, SequentialTaskSet
import json
import numpy as np
import os

# Global list to store x-hs-latency values
x_hs_latency_values = []

# Global variables for sample logs
sample_logs_captured = {"create": False, "confirm": False}
sample_logs = {}
sample_payment_id = None  # Track the payment_id for consistent logging
CAPTURE_LOGS = os.getenv("CAPTURE_SAMPLE_LOGS", "false").lower() == "true"

class APICalls(SequentialTaskSet):
    payment_id = ""
    @task
    def payment_create(self):
        payload = json.dumps({
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
        })
        response = self.client.post('/payments', data=payload,
                        headers={
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                            'api-key' : api_key
                        })
        if response.status_code == 200:
            self.payment_id = json.loads(response.text)["payment_id"]

            # Capture sample log for successful payment create
            if CAPTURE_LOGS and not sample_logs_captured["create"]:
                global sample_payment_id
                sample_payment_id = self.payment_id  # Store the payment_id for matching
                sample_logs["payment_create"] = {
                    "api": "payment_create",
                    "status_code": response.status_code,
                    "headers": dict(response.headers),
                    "request_payload": json.loads(payload),
                    "response": response.json()
                }
                sample_logs_captured["create"] = True
                print(f"✅ Sample log captured for payment_create (ID: {self.payment_id})")
        else:
            error_message = response.json().get("error", "Unknown error")
            print(error_message)

    @task
    def payment_confirm(self):
        global sample_payment_id
        payload = json.dumps({
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
        })

        response = self.client.post('/payments/'+self.payment_id+'/confirm', name='/payments/payment_id/confirm', data=payload,
                        headers={
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                            'api-key' : api_key,
                            'x-hs-latency' : 'true'
                        })
        x_hs_latency = response.headers.get('x-hs-latency')
        print(x_hs_latency)

        # Store x-hs-latency value if present
        if x_hs_latency:
            try:
                latency_value = float(x_hs_latency)
                x_hs_latency_values.append(latency_value)
            except ValueError:
                pass  # Skip invalid latency values

        if response.status_code == 200:
            status = json.loads(response.text)["status"]
            print("Payment status: ", status)

            # Capture sample log for successful payment confirm only for the same payment_id
            if CAPTURE_LOGS and sample_logs_captured["create"] and not sample_logs_captured["confirm"] and self.payment_id == sample_payment_id:
                sample_logs["payment_confirm"] = {
                    "api": "payment_confirm",
                    "status_code": response.status_code,
                    "headers": dict(response.headers),
                    "request_payload": json.loads(payload),
                    "response": response.json()
                }
                sample_logs_captured["confirm"] = True
                print(f"✅ Sample log captured for payment_confirm (ID: {self.payment_id}) - Complete transaction logged!")
        else:
            error_message = response.json().get("error", "Unknown error")
            print(error_message)

            # If confirm fails for the tracked payment, reset and try next transaction
            if CAPTURE_LOGS and sample_logs_captured["create"] and self.payment_id == sample_payment_id:
                sample_logs.clear()
                sample_logs_captured["create"] = False
                sample_payment_id = None
                print(f"❌ Payment confirm failed for {self.payment_id}, resetting sample logs to try next transaction")


def calculate_and_save_p99():
    """Calculate p99 of x-hs-latency values and save to temporary file"""
    if x_hs_latency_values:
        p99 = np.percentile(x_hs_latency_values, 99)
        with open(".p99_latency.txt", "w") as f:
            f.write(str(p99))
        print(f"P99 x-hs-latency: {p99}")
    else:
        with open(".p99_latency.txt", "w") as f:
            f.write("N/A")
        print("No x-hs-latency values collected")

def save_sample_logs():
    """Save sample logs to a single file if captured"""
    if CAPTURE_LOGS and sample_logs:
        # Create output directory if it doesn't exist
        os.makedirs("output", exist_ok=True)
        with open("output/sample_logs.json", "w") as f:
            json.dump(sample_logs, f, indent=2)
        print(f"✅ Sample logs saved: output/sample_logs.json ({len(sample_logs)} APIs)")

class TestUser(HttpUser):
    wait_time = constant(0)
    tasks = [APICalls]
    def on_start(self):
        global api_key
        with open(".secrets.env", "r") as f:
            api_key = f.read().strip()

    def on_stop(self):
        """Called when the user stops"""
        calculate_and_save_p99()
        save_sample_logs()

