# Changelog

All notable changes to Hyperswitch will be documented here.

## Hyperswitch Suite v1.1

### [Hyperswitch App Server v1.107.0 (2024-03-12)](https://github.com/juspay/hyperswitch/releases/tag/v1.107.0)

#### Docker Release

- [v1.107.0](https://hub.docker.com/layers/juspaydotin/hyperswitch-router/v1.107.0/images/sha256-a4fe381304b8400e0e0b998b59d78d87ae36d270ad8e36a85db76ad4300faf84) (with KMS)
- [v1.107.0-standalone](https://hub.docker.com/layers/juspaydotin/hyperswitch-router/v1.107.0-standalone/images/sha256-247aa02f8190cb4309167b8c777072feae3b093f8fdb27500634cc948d7a8811) (without KMS)

#### New Features

- **connector**: [Cybersource] Implement 3DS flow for cards ([#3290](https://github.com/juspay/hyperswitch/pull/3290))
- **connector**: [Volt] Add support for Payments Webhooks ([#3155](https://github.com/juspay/hyperswitch/pull/3155))
- **connector**: [Volt] Add support for refund webhooks ([#3326](https://github.com/juspay/hyperswitch/pull/3326))
- **connector**: [BANKOFAMERICA] Implement 3DS flow for cards ([#3343](https://github.com/juspay/hyperswitch/pull/3343))
- **connector**: [Adyen] Add support for PIX Payment Method ([#3236](https://github.com/juspay/hyperswitch/pull/3236))
- **connector**: [Payme] Add Void flow to Payme ([#3817](https://github.com/juspay/hyperswitch/pull/3817))
- Add support for PaymentAuthorized, PaymentCaptured webhook events ([#3212](https://github.com/juspay/hyperswitch/pull/3212))
- Add outgoing webhook for manual partial_capture events ([#3388](https://github.com/juspay/hyperswitch/pull/3388))
- Implement hashicorp secrets manager solution ([#3297](https://github.com/juspay/hyperswitch/pull/3297))
- Add a logging middleware to log all api requests ([#3437](https://github.com/juspay/hyperswitch/pull/3437))
- Added sdk layout option payment link ([#3207](https://github.com/juspay/hyperswitch/pull/3207))
- Add capability to store bank details using /payment_methods endpoint ([#3113](https://github.com/juspay/hyperswitch/pull/3113))
- Add Wallet to Payouts ([#3502](https://github.com/juspay/hyperswitch/pull/3502))
- Extend routing capabilities to payout operation ([#3531](https://github.com/juspay/hyperswitch/pull/3531))
- Implement Smart Retries for Payout ([#3580](https://github.com/juspay/hyperswitch/pull/3580))
- Add recon APIs ([#3345](https://github.com/juspay/hyperswitch/pull/3345))
- Payment_method block ([#3056](https://github.com/juspay/hyperswitch/pull/3056))
- Add delete_evidence api for disputes ([#3608](https://github.com/juspay/hyperswitch/pull/3608))
- Add support to delete user ([#3374](https://github.com/juspay/hyperswitch/pull/3374))
- Support multiple invites ([#3422](https://github.com/juspay/hyperswitch/pull/3422))
- Add support for resend invite ([#3523](https://github.com/juspay/hyperswitch/pull/3523))
- Create apis for custom role ([#3763](https://github.com/juspay/hyperswitch/pull/3763))
- Invite user without email ([#3328](https://github.com/juspay/hyperswitch/pull/3328))
- Add transfer org ownership API ([#3603](https://github.com/juspay/hyperswitch/pull/3603))
- Add deep health check ([#3210](https://github.com/juspay/hyperswitch/pull/3210))
- Add support for card extended bin in payment attempt ([#3312](https://github.com/juspay/hyperswitch/pull/3312))

#### Refactors / Bug Fixes

- Fix the error during surcharge with saved card ([#3318](https://github.com/juspay/hyperswitch/pull/3318))
- Return surcharge in payment method list response if passed in create request ([#3363](https://github.com/juspay/hyperswitch/pull/3363))
- Fix mandate_details to store some value only if mandate_data struct is present ([#3525](https://github.com/juspay/hyperswitch/pull/3525))
- Add column mandate_data for storing the details of a mandate in PaymentAttempt ([#3606](https://github.com/juspay/hyperswitch/pull/3606))
- Validate amount_to_capture in payment update ([#3830](https://github.com/juspay/hyperswitch/pull/3830))
- Add merchant_connector_id in refund ([#3303](https://github.com/juspay/hyperswitch/pull/3303))
- Update amount_capturable based on intent_status and payment flow ([#3278](https://github.com/juspay/hyperswitch/pull/3278))
- Auto retry once for connection closed ([#3426](https://github.com/juspay/hyperswitch/pull/3426))
- Add locker config to enable or disable locker ([#3352](https://github.com/juspay/hyperswitch/pull/3352))
- Restrict requires_customer_action in confirm ([#3235](https://github.com/juspay/hyperswitch/pull/3235))
- Inclusion of locker to store fingerprints ([#3630](https://github.com/juspay/hyperswitch/pull/3630))
- Status mapping for Capture for 429 http code ([#3897](https://github.com/juspay/hyperswitch/pull/3897))
- Change unique constraint to connector label ([#3091](https://github.com/juspay/hyperswitch/pull/3091))
- Segregated payment link in html css js files, sdk over flow issue, surcharge bug, block SPM customer call for payment link ([#3410](https://github.com/juspay/hyperswitch/pull/3410))
- Add Miscellaneous charges in cart for payment links ([#3645](https://github.com/juspay/hyperswitch/pull/3645))
- Handle card duplication ([#3146](https://github.com/juspay/hyperswitch/pull/3146))
- Restricted list payment method Customer to api-key based ([#3100](https://github.com/juspay/hyperswitch/pull/3100))

#### Database Migrations

<details><summary>Click to view database migrations</summary>
<pre>
DB Difference between v1.105.1 and v1.107.0
-- Your SQL goes here
ALTER TABLE business_profile
ADD COLUMN IF NOT EXISTS payment_link_config JSONB DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE payment_link ADD COLUMN IF NOT EXISTS  profile_id VARCHAR(64) DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE merchant_connector_account
ADD UNIQUE (profile_id, connector_label);

DROP INDEX IF EXISTS "merchant_connector_account_profile_id_connector_id_index";
-- Your SQL goes here
ALTER TABLE payment_intent ADD COLUMN IF NOT EXISTS session_expiry TIMESTAMP DEFAULT NULL;
-- Your SQL goes here

CREATE TYPE "BlocklistDataKind" AS ENUM (
'payment_method',
'card_bin',
'extended_card_bin'
);

CREATE TABLE blocklist_fingerprint (
id SERIAL PRIMARY KEY,
merchant_id VARCHAR(64) NOT NULL,
fingerprint_id VARCHAR(64) NOT NULL,
data_kind "BlocklistDataKind" NOT NULL,
encrypted_fingerprint TEXT NOT NULL,
created_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX blocklist_fingerprint_merchant_id_fingerprint_id_index
ON blocklist_fingerprint (merchant_id, fingerprint_id);
-- Your SQL goes here

CREATE TABLE blocklist (
id SERIAL PRIMARY KEY,
merchant_id VARCHAR(64) NOT NULL,
fingerprint_id VARCHAR(64) NOT NULL,
data_kind "BlocklistDataKind" NOT NULL,
metadata JSONB,
created_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX blocklist_unique_fingerprint_id_index ON blocklist (merchant_id, fingerprint_id);
CREATE INDEX blocklist_merchant_id_data_kind_created_at_index ON blocklist (merchant_id, data_kind, created_at DESC);
-- Your SQL goes here
ALTER TABLE payment_intent ADD COLUMN IF NOT EXISTS fingerprint_id VARCHAR(64);
ALTER TABLE payment_attempt
ADD COLUMN IF NOT EXISTS net_amount BIGINT;
-- Backfill
UPDATE payment_attempt pa
SET net_amount = pa.amount + COALESCE(pa.surcharge_amount, 0) + COALESCE(pa.tax_amount, 0);
-- Your SQL goes here

CREATE TABLE blocklist_lookup (
id SERIAL PRIMARY KEY,
merchant_id VARCHAR(64) NOT NULL,
fingerprint TEXT NOT NULL
);

CREATE UNIQUE INDEX blocklist_lookup_merchant_id_fingerprint_index ON blocklist_lookup (merchant_id, fingerprint);
-- Your SQL goes here
ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS session_expiry BIGINT DEFAULT NULL;
-- Your SQL goes here
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'payment_authorized';
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'payment_captured';
-- Your SQL goes here
ALTER TABLE users ADD COLUMN preferred_merchant_id VARCHAR(64);
-- Your SQL goes here
ALTER TYPE "DashboardMetadata" ADD VALUE IF NOT EXISTS 'integration_completed';
-- Your SQL goes here
ALTER TABLE payout_attempt
ALTER COLUMN connector TYPE JSONB USING jsonb_build_object (
'routed_through', connector, 'algorithm', NULL
);

ALTER TABLE payout_attempt ADD COLUMN routing_info JSONB;

UPDATE payout_attempt
SET
routing_info = connector -> 'algorithm'
WHERE
connector ->> 'algorithm' IS NOT NULL;

ALTER TABLE payout_attempt
ALTER COLUMN connector TYPE VARCHAR(64) USING connector ->> 'routed_through';

ALTER TABLE payout_attempt ALTER COLUMN connector DROP NOT NULL;

CREATE type "TransactionType" as ENUM('payment', 'payout');

ALTER TABLE routing_algorithm
ADD COLUMN algorithm_for "TransactionType" DEFAULT 'payment' NOT NULL;

ALTER TABLE routing_algorithm
ALTER COLUMN algorithm_for
DROP DEFAULT;
-- Your SQL goes here
ALTER TYPE "PayoutType" ADD VALUE IF NOT EXISTS 'wallet';
-- Your SQL goes here
ALTER TABLE payouts
ADD COLUMN attempt_count SMALLINT NOT NULL DEFAULT 1;

UPDATE payouts
SET attempt_count = payout_id_count.count
FROM (SELECT payout_id, count(payout_id) FROM payout_attempt GROUP BY payout_id) as payout_id_count
WHERE payouts.payout_id = payout_id_count.payout_id;
-- Your SQL goes here
ALTER TABLE payment_attempt
ADD COLUMN IF NOT EXISTS mandate_data JSONB DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE payment_attempt ADD COLUMN IF NOT EXISTS fingerprint_id VARCHAR(64);
-- Your SQL goes here
CREATE TYPE "RoleScope" AS ENUM ('merchant','organization');

CREATE TABLE IF NOT EXISTS roles (
id SERIAL PRIMARY KEY,
role_name VARCHAR(64) NOT NULL,
role_id VARCHAR(64) NOT NULL UNIQUE,
merchant_id VARCHAR(64) NOT NULL,
org_id VARCHAR(64) NOT NULL,
groups TEXT[] NOT NULL,
scope "RoleScope" NOT NULL,
created_at TIMESTAMP NOT NULL DEFAULT now(),
created_by VARCHAR(64) NOT NULL,
last_modified_at TIMESTAMP NOT NULL DEFAULT now(),
last_modified_by VARCHAR(64) NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS role_id_index ON roles (role_id);
CREATE INDEX roles_merchant_org_index ON roles (merchant_id, org_id);
-- Your SQL goes here
ALTER TABLE address
ADD COLUMN IF NOT EXISTS email BYTEA;
-- Your SQL goes here
ALTER TYPE "DashboardMetadata" ADD VALUE IF NOT EXISTS 'is_change_password_required';
-- Your SQL goes here

ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS locker_id VARCHAR(64) DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMP NOT NULL DEFAULT now()::TIMESTAMP;
-- Your SQL goes here
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS default_payment_method_id VARCHAR(64);
-- Your SQL goes here

ALTER TABLE payment_methods
ADD COLUMN connector_mandate_details JSONB
DEFAULT NULL;

ALTER TABLE payment_methods
ADD COLUMN customer_acceptance JSONB
DEFAULT NULL;

ALTER TABLE payment_methods
ADD COLUMN status VARCHAR(64)
NOT NULL DEFAULT 'active';
-- Your SQL goes here
CREATE UNIQUE INDEX role_name_org_id_org_scope_index ON roles(org_id, role_name) WHERE scope='organization';
CREATE UNIQUE INDEX role_name_merchant_id_merchant_scope_index ON roles(merchant_id, role_name) WHERE scope='merchant';
-- Your SQL goes here
-- Add the new column with a default value
ALTER TABLE dispute
ADD COLUMN dispute_amount BIGINT NOT NULL DEFAULT 0;

-- Update existing rows to set the default value based on the integer equivalent of the amount column
UPDATE dispute
SET dispute_amount = CAST(amount AS BIGINT);

</pre>
</details>

[Comparing v1.105.1..v107.0 - juspay/hyperswitch](https://github.com/juspay/hyperswitch/compare/v1.105.1..v1.107.0)

#### Configuration Changes

<details>
<summary>Click to view a diff of configuration changes between <code>v1.105.1</code> and <code>v1.107.0</code></summary>
<pre>
   {
     "name": "ROUTER__BANK_CONFIG__IDEAL__ADYEN__BANKS",
-    "value": "abn_amro,asn_bank,bunq,handelsbanken,ing,knab,moneyou,rabobank,regiobank,revolut,sns_bank,triodos_bank,van_lanschot"
+    "value": "abn_amro,asn_bank,bunq,ing,knab,n26,nationale_nederlanden,rabobank,regiobank,revolut,sns_bank,triodos_bank,van_lanschot,yoursafe"
   },
   {
     "name": "ROUTER__BANK_CONFIG__ONLINE_BANKING_FPX__ADYEN__BANKS",
-    "value": "affin_bank,agro_bank,alliance_bank,am_bank,bank_islam,bank_muamalat,bank_rakyat,bank_simpanan_nasional,cimb_bank,hong_leong_bank,hsbc_bank,kuwait_finance_house,may_bank,ocbc_bank,public_bank,rhb_bank,standard_chartered_bank,uob_bank"
+    "value": "affin_bank,agro_bank,alliance_bank,am_bank,bank_islam,bank_muamalat,bank_rakyat,bank_simpanan_nasional,cimb_bank,hong_leong_bank,hsbc_bank,kuwait_finance_house,maybank,ocbc_bank,public_bank,rhb_bank,standard_chartered_bank,uob_bank"
   },
   {
     "name": "ROUTER__BANK_CONFIG__ONLINE_BANKING_SLOVAKIA__ADYEN__BANKS",
-    "value": "e_platby_v_u_b,e_platby_vub,postova_banka,sporo_pay,tatra_pay,viamo,volksbank_gruppe,volkskredit_bank_ag,vr_bank_braunau"
+    "value": "e_platby_vub,postova_banka,sporo_pay,tatra_pay,viamo,volksbank_gruppe,volkskreditbank_ag,vr_bank_braunau"
   },
   {
     "name": "ROUTER__CONNECTORS__ADYEN__BASE_URL",
-    "value": "https://checkout-test.adyen.com/"
+    "value": "https://{{merchant_endpoint_prefix}}-checkout-live.adyenpayments.com/"
   },
   {
     "name": "ROUTER__CONNECTORS__ADYEN__SECONDARY_BASE_URL",
-    "value": "https://pal-test.adyen.com/"
+    "value": "https://{{merchant_endpoint_prefix}}-pal-live.adyenpayments.com/"
   },
   {
     "name": "ROUTER__CONNECTORS__CYBERSOURCE__BASE_URL",
-    "value": "https://apitest.cybersource.com/"
+    "value": "https://api.cybersource.com/"
   },
+  {
+    "name": "ROUTER__CORS__ALLOWED_METHODS",
+    "value": "GET,PUT,POST,DELETE"
+  },
+  {
+    "name": "ROUTER__CORS__MAX_AGE",
+    "value": "30"
+  },
+  {
+    "name": "ROUTER__CORS__WILDCARD_ORIGIN",
+    "value": "true"
+  },
+  {
+    "name": "ROUTER__EVENTS__KAFKA__DISPUTE_ANALYTICS_TOPIC",
+    "value": "hyperswitch-dispute-events"
+  },
-  {
-    "name": "ROUTER__JWEKEY__LOCKER_DECRYPTION_KEY1",
-    "value": "secret"
-  },
-  {
-    "name": "ROUTER__JWEKEY__LOCKER_DECRYPTION_KEY2",
-    "value": "secret"
-  },
-  {
-    "name": "ROUTER__JWEKEY__LOCKER_ENCRYPTION_KEY1",
-    "value": "secret"
-  },
-  {
-    "name": "ROUTER__JWEKEY__LOCKER_ENCRYPTION_KEY2",
-    "value": "secret"
-  },
-  {
-    "name": "ROUTER__JWEKEY__LOCKER_KEY_IDENTIFIER1",
-    "value": "secret"
-  },
-  {
-    "name": "ROUTER__JWEKEY__LOCKER_KEY_IDENTIFIER2",
-    "value": "secret"
-  },
+  {
+    "name": "ROUTER__LOCKER__LOCKER_ENABLED",
+    "value": "true"
+  },
+  {
+    "name": "ROUTER__MANDATES__SUPPORTED_PAYMENT_METHODS__BANK_REDIRECT__GIROPAY__CONNECTOR_LIST",
+    "value": "adyen,globalpay"
+  },
+  {
+    "name": "ROUTER__MANDATES__SUPPORTED_PAYMENT_METHODS__BANK_REDIRECT__IDEAL__CONNECTOR_LIST",
+    "value": "stripe,adyen,globalpay"
+  },
+  {
+    "name": "ROUTER__MANDATES__SUPPORTED_PAYMENT_METHODS__BANK_REDIRECT__SOFORT__CONNECTOR_LIST",
+    "value": "stripe,adyen,globalpay"
+  },
   {
     "name": "ROUTER__MANDATES__SUPPORTED_PAYMENT_METHODS__CARD__CREDIT__CONNECTOR_LIST",
-    "value": "stripe,adyen,authorizedotnet,globalpay,worldpay,multisafepay,nmi,nexinets,noon"
+    "value": "stripe,adyen,authorizedotnet,cybersource,globalpay,worldpay,multisafepay,nmi,nexinets,noon"
   },
   {
     "name": "ROUTER__MANDATES__SUPPORTED_PAYMENT_METHODS__CARD__DEBIT__CONNECTOR_LIST",
-    "value": "stripe,adyen,authorizedotnet,globalpay,worldpay,multisafepay,nmi,nexinets,noon"
+    "value": "stripe,adyen,authorizedotnet,cybersource,globalpay,worldpay,multisafepay,nmi,nexinets,noon"
   },
   {
     "name": "ROUTER__MANDATES__SUPPORTED_PAYMENT_METHODS__WALLET__APPLE_PAY__CONNECTOR_LIST",
-    "value": "stripe,adyen"
+    "value": "stripe,adyen,cybersource,noon"
   },
   {
     "name": "ROUTER__MANDATES__SUPPORTED_PAYMENT_METHODS__WALLET__GOOGLE_PAY__CONNECTOR_LIST",
-    "value": "stripe,adyen"
+    "value": "stripe,adyen,cybersource"
   },
+  {
+    "name": "ROUTER__MANDATES__UPDATE_MANDATE_SUPPORTED__CARD__CREDIT__CONNECTOR_LIST",
+    "value": "cybersource"
+  },
+  {
+    "name": "ROUTER__MANDATES__UPDATE_MANDATE_SUPPORTED__CARD__DEBIT__CONNECTOR_LIST",
+    "value": "cybersource"
+  },
-  {
-    "name": "ROUTER__OSS_DECISION_MANAGER__OSS_3DS_DECISION_ENABLED",
-    "value": "false"
-  },
-  {
-    "name": "ROUTER__OSS_DECISION_MANAGER__OSS_SURCHARGE_DECISION_ENABLED",
-    "value": "false"
-  },
-  {
-    "name": "ROUTER__OSS_ROUTING__ENABLED",
-    "value": "true"
-  },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__AFTERPAY_CLEARPAY__COUNTRY",
-    "value": "AU,CA,ES,FR,IT,NZ,UK,US"
+    "value": "AU,CA,ES,FR,IT,NZ,GB,US"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__ALI_PAY__COUNTRY",
-    "value": "AU,N,JP,HK,SG,MY,TH,ES,UK,SE,NO,AT,NL,DE,CY,CH,BE,FR,DK,FI,RO,MT,SI,GR,PT,IE,IT,CA,US"
+    "value": "AU,JP,HK,SG,MY,TH,ES,GB,SE,NO,AT,NL,DE,CY,CH,BE,FR,DK,FI,RO,MT,SI,GR,PT,IE,IT,CA,US"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__APPLE_PAY__COUNTRY",
-    "value": "AE,AK,AM,AR,AT,AU,AZ,BE,BG,BH,BR,BY,CA,CH,CN,CO,CR,CY,CZ,DE,DK,EE,ES,FI,FO,FR,GB,GE,GG,GL,GR,HK,HR,HU,IE,IL,IM,IS,IT,JE,JO,JP,KW,KZ,LI,LT,LU,LV,MC,MD,ME,MO,MT,MX,MY,NL,NO,NZ,PE,PL,PS,PT,QA,RO,RS,SA,SE,SG,SI,SK,SM,TW,UA,UK,UM,US"
+    "value": "AE,AM,AR,AT,AU,AZ,BE,BG,BH,BR,BY,CA,CH,CN,CO,CR,CY,CZ,DE,DK,EE,ES,FI,FO,FR,GB,GE,GG,GL,GR,HK,HR,HU,IE,IL,IM,IS,IT,JE,JO,JP,KW,KZ,LI,LT,LU,LV,MC,MD,ME,MO,MT,MX,MY,NL,NO,NZ,PE,PL,PS,PT,QA,RO,RS,SA,SE,SG,SI,SK,SM,TW,UA,GB,UM,US"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__BACS__COUNTRY",
-    "value": "UK"
+    "value": "GB"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__GOOGLE_PAY__COUNTRY",
-    "value": "AE,AG,AL,AO,AR,AS,AT,AU,AZ,BE,BG,BH,BR,BY,CA,CH,CL,CO,CY,CZ,DE,DK,DO,DZ,EE,EG,ES,FI,FR,GB,GR,HK,HR,HU,ID,IE,IL,IN,IS,IT,JO,JP,KE,KW,KZ,LB,LI,LK,LT,LU,LV,MT,MX,MY,NL,NO,NZ,OM,PA,PE,PH,PK,PL,PT,QA,RO,RU,SA,SE,SG,SI,SK,TH,TR,TW,UA,UK,US,UY,VN,ZA"
+    "value": "AE,AG,AL,AO,AR,AS,AT,AU,AZ,BE,BG,BH,BR,BY,CA,CH,CL,CO,CY,CZ,DE,DK,DO,DZ,EE,EG,ES,FI,FR,GB,GR,HK,HR,HU,ID,IE,IL,IN,IS,IT,JO,JP,KE,KW,KZ,LB,LI,LK,LT,LU,LV,MT,MX,MY,NL,NO,NZ,OM,PA,PE,PH,PK,PL,PT,QA,RO,RU,SA,SE,SG,SI,SK,TH,TR,TW,UA,GB,US,UY,VN,ZA"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__GOOGLE_PAY__CURRENCY",
-    "value": "AED,ALL,AMD,ANG,AOA,ARS,AUD,AWG,AZN,BAM,BBD,BDT,BGN,BHD,BMD,BND,BOB,BRL,BSD,BWP,BYN,BZD,CAD,CHF,CLP,CNY,COP,CRC,CUP,CVE,CZK,DJF,DKK,DOP,DZD,EGP,ETB,EUR,FJD,FKP,GBP,GEL,GHS,GIP,GMD,GNF,GTQ,GYD,HKD,HNL,HTG,HUF,IDR,ILS,INR,IQD,ISK,JMD,JOD,JPY,KES,KGS,KHR,KMF,KRW,KWD,KYD,KZT,LAK,LBP,LKR,LYD,MAD,MDL,MKD,MMK,MNT,MOP,MRU,MUR,MVR,MWK,MXN,MYR,MZN,NAD,NGN,NIO,NOK,NPR,NZD,OMR,PAB,PEN,PGK,PHP,PKR,PLN,PYG,QAR,RON,RSD,RUB,RWF,SAR,SBD,SCR,SEK,SGD,SHP,SLE,SOS,SRD,STN,SVC,SZL,THB,TND,TOP,TRY,TTD,TWD,TZS,UAH,UGX,USD,UYU,UZS,VEF,VND,VUV,WST,XAF,XCD,XOF,XPF,YER,ZAR,ZMW"
+    "value": "AED,ALL,AMD,ANG,AOA,ARS,AUD,AWG,AZN,BAM,BBD,BDT,BGN,BHD,BMD,BND,BOB,BRL,BSD,BWP,BYN,BZD,CAD,CHF,CLP,CNY,COP,CRC,CUP,CVE,CZK,DJF,DKK,DOP,DZD,EGP,ETB,EUR,FJD,FKP,GBP,GEL,GHS,GIP,GMD,GNF,GTQ,GYD,HKD,HNL,HTG,HUF,IDR,ILS,INR,IQD,JMD,JOD,JPY,KES,KGS,KHR,KMF,KRW,KWD,KYD,KZT,LAK,LBP,LKR,LYD,MAD,MDL,MKD,MMK,MNT,MOP,MRU,MUR,MVR,MWK,MXN,MYR,MZN,NAD,NGN,NIO,NOK,NPR,NZD,OMR,PAB,PEN,PGK,PHP,PKR,PLN,PYG,QAR,RON,RSD,RUB,RWF,SAR,SBD,SCR,SEK,SGD,SHP,SLE,SOS,SRD,STN,SVC,SZL,THB,TND,TOP,TRY,TTD,TWD,TZS,UAH,UGX,USD,UYU,UZS,VES,VND,VUV,WST,XAF,XCD,XOF,XPF,YER,ZAR,ZMW"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__KLARNA__COUNTRY",
-    "value": "AT,BE,CA,CH,DE,DK,ES,FI,FR,GB,IE,IT,NL,NO,PL,PT,SE,UK,US"
+    "value": "AU,AT,BE,CA,CZ,DK,FI,FR,DE,GR,IE,IT,NO,PL,PT,RO,ES,SE,CH,NL,GB,US"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__KLARNA__CURRENCY",
-    "value": "AUD,CAD,CHF,DKK,EUR,GBP,NOK,PLN,SEK,USD"
+    "value": "AUD,EUR,CAD,CZK,DKK,NOK,PLN,RON,SEK,CHF,GBP,USD"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__PAYPAL__COUNTRY",
-    "value": "AU,NZ,CN,JP,HK,MY,TH,KR,PH,ID,AE,KW,BR,ES,UK,SE,NO,SK,AT,NL,DE,HU,CY,LU,CH,BE,FR,DK,FI,RO,HR,UA,MT,SI,GI,PT,IE,CZ,EE,LT,LV,IT,PL,IS,CA,US"
+    "value": "AU,NZ,CN,JP,HK,MY,TH,KR,PH,ID,AE,KW,BR,ES,GB,SE,NO,SK,AT,NL,DE,HU,CY,LU,CH,BE,FR,DK,FI,RO,HR,UA,MT,SI,GI,PT,IE,CZ,EE,LT,LV,IT,PL,IS,CA,US"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__PAY_SAFE_CARD__COUNTRY",
-    "value": "AT,AU,BE,BR,BE,CA,HR,CY,CZ,DK,FI,FR,GE,DE,GI,HU,IS,IE,KW,LV,IE,LI,LT,LU,MT,MX,MD,ME,NL,NZ,NO,PY,PE,PL,PT,RO,SA,RS,SK,SI,ES,SE,CH,TR,UAE,UK,US,UY"
+    "value": "AT,AU,BE,BR,BE,CA,HR,CY,CZ,DK,FI,FR,GE,DE,GI,HU,IS,IE,KW,LV,IE,LI,LT,LU,MT,MX,MD,ME,NL,NZ,NO,PY,PE,PL,PT,RO,SA,RS,SK,SI,ES,SE,CH,TR,AE,GB,US,UY"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__PAY_SAFE_CARD__CURRENCY",
-    "value": "EUR,AUD,BRL,CAD,CZK,DKK,GEL,GIP,HUF,ISK,KWD,CHF,MXN,MDL,NZD,NOK,PYG,PEN,PLN,RON,SAR,RSD,SEK,TRY,AED,GBP,USD,UYU"
+    "value": "EUR,AUD,BRL,CAD,CZK,DKK,GEL,GIP,HUF,KWD,CHF,MXN,MDL,NZD,NOK,PYG,PEN,PLN,RON,SAR,RSD,SEK,TRY,AED,GBP,USD,UYU"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__SOFORT__COUNTRY",
-    "value": "AT,BE,CH,DE,ES,FI,FR,GB,IT,NL,PL,SE,UK"
+    "value": "AT,BE,DE,ES,CH,NL"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__SOFORT__CURRENCY",
-    "value": "EUR"
+    "value": "CHF,EUR"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__TRUSTLY__COUNTRY",
-    "value": "ES,UK,SE,NO,AT,NL,DE,DK,FI,EE,LT,LV"
+    "value": "ES,GB,SE,NO,AT,NL,DE,DK,FI,EE,LT,LV"
   },
   {
     "name": "ROUTER__PM_FILTERS__ADYEN__WE_CHAT_PAY__COUNTRY",
-    "value": "AU,NZ,CN,JP,HK,SG,ES,UK,SE,NO,AT,NL,DE,CY,CH,BE,FR,DK,LI,MT,SI,GR,PT,IT,CA,US"
+    "value": "AU,NZ,CN,JP,HK,SG,ES,GB,SE,NO,AT,NL,DE,CY,CH,BE,FR,DK,LI,MT,SI,GR,PT,IT,CA,US"
   },
+  {
+    "name": "ROUTER__PM_FILTERS__BANKOFAMERICA__APPLE_PAY__CURRENCY",
+    "value": "USD"
+  },
+  {
+    "name": "ROUTER__PM_FILTERS__BANKOFAMERICA__CREDIT__CURRENCY",
+    "value": "USD"
+  },
+  {
+    "name": "ROUTER__PM_FILTERS__BANKOFAMERICA__DEBIT__CURRENCY",
+    "value": "USD"
+  },
+  {
+    "name": "ROUTER__PM_FILTERS__BANKOFAMERICA__GOOGLE_PAY__CURRENCY",
+    "value": "USD"
+  },
   {
     "name": "ROUTER__PM_FILTERS__DEFAULT__AFTERPAY_CLEARPAY__COUNTRY",
-    "value": "AU,NZ,ES,UK,FR,IT,CA,US"
+    "value": "AU,NZ,ES,GB,FR,IT,CA,US"
   },
   {
     "name": "ROUTER__PM_FILTERS__DEFAULT__ALI_PAY__COUNTRY",
-    "value": "AU,N,JP,HK,SG,MY,TH,ES,UK,SE,NO,AT,NL,DE,CY,CH,BE,FR,DK,FI,RO,MT,SI,GR,PT,IE,IT,CA,US"
+    "value": "AU,JP,HK,SG,MY,TH,ES,GB,SE,NO,AT,NL,DE,CY,CH,BE,FR,DK,FI,RO,MT,SI,GR,PT,IE,IT,CA,US"
   },
   {
     "name": "ROUTER__PM_FILTERS__DEFAULT__BACS__COUNTRY",
-    "value": "UK"
+    "value": "GB"
   },
   {
     "name": "ROUTER__PM_FILTERS__DEFAULT__GOOGLE_PAY__COUNTRY",
-    "value": "AU,NZ,JP,HK,SG,MY,TH,VN,BH,AE,KW,BR,ES,UK,SE,NO,SK,AT,NL,DE,HU,CY,LU,CH,BE,FR,DK,RO,HR,LI,MT,SI,GR,PT,IE,CZ,EE,LT,LV,IT,PL,TR,IS,CA,US"
+    "value": "AU,NZ,JP,HK,SG,MY,TH,VN,BH,AE,KW,BR,ES,GB,SE,NO,SK,AT,NL,DE,HU,CY,LU,CH,BE,FR,DK,RO,HR,LI,MT,SI,GR,PT,IE,CZ,EE,LT,LV,IT,PL,TR,IS,CA,US"
   },
   {
     "name": "ROUTER__PM_FILTERS__DEFAULT__GOOGLE_PAY__CURRENCY",
-    "value": "AED,ALL,AMD,ANG,AOA,ARS,AUD,AWG,AZN,BAM,BBD,BDT,BGN,BHD,BMD,BND,BOB,BRL,BSD,BWP,BYN,BZD,CAD,CHF,CLP,CNY,COP,CRC,CUP,CVE,CZK,DJF,DKK,DOP,DZD,EGP,ETB,EUR,FJD,FKP,GBP,GEL,GHS,GIP,GMD,GNF,GTQ,GYD,HKD,HNL,HTG,HUF,IDR,ILS,INR,IQD,ISK,JMD,JOD,JPY,KES,KGS,KHR,KMF,KRW,KWD,KYD,KZT,LAK,LBP,LKR,LYD,MAD,MDL,MKD,MMK,MNT,MOP,MRU,MUR,MVR,MWK,MXN,MYR,MZN,NAD,NGN,NIO,NOK,NPR,NZD,OMR,PAB,PEN,PGK,PHP,PKR,PLN,PYG,QAR,RON,RSD,RUB,RWF,SAR,SBD,SCR,SEK,SGD,SHP,SLE,SOS,SRD,STN,SVC,SZL,THB,TND,TOP,TRY,TTD,TWD,TZS,UAH,UGX,USD,UYU,UZS,VEF,VND,VUV,WST,XAF,XCD,XOF,XPF,YER,ZAR,ZMW"
+    "value": "AED,ALL,AMD,ANG,AOA,ARS,AUD,AWG,AZN,BAM,BBD,BDT,BGN,BHD,BMD,BND,BOB,BRL,BSD,BWP,BYN,BZD,CAD,CHF,CLP,CNY,COP,CRC,CUP,CVE,CZK,DJF,DKK,DOP,DZD,EGP,ETB,EUR,FJD,FKP,GBP,GEL,GHS,GIP,GMD,GNF,GTQ,GYD,HKD,HNL,HTG,HUF,IDR,ILS,INR,IQD,JMD,JOD,JPY,KES,KGS,KHR,KMF,KRW,KWD,KYD,KZT,LAK,LBP,LKR,LYD,MAD,MDL,MKD,MMK,MNT,MOP,MRU,MUR,MVR,MWK,MXN,MYR,MZN,NAD,NGN,NIO,NOK,NPR,NZD,OMR,PAB,PEN,PGK,PHP,PKR,PLN,PYG,QAR,RON,RSD,RUB,RWF,SAR,SBD,SCR,SEK,SGD,SHP,SLE,SOS,SRD,STN,SVC,SZL,THB,TND,TOP,TRY,TTD,TWD,TZS,UAH,UGX,USD,UYU,UZS,VES,VND,VUV,WST,XAF,XCD,XOF,XPF,YER,ZAR,ZMW"
   },
   {
     "name": "ROUTER__PM_FILTERS__DEFAULT__KLARNA__COUNTRY",
-    "value": "AT,ES,UK,SE,NO,AT,NL,DE,CH,BE,FR,DK,FI,PT,IE,IT,PL,CA,US"
+    "value": "AT,ES,GB,SE,NO,AT,NL,DE,CH,BE,FR,DK,FI,PT,IE,IT,PL,CA,US"
   },
   {
     "name": "ROUTER__PM_FILTERS__DEFAULT__PAYPAL__COUNTRY",
-    "value": "AU,NZ,CN,JP,HK,MY,TH,KR,PH,ID,AE,KW,BR,ES,UK,SE,NO,SK,AT,NL,DE,HU,CY,LU,CH,BE,FR,DK,FI,RO,HR,UA,MT,SI,GI,PT,IE,CZ,EE,LT,LV,IT,PL,IS,CA,US"
+    "value": "AU,NZ,CN,JP,HK,MY,TH,KR,PH,ID,AE,KW,BR,ES,GB,SE,NO,SK,AT,NL,DE,HU,CY,LU,CH,BE,FR,DK,FI,RO,HR,UA,MT,SI,GI,PT,IE,CZ,EE,LT,LV,IT,PL,IS,CA,US"
   },
   {
     "name": "ROUTER__PM_FILTERS__DEFAULT__SOFORT__COUNTRY",
-    "value": "ES,UK,SE,AT,NL,DE,CH,BE,FR,FI,IT,PL"
+    "value": "ES,GB,SE,AT,NL,DE,CH,BE,FR,FI,IT,PL"
   },
   {
     "name": "ROUTER__PM_FILTERS__DEFAULT__TRUSTLY__COUNTRY",
-    "value": "ES,UK,SE,NO,AT,NL,DE,DK,FI,EE,LT,LV"
+    "value": "ES,GB,SE,NO,AT,NL,DE,DK,FI,EE,LT,LV"
   },
   {
     "name": "ROUTER__PM_FILTERS__DEFAULT__WE_CHAT_PAY__COUNTRY",
-    "value": "AU,NZ,CN,JP,HK,SG,ES,UK,SE,NO,AT,NL,DE,CY,CH,BE,FR,DK,LI,MT,SI,GR,PT,IT,CA,US"
+    "value": "AU,NZ,CN,JP,HK,SG,ES,GB,SE,NO,AT,NL,DE,CY,CH,BE,FR,DK,LI,MT,SI,GR,PT,IT,CA,US"
   },
+  {
+    "name": "ROUTER__PM_FILTERS__VOLT__OPEN_BANKING_UK__COUNTRY",
+    "value": "DE,GB,AT,BE,CY,EE,ES,FI,FR,GR,HR,IE,IT,LT,LU,LV,MT,NL,PT,SI,SK,BG,CZ,DK,HU,NO,PL,RO,SE,AU,BR"
+  },
+  {
+    "name": "ROUTER__PM_FILTERS__VOLT__OPEN_BANKING_UK__CURRENCY",
+    "value": "EUR,GBP,DKK,NOK,PLN,SEK,AUD,BRL"
+  },
+  {
+    "name": "ROUTER__REDIS__UNRESPONSIVE_TIMEOUT",
+    "value": "2"
+  },
+  {
+    "name": "ROUTER__TEMP_LOCKER_ENABLE_CONFIG__BANKOFAMERICA__PAYMENT_METHOD",
+    "value": "card"
+  },
+  {
+    "name": "ROUTER__TEMP_LOCKER_ENABLE_CONFIG__CYBERSOURCE__PAYMENT_METHOD",
+    "value": "card"
+  },
+  {
+    "name": "ROUTER__TEMP_LOCKER_ENABLE_CONFIG__NMI__PAYMENT_METHOD",
+    "value": "card"
+  },
+  {
+    "name": "ROUTER__TEMP_LOCKER_ENABLE_CONFIG__PAYME__PAYMENT_METHOD",
+    "value": "card"
+  },
+  {
+    "name": "ROUTER__TOKENIZATION__CHECKOUT__APPLE_PAY_PRE_DECRYPT_FLOW",
+    "value": "network_tokenization"
+  },
</pre>

<pre>
// Add these configuration variables and update these values
+  {
+    "name": "ROUTER__SECRETS__ADMIN_API_KEY",
+    "value": "YOUR_ADMIN_API_KEY" // Update this
+  },
+  {
+    "name": "ROUTER__SECRETS__JWT_SECRET",
+    "value": "YOUR_JWT_SECRET" // Update this
+  },
+  {
+    "name": "ROUTER__SECRETS__RECON_ADMIN_API_KEY",
+    "value": "YOUR_RECON_ADMIN_API_KEY" // Update this
+  },
</pre>

<pre>
// Remove if not using AWS KMS or AWS S3
+  {
+    "name": "ROUTER__ENCRYPTION_MANAGEMENT__AWS_KMS__KEY_ID",
+    "value": "YOUR_KMS_KEY_ID"
+  },
+  {
+    "name": "ROUTER__ENCRYPTION_MANAGEMENT__AWS_KMS__REGION",
+    "value": "YOUR_KMS_REGION"
+  },
+  {
+    "name": "ROUTER__ENCRYPTION_MANAGEMENT__ENCRYPTION_MANAGER",
+    "value": "aws_kms"
+  },
+  {
+    "name": "ROUTER__FILE_STORAGE__AWS_S3__BUCKET_NAME",
+    "value": "bucket"
+  },
+  {
+    "name": "ROUTER__FILE_STORAGE__AWS_S3__REGION",
+    "value": "us-east-1"
+  },
+  {
+    "name": "ROUTER__FILE_STORAGE__FILE_STORAGE_BACKEND",
+    "value": "aws_s3"
+  },
+  {
+    "name": "ROUTER__SECRETS_MANAGEMENT__AWS_KMS__KEY_ID",
+    "value": "YOUR_KMS_KEY_ID"
+  },
+  {
+    "name": "ROUTER__SECRETS_MANAGEMENT__AWS_KMS__REGION",
+    "value": "YOUR_KMS_REGION"
+  },
+  {
+    "name": "ROUTER__SECRETS_MANAGEMENT__SECRETS_MANAGER",
+    "value": "aws_kms"
+  },
</pre>
</details>

**Full Changelog:** [`v1.105.1...v1.107.0`](https://github.com/juspay/hyperswitch/compare/v1.105.1...v1.107.0)

### [Hyperswitch Control Center v1.29.9 (2024-03-12)](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.29.9)

We are excited to unveil version 1.29.9 of the Hyperswitch control center!
This release represents a major achievement in our ongoing efforts to deliver a
flexible, cutting-edge, and community-focused payment solution.

**Key Features**:

**Open Source Initiative:** Hyperswitch-control-center is now officially
completely open source!
All the features available in our cloud-hosted offering are now available in the
open-source version as well.
We're excited to invite the community to collaborate, contribute, and build upon
this foundation.
The entire source code is available on [github](https://github.com/juspay/hyperswitch-control-center).

#### New Features

- User Management Module:
  - Added ability to create custom roles [#473](https://github.com/juspay/hyperswitch-control-center/pull/473)
  - Added permissions and access control across the dashboard [#264](https://github.com/juspay/hyperswitch-control-center/pull/264)
  - Invite new users and accept invitation [#353](https://github.com/juspay/hyperswitch-control-center/pull/353)
  - Update roles of users and delete a user [#403](https://github.com/juspay/hyperswitch-control-center/pull/403)

#### Improvements

- Multiple UI / UX fixes and enhancements

#### Bugs Fixes

- Minor bug fixes in surcharge manager [#259](https://github.com/juspay/hyperswitch-control-center/pull/259)
- Code refactors for usability

### [Hyperswitch Web Client v0.27.2 (2024-03-06)](https://github.com/juspay/hyperswitch-web/releases/tag/v0.27.2)

#### Features

- Added metadata support for logs ([#88](https://github.com/juspay/hyperswitch-web/pull/88))
- Building before committing and added release rules ([#90](https://github.com/juspay/hyperswitch-web/pull/90))
- Added support of Dynamic Fields For Bancontact ([#72](https://github.com/juspay/hyperswitch-web/pull/72))
- Added Address Element ([#109](https://github.com/juspay/hyperswitch-web/pull/109))
- Added Surcharge for One Click Wallets ([#110](https://github.com/juspay/hyperswitch-web/pull/110))
- Dynamic fields support for IDeal, Sofort and Eps ([#125](https://github.com/juspay/hyperswitch-web/pull/125))
- Added Pix Bank Transfer ([#129](https://github.com/juspay/hyperswitch-web/pull/129))
- Added masked payload for confirm calls ([#148](https://github.com/juspay/hyperswitch-web/pull/148))
- Logging framework revamped ([#167](https://github.com/juspay/hyperswitch-web/pull/167))
- Language Support for Error Messages ([#173](https://github.com/juspay/hyperswitch-web/pull/173))
- moved Issues from Jira to Github ([#138](https://github.com/juspay/hyperswitch-web/pull/138))
- One click confirm handler ([#69](https://github.com/juspay/hyperswitch-web/pull/69))
- Added LOADER_CHANGED event on loader state update ([#178](https://github.com/juspay/hyperswitch-web/pull/178))
- paymentmethods: Boleto Payment Method Integration ([#195](https://github.com/juspay/hyperswitch-web/pull/195))

#### Refactors / Bug Fixes

- Created separate iframe for full screen ([#111](https://github.com/juspay/hyperswitch-web/pull/111))
- Added check on last name for Dynamic Fields ([#71](https://github.com/juspay/hyperswitch-web/pull/71))
- New Elements file without PreMountLoader ([#29](https://github.com/juspay/hyperswitch-web/pull/29))
- Added Dynamic Fields for Open Banking Uk ([#117](https://github.com/juspay/hyperswitch-web/pull/117))
- Fix multiple country dropdown ([#119](https://github.com/juspay/hyperswitch-web/pull/119))
- Fix empty/invalid country variant /confirm call ([#137](https://github.com/juspay/hyperswitch-web/pull/137))
- Fixed multiple re render ([#144](https://github.com/juspay/hyperswitch-web/pull/144))
- Missing address state ([#150](https://github.com/juspay/hyperswitch-web/pull/150))
- Added billing name to address element ([#145](https://github.com/juspay/hyperswitch-web/pull/145))
- Address line2 optional in case of isUseBillingAddress ([#174](https://github.com/juspay/hyperswitch-web/pull/174))
- animatedcheckbox: Save Card Details checkbox changes ([#184](https://github.com/juspay/hyperswitch-web/pull/184))
- intentCall: handling no response on confirm ([#203](https://github.com/juspay/hyperswitch-web/pull/203))

### [Hyperswitch WooCommerce Plugin v1.5.1 (2024-03-12)](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.5.1)

#### What's Changed

- Fix wordpress compatibility ([#3](https://github.com/juspay/hyperswitch-woocommerce-plugin/pull/3))
- HPOS compatibility+ ([#5](https://github.com/juspay/hyperswitch-woocommerce-plugin/pull/5))
- One click payment methods ([#6](https://github.com/juspay/hyperswitch-woocommerce-plugin/pull/6))
- Fixes for text internationalization ([#7](https://github.com/juspay/hyperswitch-woocommerce-plugin/pull/7))
- Internationalization fixes ([#8](https://github.com/juspay/hyperswitch-woocommerce-plugin/pull/8))

**Full Changelog:** [`v1.2.0...v1.5.1`](https://github.com/juspay/hyperswitch-woocommerce-plugin/compare/v1.2.0...v1.5.1)

### [Hyperswitch Card Vault v0.4.0 (2024-02-08)](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.4.0)

#### Features

- **benches:** Introduce benchmarks for internal components ([#53](https://github.com/juspay/hyperswitch-card-vault/pull/53))
- **caching:** Implement hash_table and merchant table caching ([#55](https://github.com/juspay/hyperswitch-card-vault/pull/55))
- **hashicorp-kv:** Add feature to extend key management service at runtime ([#65](https://github.com/juspay/hyperswitch-card-vault/pull/65))
- Add `duplication_check` field in stored card response([#59](https://github.com/juspay/hyperswitch-card-vault/pull/59))
- **hmac:** Add implementation for `hmac-sha512` ([#74](https://github.com/juspay/hyperswitch-card-vault/pull/74))
- **fingerprint:** Add fingerprint table and db interface ([#75](https://github.com/juspay/hyperswitch-card-vault/pull/75))
- **fingerprint:** Add api for fingerprint ([#76](https://github.com/juspay/hyperswitch-card-vault/pull/76))

#### Miscellaneous Tasks

- **deps:** Update axum `0.6.20` to `0.7.3` ([#66](https://github.com/juspay/hyperswitch-card-vault/pull/66))
- Fix caching issue for conditional merchant creation ([#68](https://github.com/juspay/hyperswitch-card-vault/pull/68))

**Full Changelog:** [`v0.2.0...v0.4.0`](https://github.com/juspay/hyperswitch-card-vault/compare/v0.2.0...v0.4.0)

## Hyperswitch Suite v1.0

### [Hyperswitch App Server v1.105.1 (2024-01-11)](https://github.com/juspay/hyperswitch/releases/tag/v1.105.1)

#### Docker Release

- [v1.105.1](https://hub.docker.com/layers/juspaydotin/hyperswitch-router/v1.105.1/images/sha256-a44cdd66633ae5003e3300d061119602ca62e8050427aef0c90707b75c242a33) (with KMS)
- [v1.105.1-standalone](https://hub.docker.com/layers/juspaydotin/hyperswitch-router/v1.105.1-standalone/images/sha256-96b7bfba7dae5f85bb6fac5d834a49d8c52a0f0d4e31167f6e2288048833316b) (without KMS)

#### New Features

- **connector:** [BankofAmerica] Implement support for Google Pay and Applepay ([#2940](https://github.com/juspay/hyperswitch/pull/2940), [#3061](https://github.com/juspay/hyperswitch/pull/3061))
- **connector:** [Cybersource] Implement support for Google Pay and Applepay ([#3139](https://github.com/juspay/hyperswitch/pull/3139), [#3149](https://github.com/juspay/hyperswitch/pull/3149))
- **connector:** [NMI] Implement 3DS for Cards and webhooks for payments and refunds ([#3143](https://github.com/juspay/hyperswitch/pull/3143), [#3164](https://github.com/juspay/hyperswitch/pull/3164))
- **connector:** [Paypal] Add Preprocessing flow to complete authorization for Card 3DS Auth Verification ([#2757](https://github.com/juspay/hyperswitch/pull/2757))
- **connector:** [Trustpay] Update dynamic fields for trustpay blik ([#3042](https://github.com/juspay/hyperswitch/pull/3042))
- **connector:** [BOA] Populate merchant_defined_information with metadata ([#3253](https://github.com/juspay/hyperswitch/pull/3253))
- Add support for Riskified FRM Connector ([#2533](https://github.com/juspay/hyperswitch/pull/2533))
- Add ability to verify connector credentials before integrating the connector ([#2986](https://github.com/juspay/hyperswitch/pull/2757))
- Enable surcharge support for all connectors ([#3109)](https://github.com/juspay/hyperswitch/pull/3109)
- Make core changes in payments flow to support incremental authorization ([#3009](https://github.com/juspay/hyperswitch/pull/3009))
- Add support for tokenizing bank details and fetching masked details while listing ([#2585](https://github.com/juspay/hyperswitch/pull/2585))
- Implement change password for user ([#2959](https://github.com/juspay/hyperswitch/pull/2959))
- Add support to filter payment link based on merchant_id ([#2805](https://github.com/juspay/hyperswitch/pull/2805))
- Add APIs for user roles ([#3013](https://github.com/juspay/hyperswitch/pull/3013) )
- Receive card_holder_name in confirm flow when using token for payment ([#2982](https://github.com/juspay/hyperswitch/pull/2982))
- payments: Add outgoing payments webhooks ([#3133](https://github.com/juspay/hyperswitch/pull/3133))
- Use card bin to get additional card details ([#3036](https://github.com/juspay/hyperswitch/pull/3036))
- Add support for passing card_cvc in payment_method_data object along with token ([#3024](https://github.com/juspay/hyperswitch/pull/3024))

#### Bug Fixes

- Accept connector_transaction_id in error_response of connector flows ([#2972](https://github.com/juspay/hyperswitch/pull/2972))
- Enable payment refund when payment is partially captured ([#2991](https://github.com/juspay/hyperswitch/pull/2991))
- Make the billing country for apple pay as optional field ([#3188](https://github.com/juspay/hyperswitch/pull/3188))
- Error propagation for not supporting partial refund ([#2976](https://github.com/juspay/hyperswitch/pull/2976))
- Mark refund status as failure for not_implemented error from connector flows ([#2978](https://github.com/juspay/hyperswitch/pull/2978))
- Allow zero amount for payment intent in list payment methods ([#3090](https://github.com/juspay/hyperswitch/pull/3090))
- Validate refund amount with amount_captured instead of amount ([#3120](https://github.com/juspay/hyperswitch/pull/3120))
- Make the card_holder_name as an empty string if not sent ([#3173](https://github.com/juspay/hyperswitch/pull/3173))

#### Database Migration

[Comparing v1.86.0..v1.105.1](https://github.com/juspay/hyperswitch/compare/v1.86.0..v1.105.1#diff-12ab8c82b7e89b1dd8185137f29664db1a8f6bad230114a53a3081d71c33034e)

### [Hyperswitch Control Center v1.23.3 (2024-01-11)](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.23.3)

We are excited to unveil version 1.23.3 of the Hyperswitch control center!
This release represents a major achievement in our ongoing efforts to deliver a
flexible, cutting-edge, and community-focused payment solution.

**Key Features:**

**Open Source Initiative:** Hyperswitch-control-center is now officially
completely open source!
All the features available in our cloud-hosted offering are now available in the
open-source version as well.
We're excited to invite the community to collaborate, contribute, and build upon
this foundation.
The entire source code is available on
[github](https://github.com/juspay/hyperswitch-control-center).

#### New Features

- Added more filters (payment method type, authentication type) to view payments by ([#160](https://github.com/juspay/hyperswitch-control-center/pull/160))
- Added evoucher flow for cashtocode ([#148](https://github.com/juspay/hyperswitch-control-center/pull/148))

#### Improvements

- Multiple UI fixes and enhancements ([#132](https://github.com/juspay/hyperswitch-control-center/pull/132), [#150](https://github.com/juspay/hyperswitch-control-center/pull/150))
- Switch merchant flow improvements ([#213](https://github.com/juspay/hyperswitch-control-center/pull/213))

#### Bug Fixes

- Rule based routing fix for configuration panel on profile change ([#236](https://github.com/juspay/hyperswitch-control-center/pull/236))
- Billing and shipping address mapping changes in payment details page ([#233](https://github.com/juspay/hyperswitch-control-center/pull/233))

### [Hyperswitch Web Client v0.16.7 (2024-01-11)](https://github.com/juspay/hyperswitch-web/releases/tag/v0.16.7)

#### SDK Demo Docker Release

[v1.0.10](https://hub.docker.com/layers/juspaydotin/hyperswitch-web/v1.0.10/images/sha256-ad7675111c562064c560c190d291cbe7053f05b5223c57b05edf8b40e24e3789)

We're thrilled to announce the release of Hyperswitch web version v0.16.7!
This marks a significant milestone in our journey toward providing a versatile,
innovative, and community-driven payment solution.

#### Key Features

**Open Source Initiative:** Hyperswitch-web is now officially completely open
source!
All the features available in our cloud-hosted offering are now available in the
open-source version as well.
We're excited to invite the community to collaborate, contribute, and build upon
this foundation.
The entire source code is available on
[github](https://github.com/juspay/hyperswitch-web).

#### New Features

- Added Evoucher Payment Method Type Redirection flow ([#73](https://github.com/juspay/hyperswitch-web/issues/73))

#### Improvements

- ApplePay Payment Request to take client's country in case session sends null ([#78](https://github.com/juspay/hyperswitch-web/issues/78))
- Added all billing details if any is empty ([#80](https://github.com/juspay/hyperswitch-web/issues/80))

#### Bugs Fixes

- Or Pay using fix for GooglePay and ApplePay ([#85](https://github.com/juspay/hyperswitch-web/issues/85))
- ApplePay button not rendering and orPayUsing not visible ([#84](https://github.com/juspay/hyperswitch-web/issues/84))

#### Deprecations

- Removed card token object from confirm for saved cards ([#76](https://github.com/juspay/hyperswitch-web/issues/76))

### [Hyperswitch WooCommerce Plugin v1.2.0 (2024-01-11)](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.2.0)

#### Key Features

**Open Source Initiative:** Hyperswitch-WooCommerce-Plugin is now officially
completely open source!
All the features available in our cloud-hosted offering are now available in the
open-source version as well.
We're excited to invite the community to collaborate, contribute, and build upon this foundation.

### [Hyperswitch Card Vault v0.2.0 (2023-12-26)](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.2.0)

### Features

- **router:** Use only card number for card duplication check ([#57](https://github.com/juspay/hyperswitch-card-vault/pull/57))

### Miscellaneous Tasks

- **deps:** Update version of aws dependencies ([#54](https://github.com/juspay/hyperswitch-card-vault/pull/54))
- **utils:**
  - Add jwe operations in utils binary ([#60](https://github.com/juspay/hyperswitch-card-vault/pull/60))
  - Fix jwe operations in utils binary ([#61](https://github.com/juspay/hyperswitch-card-vault/pull/61))

**Full Changelog:** [`v0.1.3...v0.2.0`](https://github.com/juspay/hyperswitch-card-vault/compare/v0.1.3...v0.2.0)
