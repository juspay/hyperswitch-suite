"""Mock Stripe connector for hyperswitch load testing.

This server mimics the subset of Stripe's API that hyperswitch's Stripe
connector exercises. Point hyperswitch's `stripe.base_url` config to this
service (e.g. http://stripe-mock:12111) to avoid real Stripe rate limits.
"""

import asyncio
import itertools
import os
import time
from contextlib import asynccontextmanager
from typing import Annotated, Any

from fastapi import FastAPI, Form, Request
from fastapi.responses import JSONResponse

DELAY_MS = float(os.environ.get("DELAY_MS", "3000"))


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.id_counter = itertools.count(start=1)
    yield


app = FastAPI(title="Mock Stripe Connector", lifespan=lifespan)


@app.middleware("http")
async def delay_middleware(request: Request, call_next):
    await asyncio.sleep(DELAY_MS / 1000)
    return await call_next(request)


def _next_id(prefix: str) -> str:
    return f"{prefix}_{next(app.state.id_counter):016x}"


def _now() -> int:
    return int(time.time())


def _currency(cur: str | None) -> str:
    return (cur or "usd").lower()


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/v1/customers")
def create_customer(
    email: Annotated[str | None, Form()] = None,
    name: Annotated[str | None, Form()] = None,
    phone: Annotated[str | None, Form()] = None,
    description: Annotated[str | None, Form()] = None,
):
    return {
        "id": _next_id("cus"),
        "object": "customer",
        "email": email,
        "name": name,
        "phone": phone,
        "description": description,
    }


@app.post("/v1/tokens")
def create_token():
    return {"id": _next_id("tok"), "object": "token"}


@app.post("/v1/payment_methods")
def create_payment_method():
    return {"id": _next_id("pm"), "object": "payment_method"}


def _payment_intent_response(
    id: str,
    amount: int,
    currency: str,
    status: str,
    amount_received: int | None,
) -> dict[str, Any]:
    return {
        "id": id,
        "object": "payment_intent",
        "amount": amount,
        "amount_received": amount_received,
        "amount_capturable": amount if amount_received is None else 0,
        "currency": currency.lower(),
        "status": status,
        "client_secret": None,
        "created": _now(),
        "customer": None,
        "payment_method": _next_id("pm"),
        "description": None,
        "statement_descriptor": None,
        "statement_descriptor_suffix": None,
        "metadata": {},
        "next_action": None,
        "payment_method_options": None,
        "last_payment_error": None,
        "latest_attempt": None,
        "latest_charge": None,
    }


@app.post("/v1/payment_intents")
def create_payment_intent(
    amount: Annotated[str | None, Form()] = None,
    currency: Annotated[str | None, Form()] = None,
    capture_method: Annotated[str | None, Form()] = None,
):
    parsed_amount = int(amount) if amount else 100
    cur = _currency(currency)
    is_manual = capture_method == "manual"

    if is_manual:
        status, amount_received = "requires_capture", None
    else:
        status, amount_received = "succeeded", parsed_amount

    return _payment_intent_response(
        _next_id("pi"), parsed_amount, cur, status, amount_received
    )


@app.post("/v1/payment_intents/{intent_id}/capture")
def capture_payment_intent(
    intent_id: str,
    amount_to_capture: Annotated[str | None, Form()] = None,
):
    amount = int(amount_to_capture) if amount_to_capture else 100
    return _payment_intent_response(intent_id, amount, "usd", "succeeded", amount)


@app.get("/v1/payment_intents/{intent_id}")
def get_payment_intent(intent_id: str):
    return _payment_intent_response(intent_id, 100, "usd", "succeeded", 100)


@app.post("/v1/payment_intents/{intent_id}/cancel")
def cancel_payment_intent(intent_id: str):
    return _payment_intent_response(intent_id, 100, "usd", "canceled", None)


def _setup_intent_response(id: str, status: str) -> dict[str, Any]:
    return {
        "id": id,
        "object": "setup_intent",
        "status": status,
        "client_secret": _next_id("seti_secret"),
        "customer": None,
        "payment_method": _next_id("pm"),
        "statement_descriptor": None,
        "statement_descriptor_suffix": None,
        "metadata": {},
        "next_action": None,
        "payment_method_options": None,
        "latest_attempt": None,
        "last_setup_error": None,
    }


@app.post("/v1/setup_intents")
def create_setup_intent():
    return _setup_intent_response(_next_id("set"), "succeeded")


@app.get("/v1/setup_intents/{intent_id}")
def get_setup_intent(intent_id: str):
    return _setup_intent_response(intent_id, "succeeded")


def _refund_response(
    id: str, amount: int, currency: str, payment_intent: str
) -> dict[str, Any]:
    return {
        "id": id,
        "object": "refund",
        "amount": amount,
        "currency": currency.lower(),
        "metadata": {},
        "payment_intent": payment_intent,
        "status": "succeeded",
        "failure_reason": None,
    }


@app.post("/v1/refunds")
def create_refund(
    amount: Annotated[str | None, Form()] = None,
    currency: Annotated[str | None, Form()] = None,
    payment_intent: Annotated[str | None, Form()] = None,
):
    parsed_amount = int(amount) if amount else 100
    cur = _currency(currency)
    pi = payment_intent or _next_id("pi")
    return _refund_response(_next_id("re"), parsed_amount, cur, pi)


@app.get("/v1/refunds/{refund_id}")
def get_refund(refund_id: str):
    return _refund_response(refund_id, 100, "usd", _next_id("pi"))


@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"])
async def catch_all(request: Request, path: str):
    """Return an empty 200 for any unhandled Stripe endpoint so the mock stays lenient."""
    return JSONResponse({})
