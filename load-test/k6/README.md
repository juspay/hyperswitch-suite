# Hyperswitch Payments Load Test (k6)

A [k6](https://k6.io/) script that exercises the core Hyperswitch payment flow
against any Hyperswitch deployment:

1. **Create Payment** — `POST /payments`
2. **Confirm Payment** — `POST /payments/{payment_id}/confirm`
3. **Retrieve Payment** — `GET /payments/{payment_id}`

Each virtual user creates a payment with a unique 30-character `payment_id`,
confirms it with a test card, and then retrieves the final state.

The script is fully self-contained: it only talks to the Hyperswitch API over
HTTP. It has no cloud-provider dependencies (no AWS, ElastiCache, etc.) and no
external library imports, so it runs anywhere k6 runs — including air-gapped
environments.

## Prerequisites

- [k6](https://k6.io/docs/get-started/installation/) installed locally.
- A reachable Hyperswitch server (local, self-hosted, or hosted).
- A merchant API key for that server.

## Running the test

From this directory:

```bash
export BASE_URL="http://localhost:8080"   # your Hyperswitch server URL
export API_KEY="<merchant-api-key>"
export PROFILE_ID="pro_..."               # optional, omit if you use the default profile
k6 run payments-flow.js
```

> Never commit the API key. Always pass it via environment variables or
> your CI/CD secret store.

## Configuration

| Variable       | Default               | Description                                 |
|----------------|-----------------------|---------------------------------------------|
| `BASE_URL`     | *required*            | Base URL of the Hyperswitch server          |
| `API_KEY`      | *required*            | Hyperswitch merchant `api-key`              |
| `PROFILE_ID`   | *(none)*              | Business profile ID                         |
| `RETURN_URL`   | `https://example.com` | `return_url` sent on payment create         |
| `VU_COUNT`     | `10`                  | Peak number of virtual users                |
| `RAMP_UP`      | `30s`                 | Ramp-up duration                            |
| `DURATION`     | `5m`                  | Steady-state duration                       |
| `RAMP_DOWN`    | `30s`                 | Ramp-down duration                          |

### Examples

Smoke test (1 VU, 1 iteration):

```bash
k6 run --env BASE_URL=$BASE_URL --env API_KEY=$API_KEY --env VU_COUNT=1 --env DURATION=1s --env RAMP_UP=1s --env RAMP_DOWN=1s payments-flow.js
```

Heavier sustained load:

```bash
k6 run \
  --env BASE_URL=$BASE_URL \
  --env API_KEY=$API_KEY \
  --env PROFILE_ID=$PROFILE_ID \
  --env VU_COUNT=50 \
  --env DURATION=10m \
  --env RAMP_UP=2m \
  --env RAMP_DOWN=1m \
  payments-flow.js
```

## Test card

The script uses the generic sandbox-success Visa test card:

- Number: `4242424242424242`
- Expiry: `12 / 30`
- CVC: `123`

Replace the card payload in `confirmPayment()` if you need to test a different
payment method or connector.

To load test without hitting a real payment processor (and its rate limits),
point your Hyperswitch connector configuration at the
[mock Stripe connector](../mock-stripe-connector/) included in this repository.

## Metrics and thresholds

Built-in thresholds:

- Overall failure rate < 5 %
- p(95) latency < 2.5 s overall
- p(95) latency per endpoint:
  - Create < 1 s
  - Confirm < 2 s
  - Retrieve < 1 s

Results are printed to stdout after the test completes. For CI/CD, you can
export results to JSON/InfluxDB/Prometheus — see the
[k6 outputs guide](https://k6.io/docs/results-output/output-options/).
