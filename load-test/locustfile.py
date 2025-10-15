from locust import HttpUser, task, constant, SequentialTaskSet
import json
import numpy as np
import os

# Global list to store x-hs-latency values
x_hs_latency_values = []

# Global variables to store payment IDs for sample log generation
sample_payment_id = None
sample_log_captured = False

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
        else:
            error_message = response.json().get("error", "Unknown error")
            print(error_message)

    @task
    def payment_confirm(self):
        global sample_payment_id, sample_log_captured

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

        # Capture payment_id for sample log generation if enabled and not already captured
        if (os.getenv('GEN_SAMPLE_LOG', 'false').lower() == 'true' and
            not sample_log_captured and response.status_code == 200):
            try:
                response_data = json.loads(response.text)
                if response_data.get("status") == "succeeded":
                    payment_id = response_data.get("payment_id")
                    if payment_id:
                        sample_payment_id = payment_id
                        sample_log_captured = True
                        print(f"Sample payment ID captured: {payment_id}")
            except (json.JSONDecodeError, KeyError):
                pass

        if response.status_code == 200:
            status = json.loads(response.text)["status"]
            print("Payment status: ", status)
        else:
            error_message = response.json().get("error", "Unknown error")
            print(error_message)


def save_load_test_results():
    """Save P99 latency and sample request ID to JSON file"""
    import os

    # Ensure output/temp directory exists
    os.makedirs("output/temp", exist_ok=True)

    # Calculate P99 latency
    p99_latency = "N/A"
    if x_hs_latency_values:
        p99_latency = float(np.percentile(x_hs_latency_values, 99))
        print(f"P99 x-hs-latency: {p99_latency}")
    else:
        print("No x-hs-latency values collected")

    # Prepare data
    results = {
        "p99_latency": p99_latency,
        "sample_payment_id": sample_payment_id if sample_payment_id else "N/A"
    }

    # Save to JSON file
    with open("output/temp/load_test.json", "w") as f:
        json.dump(results, f, indent=2)

    print(f"Load test results saved to output/temp/load_test.json")
    if sample_payment_id:
        print(f"Sample payment ID: {sample_payment_id}")

class TestUser(HttpUser):
    wait_time = constant(0)
    tasks = [APICalls]
    def on_start(self):
        global api_key
        with open(".secrets.env", "r") as f:
            api_key = f.read().strip()

    def on_stop(self):
        """Called when the user stops"""
        save_load_test_results()

