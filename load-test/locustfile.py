import os
from locust import HttpUser, task,  between, constant, events
from uuid import uuid4 as u4
from random import choice
import json

X_REQUEST_ID = None

class WebsiteUser(HttpUser):
    wait_time = constant(0)
    def on_start(self):
        global api_key
        with open(".secrets.env", "r") as f:
            api_key = f.read().strip()
    
    @task(4)
    def payments(self):
        global X_REQUEST_ID
        payload = json.dumps({
    "amount": 6540,
    "currency": "USD",
    "confirm": True,
    "capture_method": "automatic",
    "capture_on": "2022-09-10T10:11:12Z",
    "amount_to_capture": 6540,
    "customer_id": "StripeCustomer",
    "email": "guest@example.com",
    "name": "John Doe",
    "phone": "999999999",
    "phone_country_code": "+65",
    "description": "Its my first payment request",
    "authentication_type": "no_three_ds",
    "return_url": "https://duck.com",
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
    "statement_descriptor_suffix": "JS",
    "metadata": {
        "udf1": "value1",
        "new_customer": "True",
        "login_date": "2019-09-10T10:11:12Z"
    },
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
    }
})
        response = self.client.post('/payments', data=payload,
                         headers={
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                            'api-key' : api_key 
                            })
        if response.status_code == 200:
            status = json.loads(response.text)["status"]
            if status == "succeeded" and X_REQUEST_ID != None :
                X_REQUEST_ID = response.headers.get("x-request-id")
        else:
            error_message = response.json().get("error", "Unknown error") 
            print(error_message)  
    
@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    global X_REQUEST_ID
    with open(".secrets.env", "w") as f:
        f.write(X_REQUEST_ID)