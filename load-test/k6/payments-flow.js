import http from 'k6/http';
import { check, sleep, group } from 'k6';

// -------------------------------------------------------------------------
// Configuration (all values come from environment variables)
// -------------------------------------------------------------------------
const BASE_URL = __ENV.BASE_URL;
const API_KEY = __ENV.API_KEY;
const PROFILE_ID = __ENV.PROFILE_ID || '';
const RETURN_URL = __ENV.RETURN_URL || 'https://example.com';

const VU_COUNT = Number(__ENV.VU_COUNT || 10);
const DURATION = __ENV.DURATION || '5m';
const RAMP_UP = __ENV.RAMP_UP || '30s';
const RAMP_DOWN = __ENV.RAMP_DOWN || '30s';

export const options = {
  scenarios: {
    payment_flow: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: RAMP_UP, target: VU_COUNT },
        { duration: DURATION, target: VU_COUNT },
        { duration: RAMP_DOWN, target: 0 },
      ],
      gracefulRampDown: '10s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<2500'],
    'http_req_duration{group:::1. Create Payment}': ['p(95)<1000'],
    'http_req_duration{group:::2. Confirm Payment}': ['p(95)<2000'],
    'http_req_duration{group:::3. Retrieve Payment}': ['p(95)<1000'],
  },
};

export function setup() {
  if (!BASE_URL) {
    throw new Error(
      'BASE_URL environment variable is required (your Hyperswitch server URL). ' +
      'Example: BASE_URL=http://localhost:8080 API_KEY=<merchant-api-key> k6 run payments-flow.js'
    );
  }
  if (!API_KEY) {
    throw new Error(
      'API_KEY environment variable is required (a merchant API key). ' +
      'Example: BASE_URL=http://localhost:8080 API_KEY=<merchant-api-key> k6 run payments-flow.js'
    );
  }
}

const headers = {
  'Content-Type': 'application/json',
  Accept: 'application/json',
  'api-key': API_KEY,
};

const RANDOM_CHARS = 'abcdefghijklmnopqrstuvwxyz0123456789';

function randomString(length) {
  let out = '';
  for (let i = 0; i < length; i++) {
    out += RANDOM_CHARS[Math.floor(Math.random() * RANDOM_CHARS.length)];
  }
  return out;
}

function parseJson(res) {
  try {
    return res.json();
  } catch (e) {
    console.error(`Failed to parse JSON response. Status=${res.status}, Body=${res.body}`);
    return null;
  }
}

function makePaymentId() {
  // Hyperswitch payment_id must be exactly 30 characters.
  return 'pay_' + randomString(26);
}

function createPayment() {
  const payload = {
    amount: 6540,
    currency: 'USD',
    confirm: false,
    capture_method: 'automatic',
    authentication_type: 'no_three_ds',
    payment_id: makePaymentId(),
    customer: {
      id: `cus_${randomString(20)}`,
      email: `loadtest-${randomString(8)}@example.com`,
      name: 'k6 Load Test',
      phone: '9123456789',
    },
    description: 'k6 load test payment',
    return_url: RETURN_URL,
  };

  if (PROFILE_ID) {
    payload.profile_id = PROFILE_ID;
  }

  const res = http.post(`${BASE_URL}/payments`, JSON.stringify(payload), {
    headers,
    tags: { name: 'payments-create' },
  });

  const body = parseJson(res);

  check(res, {
    'create status is 200': (r) => r.status === 200,
    'create response has payment_id': () => body && typeof body.payment_id === 'string' && body.payment_id.length === 30,
  });

  return body;
}

function confirmPayment(paymentId) {
  const payload = {
    payment_method: 'card',
    payment_method_type: 'credit',
    payment_method_data: {
      card: {
        card_number: '4242424242424242',
        card_exp_month: '12',
        card_exp_year: '30',
        card_cvc: '123',
        card_holder_name: 'k6 Load Test',
      },
    },
    customer_acceptance: {
      acceptance_type: 'online',
      accepted_at: new Date().toISOString(),
      online: {
        ip_address: '127.0.0.1',
        user_agent: 'k6-load-test/1.0',
      },
    },
  };

  const res = http.post(`${BASE_URL}/payments/${paymentId}/confirm`, JSON.stringify(payload), {
    headers,
    tags: { name: 'payments-confirm' },
  });

  const body = parseJson(res);

  check(res, {
    'confirm status is 200': (r) => r.status === 200,
    'confirm response has terminal status': () =>
      body &&
      (body.status === 'succeeded' ||
        body.status === 'requires_capture' ||
        body.status === 'processing'),
  });

  return body;
}

function retrievePayment(paymentId) {
  const res = http.get(`${BASE_URL}/payments/${paymentId}`, {
    headers,
    tags: { name: 'payments-retrieve' },
  });

  const body = parseJson(res);

  check(res, {
    'retrieve status is 200': (r) => r.status === 200,
    'retrieve response matches payment_id': () => body && body.payment_id === paymentId,
  });

  return body;
}

export default function () {
  let paymentId;

  group('1. Create Payment', () => {
    const created = createPayment();
    if (!created || !created.payment_id) {
      console.error(`Create payment failed for VU ${__VU} iteration ${__ITER}`);
      return;
    }
    paymentId = created.payment_id;
  });

  if (!paymentId) {
    return;
  }

  group('2. Confirm Payment', () => {
    confirmPayment(paymentId);
  });

  group('3. Retrieve Payment', () => {
    retrievePayment(paymentId);
  });

  // Minimal pacing between iterations. Remove or adjust for higher throughput.
  sleep(1);
}
