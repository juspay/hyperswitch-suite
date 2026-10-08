# Mock Stripe Connector

A tiny FastAPI server that stubs the Stripe API endpoints exercised by hyperswitch's Stripe connector. Use it for load testing or local development without hitting Stripe's rate limits.

## How it works

Run this server locally (or anywhere reachable by your hosted hyperswitch server) and point hyperswitch's `stripe.base_url` config to it. The server accepts form-urlencoded requests, ignores most fields, and returns Stripe-shaped JSON responses with deterministic success statuses.

## Endpoints

| Method | Path | Behaviour |
|--------|------|-----------|
| POST | `/v1/customers` | Returns a fake customer object |
| POST | `/v1/tokens` | Returns a fake card token |
| POST | `/v1/payment_methods` | Returns a fake payment method |
| POST | `/v1/payment_intents` | Creates a PI; `capture_method=manual` → `requires_capture`, otherwise `succeeded` |
| GET | `/v1/payment_intents/{id}` | Returns the PI as `succeeded` |
| POST | `/v1/payment_intents/{id}/capture` | Captures and returns the PI as `succeeded` |
| POST | `/v1/payment_intents/{id}/cancel` | Cancels and returns the PI as `canceled` |
| POST | `/v1/setup_intents` | Returns a fake setup intent as `succeeded` |
| GET | `/v1/setup_intents/{id}` | Returns the setup intent as `succeeded` |
| POST | `/v1/refunds` | Returns a fake refund as `succeeded` |
| GET | `/v1/refunds/{id}` | Returns the refund as `succeeded` |
| * | any other path | Returns `{}` with HTTP 200 to keep the mock lenient |

## Running locally

```bash
cd load-test/mock-stripe-connector
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 12111 --workers 4
```

The server listens on `http://0.0.0.0:12111`.

## Building the Docker image

```bash
cd load-test/mock-stripe-connector
docker build -t mock-stripe-connector:latest .
```

Run it locally:

```bash
docker run --rm -p 8080:8080 -e DELAY_MS=3000 -e WORKERS=4 mock-stripe-connector:latest
```

The image listens on `8080` and honors the `DELAY_MS` and `WORKERS` env vars (see [Notes](#notes)).

To deploy it alongside a hosted hyperswitch installation, push the image to a container registry your cluster can pull from:

```bash
docker tag mock-stripe-connector:latest <registry>/mock-stripe-connector:<tag>
docker push <registry>/mock-stripe-connector:<tag>
```

## Pointing hyperswitch to the mock

Update the hyperswitch config (e.g. `config/development.toml` or whichever config file your hosted server loads):

```toml
stripe.base_url = "http://<mock-server-host>:12111/"
stripebilling.base_url = "http://<mock-server-host>:12111/"
```

If running the mock on the same machine as hyperswitch, use `http://127.0.0.1:12111/`. If hyperswitch is hosted elsewhere, use the mock server's reachable IP/hostname.

## Notes

- Every request is delayed by `DELAY_MS` milliseconds (default **3000**, i.e. 3 seconds) to simulate realistic connector latency. Override it with `-e DELAY_MS=<milliseconds>` (Docker/Podman) or the `DELAY_MS` env var directly.
- The number of uvicorn worker processes is controlled by the `WORKERS` env var (default **4**, image only — not used when running via `uvicorn` directly, where `--workers` is passed on the command line). Override it with `-e WORKERS=<count>`.
- Authentication headers (`Authorization`, `Stripe-Version`) are accepted but not validated, so any Stripe API key configured in hyperswitch works.
- File-upload endpoints (`files.stripe.com`) are not specifically mocked; calls fall through to the catch-all handler.
- Responses are intentionally minimal but include all fields that hyperswitch's Stripe deserializers require.
