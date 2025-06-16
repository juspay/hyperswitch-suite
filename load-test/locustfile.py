from locust import HttpUser, task, constant, SequentialTaskSet
import json

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
                            'x-hs-latency' : 'True'
                        })
        print(response.headers.get('x-hs-latency'))
        if response.status_code == 200:
            status = json.loads(response.text)["status"]
            print("Payment status: ", status)
        else:
            error_message = response.json().get("error", "Unknown error")
            print(error_message)


class TestUser(HttpUser):
    wait_time = constant(0)
    tasks = [APICalls]
    def on_start(self):
        global api_key
        with open(".secrets.env", "r") as f:
            api_key = f.read().strip()

