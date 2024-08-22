# Changelog

All notable changes to Hyperswitch will be documented here.

## Hyperswitch Suite v1.4

### [Hyperswitch App Server v1.110.0 (2024-08-02)](https://github.com/juspay/hyperswitch/releases/tag/v1.110.0)

#### Docker Release

[v1.110.0](https://hub.docker.com/layers/juspaydotin/hyperswitch-router/v1.110.0/images/sha256-3f510235d509fca09935397c641c497d5f014513ffa4fb8214839c6b30869934) (with AWS SES support)

[v1.110.0-standalone](https://hub.docker.com/layers/juspaydotin/hyperswitch-router/v1.110.0-standalone/images/sha256-3af140233bea904f03f68305179aa341cccecc6d1016074224455f83267dd54b) (without AWS SES support)

### Features

- **connector:**
  - [BRAINTREE] Implement Card Mandates ([#5204](https://github.com/juspay/hyperswitch/pull/5204))
  - [RazorPay] Add new connector and Implement payment flows for UPI payment method ([#5200](https://github.com/juspay/hyperswitch/pull/5200))
  - [Bambora APAC] Add payment flows ([#5193](https://github.com/juspay/hyperswitch/pull/5193))
  - [DATATRANS] Implement card payments ([#5028](https://github.com/juspay/hyperswitch/pull/5028))
  - Plaid connector Integration ([#3952](https://github.com/juspay/hyperswitch/pull/3952))
  - [Itau Bank] Add payment and sync flow for Pix ([#5342](https://github.com/juspay/hyperswitch/pull/5342))
  - [Itaubank] Add refund and rsync flow ([#5420](https://github.com/juspay/hyperswitch/pull/5420))
  - [HELCIM] Move connector to hyperswitch_connectors ([#5287](https://github.com/juspay/hyperswitch/pull/5287))
- FRM Analytics ([#4880](https://github.com/juspay/hyperswitch/pull/4880))
- Customer_details storage in payment_intent ([#5007](https://github.com/juspay/hyperswitch/pull/5007))
- Added integrity framework for Authorize and Sync flow with connector as Stripe ([#5109](https://github.com/juspay/hyperswitch/pull/5109))
- Add merchant order reference id ([#5197](https://github.com/juspay/hyperswitch/pull/5197))
- Billing_details inclusion in Payment Intent ([#5090](https://github.com/juspay/hyperswitch/pull/5090))
- Constraint Graph for Payment Methods List ([#5081](https://github.com/juspay/hyperswitch/pull/5081))
- Add retrieve flow for payouts ([#4936](https://github.com/juspay/hyperswitch/pull/4936))
- Payments core modification for open banking connectors ([#3947](https://github.com/juspay/hyperswitch/pull/3947))
- Add support to register api keys to proxy ([#5168](https://github.com/juspay/hyperswitch/pull/5168))
- Add hashed customer_email and feature_metadata ([#5220](https://github.com/juspay/hyperswitch/pull/5220))
- Forward the tenant configuration as part of the kafka message ([#5224](https://github.com/juspay/hyperswitch/pull/5224))
- Implement tag-based filters in global search ([#5151](https://github.com/juspay/hyperswitch/pull/5151))
- Added search_tags based filter for global search in dashboard ([#5341](https://github.com/juspay/hyperswitch/pull/5341))
- Added recipient connector call for open banking connectors ([#3758](https://github.com/juspay/hyperswitch/pull/3758))
- Add multiple custom css support in business level ([#5137](https://github.com/juspay/hyperswitch/pull/5137))
- Add support to migrate existing customer PMs from processor to hyperswitch ([#5306](https://github.com/juspay/hyperswitch/pull/5306))
- Secure payout links using server side validations and client side headers ([#5219](https://github.com/juspay/hyperswitch/pull/5219))
- Add country, currency filters for payout methods ([#5130](https://github.com/juspay/hyperswitch/pull/5130))
- Added balance check for PM auth bank account ([#5054](https://github.com/juspay/hyperswitch/pull/5054))
- Add support to pass proxy bypass urls from configs ([#5322](https://github.com/juspay/hyperswitch/pull/5322))
- Add refunds manual-update api ([#5094](https://github.com/juspay/hyperswitch/pull/5094))
- Pass fields to indicate if the customer address details to be connector from wallets ([#5210](https://github.com/juspay/hyperswitch/pull/5210))
- Pass the shipping email whenever the billing details are included in the session token response ([#5228](https://github.com/juspay/hyperswitch/pull/5228))
- Add integrity check for refund refund sync and capture flow with stripe as connector ([#5187](https://github.com/juspay/hyperswitch/pull/5187))
- Add an api to migrate the payment method ([#5186](https://github.com/juspay/hyperswitch/pull/5186))
- Add support for passing the domain dynamically in the session call ([#5347](https://github.com/juspay/hyperswitch/pull/5347))
- Add support for https in actix web ([#5089](https://github.com/juspay/hyperswitch/pull/5089))
- Add support for custom outgoing webhook http headers ([#5275](https://github.com/juspay/hyperswitch/pull/5275))
- Create key in encryption service for merchant and user ([#4910](https://github.com/juspay/hyperswitch/pull/4910))
- Encryption service integration to support batch encryption and decryption ([#5164](https://github.com/juspay/hyperswitch/pull/5164))
- Add create retrieve and update api endpoints for organization resource ([#5361](https://github.com/juspay/hyperswitch/pull/5361))
- Create additional columns in organization table ([#5380](https://github.com/juspay/hyperswitch/pull/5380))
- Add env variable for enable key manager service ([#5465](https://github.com/juspay/hyperswitch/pull/5465))

### Refactors/Bug Fixes

- Add checks for duplicate `auth_method` in create API ([#5161](https://github.com/juspay/hyperswitch/pull/5161))
- Fetch customer id from customer object during MIT ([#5218](https://github.com/juspay/hyperswitch/pull/5218))
- [payouts] failure of payout retrieve when token is expired ([#5362](https://github.com/juspay/hyperswitch/pull/5362))
- Modified_at updated for every state change for Payment Attempts ([#5312](https://github.com/juspay/hyperswitch/pull/5312))
- Set `requires_cvv` to false when either `connector_mandate_details` or `network_transaction_id` is present during MITs ([#5331](https://github.com/juspay/hyperswitch/pull/5331))
- Save the `customer_id` in payments create ([#5262](https://github.com/juspay/hyperswitch/pull/5262))
- Add aliases on refund status for backwards compatibility ([#5216](https://github.com/juspay/hyperswitch/pull/5216))
- Mark retry payment as failure if `connector_tokenization` fails ([#5114](https://github.com/juspay/hyperswitch/pull/5114))
- Update last used when the customer acceptance is passed in the recurring payment ([#5116](https://github.com/juspay/hyperswitch/pull/5116))
- `override setup_future_usage` filed to on_session based on merchant config ([#5195](https://github.com/juspay/hyperswitch/pull/5195))
- Fail refund with bad request error for duplicate refund_id in refunds create flow ([#5282](https://github.com/juspay/hyperswitch/pull/5282))
- Fixed integrity check failures in case of 3ds flow in sync flow ([#5279](https://github.com/juspay/hyperswitch/pull/5279))
- Store `customer_acceptance` in payment_attempt, use it in confirm flow for delayed authorizations like external 3ds flow ([#5308](https://github.com/juspay/hyperswitch/pull/5308))
- Store `network_transaction_id` in stripe `authorize` flow ([#5399](https://github.com/juspay/hyperswitch/pull/5399))
- Do not update `perform_session_flow_routing` output if the `SessionRoutingChoice` is none ([#5336](https://github.com/juspay/hyperswitch/pull/5336))
- Make id option in auth select ([#5213](https://github.com/juspay/hyperswitch/pull/5213))
- Clear cookie and alter parsing for sso ([#5147](https://github.com/juspay/hyperswitch/pull/5147))
- Add offset and limit to key transfer API ([#5358](https://github.com/juspay/hyperswitch/pull/5358))
- [Mifinity] fix redirection after payment completion and handle 5xx error ([#5250](https://github.com/juspay/hyperswitch/pull/5250))
- [Mifinity] add a field language_preference in payment request for mifinity payment method data ([#5326](https://github.com/juspay/hyperswitch/pull/5326))
- [Itaubank] add dynamic fields for pix ([#5419](https://github.com/juspay/hyperswitch/pull/5419))
- [boa/cybs] add billing address to MIT request ([#5068](https://github.com/juspay/hyperswitch/pull/5068))
- Change primary key of refund table ([#5367](https://github.com/juspay/hyperswitch/pull/5367))
- Change primary keys in user, user_roles and roles tables ([#5374](https://github.com/juspay/hyperswitch/pull/5374))
- Change primary keys in payment_methods table ([#5393](https://github.com/juspay/hyperswitch/pull/5393))
- Removal of lifetime from the Constraint Graph framework ([#5132](https://github.com/juspay/hyperswitch/pull/5132))
- Update helper functions for deciding whether or not to consume flows based on current status ([#5248](https://github.com/juspay/hyperswitch/pull/5248))
- Changed payment method token TTL to api contract based config from const value ([#5115](https://github.com/juspay/hyperswitch/pull/5115))
- Remove the locker call in the psync flow ([#5348](https://github.com/juspay/hyperswitch/pull/5348))
- Remove id dependency from merchant connector account, dispute and mandate ([#5330](https://github.com/juspay/hyperswitch/pull/5330))
- Use hashmap deserializer for generic_link options ([#5157](https://github.com/juspay/hyperswitch/pull/5157))
- Adding millisecond to Kafka timestamp ([#5202](https://github.com/juspay/hyperswitch/pull/5202))

### Compatibility

This version of the Hyperswitch App server is compatible with the following versions of other components:

- Control Center Version: [v1.32.0](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.32.0)
- Web Client Version: [v0.80.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.80.0)
- WooCommerce Plugin Version: [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1)
- Card Vault Version: [v0.4.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.4.0)
- Key Manager: [V0.1.3](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.3)

### Database Migrations

```sql
---DB Difference between v1.109.0 AND v1.110.0
-- Your SQL goes here
ALTER TABLE merchant_connector_account ADD COLUMN IF NOT EXISTS additional_merchant_data BYTEA DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE payment_intent ADD COLUMN IF NOT EXISTS customer_details BYTEA DEFAULT NULL;
-- Your SQL goes here

ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS collect_billing_details_from_wallet_connector BOOLEAN DEFAULT FALSE;
-- Your SQL goes here
ALTER TABLE payment_intent ADD COLUMN IF NOT EXISTS billing_details BYTEA DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE payment_intent ADD COLUMN IF NOT EXISTS merchant_order_reference_id VARCHAR(255) DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE payment_intent ADD COLUMN IF NOT EXISTS shipping_details BYTEA DEFAULT NULL;
ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS outgoing_webhook_custom_http_headers BYTEA DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE payment_attempt ADD COLUMN IF NOT EXISTS customer_acceptance JSONB DEFAULT NULL;
-- Your SQL goes here
-- The below query will lock the merchant account table
-- Running this query is not necessary on higher environments
-- as the application will work fine without these queries being run
-- This query is necessary for the application to not use id in update of merchant_account
-- This query should be run after the new version of application is deployed
ALTER TABLE merchant_account DROP CONSTRAINT merchant_account_pkey;

-- Use the `merchant_id` column as primary key
-- This is already a unique, not null column
-- So this query should not fail for not null or duplicate values reasons
ALTER TABLE merchant_account
ADD PRIMARY KEY (merchant_id);
-- Your SQL goes here
-- The below query will lock the dispute table
-- Running this query is not necessary on higher environments
-- as the application will work fine without these queries being run
-- This query is necessary for the application to not use id in update of dispute
-- This query should be run only after the new version of application is deployed
ALTER TABLE dispute DROP CONSTRAINT dispute_pkey;

-- Use the `dispute_id` column as primary key
ALTER TABLE dispute
ADD PRIMARY KEY (dispute_id);
-- Your SQL goes here
-- The below query will lock the mandate table
-- Running this query is not necessary on higher environments
-- as the application will work fine without these queries being run
-- This query is necessary for the application to not use id in update of mandate
-- This query should be run only after the new version of application is deployed
ALTER TABLE mandate DROP CONSTRAINT mandate_pkey;

-- Use the `mandate_id` column as primary key
ALTER TABLE mandate
ADD PRIMARY KEY (mandate_id);
-- Your SQL goes here
-- The below query will lock the merchant connector account table
-- Running this query is not necessary on higher environments
-- as the application will work fine without these queries being run
-- This query should be run only after the new version of application is deployed
ALTER TABLE merchant_connector_account DROP CONSTRAINT merchant_connector_account_pkey;

-- Use the `merchant_connector_id` column as primary key
-- This is not a unique column, but in an ideal scenario there should not be any duplicate keys as this is being generated by the application
-- So this query should not fail for not null or duplicate values reasons
ALTER TABLE merchant_connector_account
ADD PRIMARY KEY (merchant_connector_id);
UPDATE generic_link
SET link_data = jsonb_set(link_data, '{allowed_domains}', '["*"]'::jsonb)
WHERE
    NOT link_data ? 'allowed_domains'
    AND link_type = 'payout_link';
-- Your SQL goes here
-- The below query will lock the blocklist table
-- Running this query is not necessary on higher environments
-- as the application will work fine without these queries being run
-- This query should be run after the new version of application is deployed
ALTER TABLE blocklist DROP CONSTRAINT blocklist_pkey;

-- Use the `merchant_id, fingerprint_id` columns as primary key
-- These are already unique, not null columns
-- So this query should not fail for not null or duplicate value reasons
ALTER TABLE blocklist
ADD PRIMARY KEY (merchant_id, fingerprint_id);
-- Your SQL goes here
ALTER TABLE organization
ADD COLUMN organization_details jsonb,
ADD COLUMN metadata jsonb,
ADD created_at TIMESTAMP NOT NULL DEFAULT now()::TIMESTAMP,
ADD modified_at TIMESTAMP NOT NULL DEFAULT now()::TIMESTAMP;
-- Your SQL goes here
-- The below query will lock the refund table
-- Running this query is not necessary on higher environments
-- as the application will work fine without these queries being run
-- This query should be run after the new version of application is deployed
ALTER TABLE refund DROP CONSTRAINT refund_pkey;

-- Use the `merchant_id, refund_id` columns as primary key
-- These are already unique, not null columns
-- So this query should not fail for not null or duplicate value reasons
ALTER TABLE refund
ADD PRIMARY KEY (merchant_id, refund_id);
-- Your SQL goes here
-- The below query will lock the users table
-- Running this query is not necessary on higher environments
-- as the application will work fine without these queries being run
-- This query should be run after the new version of application is deployed
ALTER TABLE users DROP CONSTRAINT users_pkey;

-- Use the `user_id` columns as primary key
-- These are already unique, not null column
-- So this query should not fail for not null or duplicate value reasons
ALTER TABLE users
ADD PRIMARY KEY (user_id);
-- Your SQL goes here
-- The below query will lock the user_roles table
-- Running this query is not necessary on higher environments
-- as the application will work fine without these queries being run
-- This query should be run after the new version of application is deployed
ALTER TABLE user_roles DROP CONSTRAINT user_roles_pkey;

-- Use the `user_id, merchant_id` columns as primary key
-- These are already unique, not null columns
-- So this query should not fail for not null or duplicate value reasons
ALTER TABLE user_roles
ADD PRIMARY KEY (user_id, merchant_id);
-- Your SQL goes here
-- The below query will lock the user_roles table
-- Running this query is not necessary on higher environments
-- as the application will work fine without these queries being run
-- This query should be run after the new version of application is deployed
ALTER TABLE roles DROP CONSTRAINT roles_pkey;

-- Use the `role_id` column as primary key
-- These are already unique, not null column
-- So this query should not fail for not null or duplicate value reasons
ALTER TABLE roles
ADD PRIMARY KEY (role_id);
-- Your SQL goes here
-- The below query will lock the payment_methods table
-- Running this query is not necessary on higher environments
-- as the application will work fine without these queries being run
-- This query should be run after the new version of application is deployed
ALTER TABLE payment_methods DROP CONSTRAINT payment_methods_pkey;

-- Use the `payment_method_id` column as primary key
-- This is already unique, not null column
-- So this query should not fail for not null or duplicate value reasons
ALTER TABLE payment_methods
ADD PRIMARY KEY (payment_method_id);
-- Your SQL goes here
-- The below query will lock the user_roles table
-- Running this query is not necessary on higher environments
-- as the application will work fine without these queries being run
-- This query should be run after the new version of application is deployed
ALTER TABLE user_roles DROP CONSTRAINT user_roles_pkey;
-- Use the `id` column as primary key
-- This is serial and a not null column
-- So this query should not fail for not null or duplicate value reasons
ALTER TABLE user_roles ADD PRIMARY KEY (id);

ALTER TABLE user_roles ALTER COLUMN org_id DROP NOT NULL;
ALTER TABLE user_roles ALTER COLUMN merchant_id DROP NOT NULL;

ALTER TABLE user_roles ADD COLUMN profile_id VARCHAR(64);
ALTER TABLE user_roles ADD COLUMN entity_id VARCHAR(64);
ALTER TABLE user_roles ADD COLUMN entity_type VARCHAR(64);

CREATE TYPE "UserRoleVersion" AS ENUM('v1', 'v2');
ALTER TABLE user_roles ADD COLUMN version "UserRoleVersion" DEFAULT 'v1' NOT NULL;
```

### Configuration Changes

Diff of configuration changes between <code>v1.109.0</code> and <code>v1.110.0</code>

```patch
diff --git a/config/deployments/sandbox.toml b/config/deployments/sandbox.toml
index 040986f79..5fb7bfe0d 100644
--- a/config/deployments/sandbox.toml
+++ b/config/deployments/sandbox.toml
@@ -30,6 +30,7 @@ airwallex.base_url = "https://api-demo.airwallex.com/"
 applepay.base_url = "https://apple-pay-gateway.apple.com/"
 authorizedotnet.base_url = "https://apitest.authorize.net/xml/v1/request.api"
 bambora.base_url = "https://api.na.bambora.com"
+bamboraapac.base_url = "https://demo.ippayments.com.au/interface/api/dts.asmx"
 bankofamerica.base_url = "https://apitest.merchant-services.bankofamerica.com/"
 billwerk.base_url = "https://api.reepay.com/"
 billwerk.secondary_base_url = "https://card.reepay.com/"
@@ -56,6 +57,7 @@ gocardless.base_url = "https://api-sandbox.gocardless.com"
 gpayments.base_url = "https://{{merchant_endpoint_prefix}}-test.api.as1.gpayments.net"
 helcim.base_url = "https://api.helcim.com/"
 iatapay.base_url = "https://sandbox.iata-pay.iata.org/api/v1"
+itaubank.base_url = "https://sandbox.devportal.itau.com.br/"
 klarna.base_url = "https://api{{klarna_region}}.playground.klarna.com/"
 mifinity.base_url = "https://demo.mifinity.com/"
 mollie.base_url = "https://api.mollie.com/v2/"
@@ -74,9 +76,11 @@ payone.base_url = "https://payment.preprod.payone.com/"
 paypal.base_url = "https://api-m.sandbox.paypal.com/"
 payu.base_url = "https://secure.snd.payu.com/"
 placetopay.base_url = "https://test.placetopay.com/rest/gateway"
+plaid.base_url = "https://sandbox.plaid.com"
 powertranz.base_url = "https://staging.ptranz.com/api/"
 prophetpay.base_url = "https://ccm-thirdparty.cps.golf/"
 rapyd.base_url = "https://sandboxapi.rapyd.net"
+razorpay.base_url = "https://sandbox.juspay.in/"
 riskified.base_url = "https://sandbox.riskified.com/api"
 shift4.base_url = "https://api.shift4.com/"
 signifyd.base_url = "https://api.signifyd.com/"
@@ -89,6 +93,7 @@ trustpay.base_url = "https://test-tpgw.trustpay.eu/"
 trustpay.base_url_bank_redirects = "https://aapi.trustpay.eu/"
 tsys.base_url = "https://stagegw.transnox.com/"
 volt.base_url = "https://api.sandbox.volt.io/"
+wellsfargo.base_url = "https://apitest.cybersource.com/"
 wise.base_url = "https://api.sandbox.transferwise.tech/"
 worldline.base_url = "https://eu.sandbox.api-ingenico.com/"
 worldpay.base_url = "https://try.access.worldpay.com/"
@@ -131,11 +136,12 @@ base_url = "https://app.hyperswitch.io"
 enabled = true

 [mandates.supported_payment_methods]
-bank_debit.ach.connector_list = "gocardless"
+bank_debit.ach = { connector_list = "gocardless,adyen" }
 bank_debit.becs.connector_list = "gocardless"
+bank_debit.bacs = { connector_list = "adyen" }
-bank_debit.sepa.connector_list = "gocardless"
-card.credit.connector_list = "stripe,adyen,authorizedotnet,cybersource,globalpay,worldpay,multisafepay,nmi,nexinets,noon,bankofamerica"
-card.debit.connector_list = "stripe,adyen,authorizedotnet,cybersource,globalpay,worldpay,multisafepay,nmi,nexinets,noon,bankofamerica"
+bank_debit.sepa = { connector_list = "gocardless,adyen" }
+card.credit.connector_list = "stripe,adyen,authorizedotnet,cybersource,globalpay,worldpay,multisafepay,nmi,nexinets,noon,bankofamerica,braintree"
+card.debit.connector_list = "stripe,adyen,authorizedotnet,cybersource,globalpay,worldpay,multisafepay,nmi,nexinets,noon,bankofamerica,braintree"
 pay_later.klarna.connector_list = "adyen"
 wallet.apple_pay.connector_list = "stripe,adyen,cybersource,noon,bankofamerica"
 wallet.google_pay.connector_list = "stripe,adyen,cybersource,bankofamerica"
@@ -309,6 +315,12 @@ sofort = { country = "AT,BE,DE,IT,NL,ES", currency = "EUR" }
 [pm_filters.volt]
 open_banking_uk = { country = "DE,GB,AT,BE,CY,EE,ES,FI,FR,GR,HR,IE,IT,LT,LU,LV,MT,NL,PT,SI,SK,BG,CZ,DK,HU,NO,PL,RO,SE,AU,BR", currency = "EUR,GBP,DKK,NOK,PLN,SEK,AUD,BRL" }

+[pm_filters.razorpay]
+upi_collect = {country = "IN", currency = "INR"}
+
+[pm_filters.plaid]
+open_banking_pis = {currency = "EUR,GBP"}
+
 [pm_filters.worldpay]
 apple_pay.country = "AU,CN,HK,JP,MO,MY,NZ,SG,TW,AM,AT,AZ,BY,BE,BG,HR,CY,CZ,DK,EE,FO,FI,FR,GE,DE,GR,GL,GG,HU,IS,IE,IM,IT,KZ,JE,LV,LI,LT,LU,MT,MD,MC,ME,NL,NO,PL,PT,RO,SM,RS,SK,SI,ES,SE,CH,UA,GB,AR,CO,CR,BR,MX,PE,BH,IL,JO,KW,PS,QA,SA,AE,CA,UM,US"
 google_pay.country = "AL,DZ,AS,AO,AG,AR,AU,AT,AZ,BH,BY,BE,BR,BG,CA,CL,CO,HR,CZ,DK,DO,EG,EE,FI,FR,DE,GR,HK,HU,IN,ID,IE,IL,IT,JP,JO,KZ,KE,KW,LV,LB,LT,LU,MY,MX,NL,NZ,NO,OM,PK,PA,PE,PH,PL,PT,QA,RO,RU,SA,SG,SK,ZA,ES,LK,SE,CH,TW,TH,TR,UA,AE,GB,US,UY,VN"
@@ -326,6 +338,12 @@ red_pagos = { country = "UY", currency = "UYU" }
 [pm_filters.zsl]
 local_bank_transfer = { country = "CN", currency = "CNY" }

+[payout_method_filters.adyenplatform]
+sepa = { country = "ES,SK,AT,NL,DE,BE,FR,FI,PT,IE,EE,LT,LV,IT,CZ,DE,HU,NO,PL,SE,GB,CH" , currency = "EUR,CZK,DKK,HUF,NOK,PLN,SEK,GBP,CHF" }
+
+[payout_method_filters.stripe]
+ach = { country = "US", currency = "USD" }
+
 [temp_locker_enable_config]
 bluesnap.payment_method = "card"
 nuvei.payment_method = "card"
@@ -359,3 +377,6 @@ keys = "user-agent"

 [saved_payment_methods]
 sdk_eligible_payment_methods = "card"
+
+[locker_based_open_banking_connectors]
+connector_list = ""

```

```patch
diff --git a/config/deployments/env_specific.toml b/config/deployments/env_specific.toml
index 68df3d28e..a7bd116a3 100644
--- a/config/deployments/env_specific.toml
+++ b/config/deployments/env_specific.toml
@@ -82,6 +82,7 @@ audit_events_topic = "topic"               # Kafka topic to be used for Payment
 payout_analytics_topic = "topic"         # Kafka topic to be used for Payouts and PayoutAttempt events
 consolidated_events_topic = "topic"      # Kafka topic to be used for Consolidated events
 authentication_analytics_topic = "topic" # Kafka topic to be used for Authentication events
+fraud_check_analytics_topic = "topic"    # Kafka topic to be used for Fraud Check events

 # File storage configuration
 [file_storage]
@@ -165,9 +166,9 @@ theme = "#4285F4"
 logo = "https://app.hyperswitch.io/HyperswitchFavicon.png"
 merchant_name = "HyperSwitch"
 [generic_link.payment_method_collect.enabled_payment_methods]
-card = ["credit", "debit"]
-bank_transfer = ["ach", "bacs", "sepa"]
-wallet = ["paypal", "pix", "venmo"]
+card = "credit,debit"
+bank_transfer = "ach,bacs,sepa"
+wallet = "paypal,pix,venmo"

 [generic_link.payout_link]
 sdk_url = "http://localhost:9090/0.16.7/v0/HyperLoader.js"
@@ -177,9 +178,7 @@ theme = "#4285F4"
 logo = "https://app.hyperswitch.io/HyperswitchFavicon.png"
 merchant_name = "HyperSwitch"
 [generic_link.payout_link.enabled_payment_methods]
-card = ["credit", "debit"]
-bank_transfer = ["ach", "bacs", "sepa"]
-wallet = ["paypal", "pix", "venmo"]
+card = "credit,debit"

 [payment_link]
 sdk_url = "http://localhost:9090/0.16.7/v0/HyperLoader.js"
@@ -191,6 +190,7 @@ redis_expiry = 900          # Redis expiry time in milliseconds
 [proxy]
 http_url = "http://proxy_http_url"    # Outgoing proxy http URL to proxy the HTTP traffic
 https_url = "https://proxy_https_url" # Outgoing proxy https URL to proxy the HTTPS traffic
+bypass_proxy_urls = []                # A list of URLs that should bypass the proxy

 # Redis credentials
 [redis]
@@ -247,6 +247,10 @@ payment_intents = "hyperswitch-payment-intent-events"
 refunds = "hyperswitch-refund-events"
 disputes = "hyperswitch-dispute-events"

+# Configuration for the Key Manager Service
+[key_manager]
+url = "http://localhost:5000" # URL of the encryption service
+
 # This section provides some secret values.
 [secrets]
 master_enc_key = "sample_key"            # Master Encryption key used to encrypt merchant wise encryption key. Should be 32-byte long.
@@ -265,6 +269,14 @@ shutdown_timeout = 30
 # HTTP Request body limit. Defaults to 32kB
 request_body_limit = 32_768

+# HTTPS Server Configuration
+# Self-signed Private Key and Certificate can be generated with mkcert for local development
+[server.tls]
+port = 8081
+host = "127.0.0.1"
+private_key = "/path/to/private_key.pem"
+certificate = "/path/to/certificate.pem"
+
 [secrets_management]
 secrets_manager = "aws_kms" # Secrets manager client to be used

@@ -281,10 +293,10 @@ region = "kms_region" # The AWS region used by the KMS SDK for decrypting data.

 [multitenancy]
 enabled = false
-global_tenant = { schema = "public", redis_key_prefix = "" }
+global_tenant = { schema = "public", redis_key_prefix = "", clickhouse_database = "default"}

 [multitenancy.tenants]
-public = { name = "hyperswitch", base_url = "http://localhost:8080", schema = "public", redis_key_prefix = "", clickhouse_database = "default"}
+public = { name = "hyperswitch", base_url = "http://localhost:8080", schema = "public", redis_key_prefix = "", clickhouse_database = "default" }

 [user_auth_methods]
 encryption_key = "user_auth_table_encryption_key" # Encryption key used for encrypting data in user_authentication_methods table

```

**Full Changelog:** [`v1.109.0...v1.110.0`](https://github.com/juspay/hyperswitch/compare/v1.109.0...v1.110.0)

### [Hyperswitch Control Center v1.32.0 (2024-07-02)](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.32.0)

**Product Name**: [Hyperswitch-control-center](https://github.com/juspay/hyperswitch-control-center)
**Version**: [v1.32.0](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.32.0)
**Release Date**: 02-07-2024
We are excited to release the latest version of the Hyperswitch control center! This release represents yet another achievement in our ongoing efforts to deliver a flexible, cutting-edge, and community-focused payment solution.
**Features**

- Add field to collect shipping details ([#783](https://github.com/juspay/hyperswitch-control-center/pull/783))
- Allow user to select apple pay label ([#852](https://github.com/juspay/hyperswitch-control-center/pull/852))
- Showing all payment method types in filters ([#841](https://github.com/juspay/hyperswitch-control-center/pull/841))
- SSO integration in dashboard ([#870](https://github.com/juspay/hyperswitch-control-center/pull/870))
- Enable custom Login methods ([#849](https://github.com/juspay/hyperswitch-control-center/pull/849)) ([#858](https://github.com/juspay/hyperswitch-control-center/pull/858)) ([#878](https://github.com/juspay/hyperswitch-control-center/pull/878)) ([#881](https://github.com/juspay/hyperswitch-control-center/pull/881))
- Payment logs ui changes ([#883](https://github.com/juspay/hyperswitch-control-center/pull/883))
- Realtime user analytics ([#872](https://github.com/juspay/hyperswitch-control-center/pull/872))
- Webhooks multi request support ([#890](https://github.com/juspay/hyperswitch-control-center/pull/890))
- Added Razorpay connectors ([#951](https://github.com/juspay/hyperswitch-control-center/pull/951))
- Global search customer email search support ([#964](https://github.com/juspay/hyperswitch-control-center/pull/964))
- Added inform about currency denomination in routing ([#997](https://github.com/juspay/hyperswitch-control-center/pull/997))
- Added attempts count column in payment list table ([#1002](https://github.com/juspay/hyperswitch-control-center/pull/1002))
- Added active payments counter ([#998](https://github.com/juspay/hyperswitch-control-center/pull/998))
- Added itaubank connector ([#1042](https://github.com/juspay/hyperswitch-control-center/pull/1042))
  **Enhancement**
- Common filter for payment analytics page ([#963](https://github.com/juspay/hyperswitch-control-center/pull/963))
- Moved delete all sample data from account settings ([#1034](https://github.com/juspay/hyperswitch-control-center/pull/1034))

#### Compatibility

This version of the Hyperswitch App server is compatible with the following versions of other components:

- App Server Version: [v1.110.0](https://github.com/juspay/hyperswitch/releases/tag/v1.110.0)
- Web Client Version: [v0.80.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.80.0)
- WooCommerce Plugin Version: [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1)
- Card Vault Version: [v0.4.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.4.0)
  **Full Changelog**: https://github.com/juspay/hyperswitch-control-center/compare/v1.30.1...v1.31.0

### [Hyperswitch Web Client v0.80.00 (2024-07-02)](https://github.com/juspay/hyperswitch-web/releases/tag/v0.80.0)

#### What's Changed

- feat: pm auth connector integration - Plaid by @PritishBudhiraja in ([#461](https://github.com/juspay/hyperswitch-web/pull/461))
- fix: fixed netcetra 3ds not opening and added fallback log by @ArushKapoorJuspay in ([#470](https://github.com/juspay/hyperswitch-web/pull/470))
- fix: info element added & logs addition by @PritishBudhiraja in ([#471](https://github.com/juspay/hyperswitch-web/pull/471))
- fix: payment data filled event logs for few payment methods by @vsrivatsa-edinburgh in ([#467](https://github.com/juspay/hyperswitch-web/pull/467))
- fix: passing customer acceptance if recurring_enabled is false in saved methods list by @ArushKapoorJuspay in ([#476](https://github.com/juspay/hyperswitch-web/pull/476))
- feat: payment-management added by @sakksham7 in ([#392](https://github.com/juspay/hyperswitch-web/pull/392))
- refactor: refactored lazy loading by @ArushKapoorJuspay in ([#484](https://github.com/juspay/hyperswitch-web/pull/484))
- fix: date of birth validations by @PritishBudhiraja in ([#480](https://github.com/juspay/hyperswitch-web/pull/480))
- feat: added upi collect payment method type by @ArushKapoorJuspay in ([#491](https://github.com/juspay/hyperswitch-web/pull/491))
- fix: premount loader fix by @PritishBudhiraja in ([#492](https://github.com/juspay/hyperswitch-web/pull/492))
- feat(payout-link): add input validations for payment methods in CollectWidget by @kashif-m in ([#460](https://github.com/juspay/hyperswitch-web/pull/460))
- feat: language preference for mifinity added by @sakksham7 in ([#502](https://github.com/juspay/hyperswitch-web/pull/502))
- feat: passing X-Merchant-Domain in the headers for Sessions Call by @ArushKapoorJuspay in ([#504](https://github.com/juspay/hyperswitch-web/pull/504))
- fix: customer acceptance issue for bank debits by @PritishBudhiraja in ([#516](https://github.com/juspay/hyperswitch-web/pull/516))
- feat: pix-ItauBank api contract changes by @sakksham7 in ([#527](https://github.com/juspay/hyperswitch-web/pull/527))
- fix: pix confirm call and added locale support by @sakksham7 in ([#528](https://github.com/juspay/hyperswitch-web/pull/528))
- feat(payout): add localisation for payout widget by @kashif-m in ([#520](https://github.com/juspay/hyperswitch-web/pull/520))
- feat: added support for collecting_billing_details_from_wallets by @ArushKapoorJuspay in ([#529](https://github.com/juspay/hyperswitch-web/pull/529))

**Full Changelog**: https://github.com/juspay/hyperswitch-web/compare/v0.71.11...v0.80.0

#### Compatibility

This version of the Hyperswitch App server is compatible with the following versions of other components:

- App server Version: [v1.110.0](https://github.com/juspay/hyperswitch/releases/tag/v1.110.0)
- Control Center Version: [v1.32.0](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.32.0)
- WooCommerce Plugin Version: [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1)
- Card Vault Version: [v0.4.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.4.0)

### [Hyperswitch Encryption Client v0.1.3 (2024-07-02)](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.3)

#### What's Changed

- fix: add proper messages to internal server error by @draca ([#20](https://github.com/juspay/hyperswitch-encryption-service/pull/20)

**Full Changelog**: https://github.com/juspay/hyperswitch-encryption-service/compare/v0.1.0...v0.1.3

## Hyperswitch Suite v1.3

### [Hyperswitch App Server v1.109.0 (2024-07-05)](https://github.com/juspay/hyperswitch/releases/tag/v1.109.0)

#### Docker Release

- [v1.109.0](https://hub.docker.com/layers/juspaydotin/hyperswitch-router/v1.109.0/images/sha256-d34751c7c2adad87b3c2f858899f3394f6c92ec9c7216ae5d984ecfdb5df83d7) (with AWS SES support)
- [v1.109.0-standalone](https://hub.docker.com/layers/juspaydotin/hyperswitch-router/v1.109.0-standalone/images/sha256-b768c3b4ec1742d88aa23a2fa315e4515d8c7320fec1be295a357c561a49955b) (without AWS SES support)

#### Features

- **connector:**
  - [Stripe] - Stripe connect integration for payouts ([#2041](https://github.com/juspay/hyperswitch/pull/2041))
  - [Ebanx] Add payout flows ([#4146](https://github.com/juspay/hyperswitch/pull/4146))
  - [Paypal] Add payout flow for wallet(Paypal and Venmo) ([#4406](https://github.com/juspay/hyperswitch/pull/4406))
  - [Cybersource] Add payout flows for Card ([#4511](https://github.com/juspay/hyperswitch/pull/4511))
  - [AUTHORIZEDOTNET] Implement zero mandates ([#4704](https://github.com/juspay/hyperswitch/pull/4704))
  - [AUTHORIZEDOTNET] Implement non-zero mandates ([#4758](https://github.com/juspay/hyperswitch/pull/4758))
  - [Iatapay] add upi qr support ([#4728](https://github.com/juspay/hyperswitch/pull/4728))
  - [Cybersource] Add support for external authentication for cybersource ([#4714](https://github.com/juspay/hyperswitch/pull/4714))
  - [Klarna] Add support for Capture, Psync, Refunds and Rsync flows ([#4799](https://github.com/juspay/hyperswitch/pull/4799))
  - [Adyen] Add payouts integration for AdyenPlatform ([#4874](https://github.com/juspay/hyperswitch/pull/4874))
  - [MIFINITY] Implement payment flows and Mifinity payment method ([#4592](https://github.com/juspay/hyperswitch/pull/4592))
  - [BOA/CYB] Make state,zip optional for Non US CA Txns ([#4915](https://github.com/juspay/hyperswitch/pull/4915))
  - [Multisafepay] Add support for Ideal and Giropay ([#4398](https://github.com/juspay/hyperswitch/pull/4398))
  - [GPayments] Implement auth and post auth flows for gpayments ([#4746](https://github.com/juspay/hyperswitch/pull/4746))
  - [Iatapay] add payment methods ([#4968](https://github.com/juspay/hyperswitch/pull/4968))
  - [Payone] add payone connector ([#4553](https://github.com/juspay/hyperswitch/pull/4553))
  - [Paypal] Add session_token flow for Paypal sdk ([#4697](https://github.com/juspay/hyperswitch/pull/4697))
- Add access_token flow for Payout Create and Fulfill flow ([#4375](https://github.com/juspay/hyperswitch/pull/4375))
- Add an api to encrypt and migrate the apple pay certificates from connector metadata to `connector_wallets_details` column in merchant connector account ([#4790](https://github.com/juspay/hyperswitch/pull/4790))
- Add profile level config to toggle extended card bin ([#4445](https://github.com/juspay/hyperswitch/pull/4445))
- Add support for connectors having separate version call for pre authentication ([#4603](https://github.com/juspay/hyperswitch/pull/4603))
- Create Payout Webhook Flow ([#4696](https://github.com/juspay/hyperswitch/pull/4696))
- Add support for multitenancy and handle the same in router, producer, consumer, drainer and analytics ([#4630](https://github.com/juspay/hyperswitch/pull/4630))
- Pass `required_billing_contact_fields` field in `/session` call based on dynamic fields ([#4601](https://github.com/juspay/hyperswitch/pull/4601))
- Pass required shipping details field for wallets session call based on `business_profile` config ([#4616](https://github.com/juspay/hyperswitch/pull/4616))
- Enable auto-retries for apple pay ([#4721](https://github.com/juspay/hyperswitch/pull/4721))
- Use Ephemeral auth for pm list and pm delete ([#4996](https://github.com/juspay/hyperswitch/pull/4996))
- Implement Process tracker workflow for Payment method Status update ([#4668](https://github.com/juspay/hyperswitch/pull/4668))
- Add an api to enable `connector_agnostic_mit` feature ([#4480](https://github.com/juspay/hyperswitch/pull/4480))
- Add support for googlepay step up flow ([#2744](https://github.com/juspay/hyperswitch/pull/2744))
- Add payments manual-update api ([#5045](https://github.com/juspay/hyperswitch/pull/5045))
- Add frm webhook support ([#4662](https://github.com/juspay/hyperswitch/pull/4662))
- Add an api for toggle KV for all merchants ([#4600](https://github.com/juspay/hyperswitch/pull/4600))
- Realtime user analytics ([#5098](https://github.com/juspay/hyperswitch/pull/5098))
- Create API to Verify TOTP ([#4597](https://github.com/juspay/hyperswitch/pull/4597))
- New routes to accept invite and list merchants ([#4591](https://github.com/juspay/hyperswitch/pull/4591))
- Add support to verify 2FA using recovery code ([#4737](https://github.com/juspay/hyperswitch/pull/4737))
- Implement force set and force change password ([#4564](https://github.com/juspay/hyperswitch/pull/4564))
- Implemented openidconnect ([#5124](https://github.com/juspay/hyperswitch/pull/5124))
- Add support for gauge metrics and include IMC metrics ([#4939](https://github.com/juspay/hyperswitch/pull/4939))
- Add metadata info to events ([#4875](https://github.com/juspay/hyperswitch/pull/4875))
- Add audit events payment confirm ([#4763](https://github.com/juspay/hyperswitch/pull/4763))
- Add audit events payment capture ([#4913](https://github.com/juspay/hyperswitch/pull/4913))

#### Refactors/Bug Fixes

- Add web client and control center services to docker compose setup ([#4197](https://github.com/juspay/hyperswitch/pull/4197))
- Fix stack overflow for docker images ([#4660](https://github.com/juspay/hyperswitch/pull/4660))
- Fix docker compose syntax ([#4782](https://github.com/juspay/hyperswitch/pull/4782))
- Add `max_amount` validation in payment flows ([#4645](https://github.com/juspay/hyperswitch/pull/4645))
- Make the constraint graph framework generic and move it into a separate crate ([#3071](https://github.com/juspay/hyperswitch/pull/3071))
- Add visualization functionality to the constraint graph ([#4701](https://github.com/juspay/hyperswitch/pull/4701))
- Rename crate data_models to hyperswitch_domain_models ([#4504](https://github.com/juspay/hyperswitch/pull/4504))
- Move RouterData to crate hyperswitch_domain_models ([#4524](https://github.com/juspay/hyperswitch/pull/4524))
- Move router data response and request models to hyperswitch domain models crate ([#4789](https://github.com/juspay/hyperswitch/pull/4789))
- Move router data flow types to hyperswitch domain models crate ([#4801](https://github.com/juspay/hyperswitch/pull/4801))
- Extract incoming and outgoing webhooks into separate modules ([#4870](https://github.com/juspay/hyperswitch/pull/4870))
- Move trait ConnectorIntegration to crate hyperswitch_interfaces ([#4946](https://github.com/juspay/hyperswitch/pull/4946))
- Introduce an interface to switch between old and new connector integration implementations on the connectors ([#5013](https://github.com/juspay/hyperswitch/pull/5013))
- Add a new endpoint for Complete Authorize flow ([#4686](https://github.com/juspay/hyperswitch/pull/4686))
- Refactor frm configs ([#4581](https://github.com/juspay/hyperswitch/pull/4581))
- Rename Card struct for payouts to avoid overrides in auto generated open API spec ([#4861](https://github.com/juspay/hyperswitch/pull/4861))
- Store `payment_method_data_billing` for recurring payments ([#4513](https://github.com/juspay/hyperswitch/pull/4513))
- Refactor conditional_configs to use Moka Cache instead of Static Cache ([#4814](https://github.com/juspay/hyperswitch/pull/4814))
- [Adyen] send `browser_info` for all the card and googlepay payments ([#5173](https://github.com/juspay/hyperswitch/pull/5173))
- [Stripe] Pass optional browser_info to stripe for increased trust ([#4374](https://github.com/juspay/hyperswitch/pull/4374))
- [NMI] Change fields for external auth due to API contract changes ([#4531](https://github.com/juspay/hyperswitch/pull/4531))
- [Klarna] Refactor Authorize call and configs for prod ([#4750](https://github.com/juspay/hyperswitch/pull/4750))
- [Adyen] handle redirection error response ([#4862](https://github.com/juspay/hyperswitch/pull/4862))
- [Stripe] Changed amount to minor Unit for stripe ([#4786](https://github.com/juspay/hyperswitch/pull/4786))
- Make save_payment_method as post_update_tracker trait function ([#4307](https://github.com/juspay/hyperswitch/pull/4307))
- Add support to enable pm_data and pm_id in payments response ([#4711](https://github.com/juspay/hyperswitch/pull/4711))
- Refactor the Knowledge Graph to include configs check, while eligibility analysis ([#4687](https://github.com/juspay/hyperswitch/pull/4687))
- Move openapi to a separate folder ([#4859](https://github.com/juspay/hyperswitch/pull/4859))
- Store `card_network` in locker ([#4425](https://github.com/juspay/hyperswitch/pull/4425))
- Enable deletion of default Payment Methods ([#4942](https://github.com/juspay/hyperswitch/pull/4942))
- Changed payment method token TTL to api contract based config from const value ([#5209](https://github.com/juspay/hyperswitch/pull/5209))
- Deprecate Signin, Verify email and Invite v1 APIs ([#4465](https://github.com/juspay/hyperswitch/pull/4465))
- Add password validations ([#4555](https://github.com/juspay/hyperswitch/pull/4555))

#### Compatibility

This version of the Hyperswitch App server is compatible with the following versions of other components:

- Control Center Version: [v1.31.0](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.31.0)
- Web Client Version: [v0.71.11](https://github.com/juspay/hyperswitch-web/releases/tag/v0.71.11)
- WooCommerce Plugin Version: [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1)
- Card Vault Version: [v0.4.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.4.0)

#### Database Migrations

```sql
-- DB Difference BETWEEN v1.108.0 AND v1.109.0
ALTER TABLE payouts ADD COLUMN IF NOT EXISTS confirm bool;
ALTER TYPE "PayoutStatus" ADD VALUE IF NOT EXISTS 'requires_vendor_account_creation';
CREATE TYPE "GenericLinkType" as ENUM(
    'payment_method_collect',
    'payout_link'
);

CREATE TABLE generic_link (
    link_id VARCHAR (64) NOT NULL PRIMARY KEY,
    primary_reference VARCHAR (64) NOT NULL,
    merchant_id VARCHAR (64) NOT NULL,
    created_at timestamp NOT NULL DEFAULT NOW():: timestamp,
    last_modified_at timestamp NOT NULL DEFAULT NOW():: timestamp,
    expiry timestamp NOT NULL,
    link_data JSONB NOT NULL,
    link_status JSONB NOT NULL,
    link_type "GenericLinkType" NOT NULL,
    url TEXT NOT NULL,
    return_url TEXT NULL
);
ALTER TABLE merchant_account ADD COLUMN IF NOT EXISTS pm_collect_link_config JSONB NULL;

ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS payout_link_config JSONB NULL;
-- Your SQL goes here

ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS is_extended_card_info_enabled BOOLEAN DEFAULT FALSE;
-- Your SQL goes here

ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS extended_card_info_config JSONB DEFAULT NULL;
ALTER TABLE fraud_check ADD COLUMN IF NOT EXISTS payment_capture_method "CaptureMethod" NULL;
-- Your SQL goes here

ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS is_connector_agnostic_mit_enabled BOOLEAN DEFAULT FALSE;
-- Your SQL goes here
ALTER TABLE authentication ALTER COLUMN error_message TYPE TEXT;
-- Your SQL goes here
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS payment_method_billing_address BYTEA;
-- Your SQL goes here
ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS use_billing_as_payment_method_billing BOOLEAN DEFAULT TRUE;
-- Your SQL goes here
CREATE TABLE IF NOT EXISTS user_key_store (
    user_id VARCHAR(64) PRIMARY KEY,
    key bytea NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);
ALTER TABLE payment_intent ADD COLUMN IF NOT EXISTS charges jsonb;

ALTER TABLE payment_attempt ADD COLUMN IF NOT EXISTS charge_id VARCHAR(64);

ALTER TABLE refund ADD COLUMN IF NOT EXISTS charges jsonb;
-- Your SQL goes here
CREATE TYPE "TotpStatus" AS ENUM (
  'set',
  'in_progress',
  'not_set'
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS totp_status "TotpStatus" DEFAULT 'not_set' NOT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS totp_secret bytea DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS totp_recovery_codes TEXT[] DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_password_modified_at TIMESTAMP;
-- Your SQL goes here
ALTER TABLE authentication DROP COLUMN three_dsserver_trans_id;
-- Your SQL goes here

ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS collect_shipping_details_from_wallet_connector BOOLEAN DEFAULT FALSE;
-- Your SQL goes here
ALTER TABLE payment_intent ADD COLUMN IF NOT EXISTS frm_metadata JSONB DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE payment_methods ADD COLUMN IF NOT EXISTS updated_by VARCHAR(64);

ALTER TABLE mandate ADD COLUMN IF NOT EXISTS updated_by VARCHAR(64);

ALTER TABLE customers ADD COLUMN IF NOT EXISTS updated_by VARCHAR(64);
-- Your SQL goes here
ALTER TABLE payment_attempt ADD COLUMN IF NOT EXISTS client_source VARCHAR(64) DEFAULT NULL;
ALTER TABLE payment_attempt ADD COLUMN IF NOT EXISTS client_version VARCHAR(64) DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE payout_attempt ALTER COLUMN connector_payout_id DROP NOT NULL;

UPDATE payout_attempt SET connector_payout_id = NULL WHERE connector_payout_id = '';
-- Your SQL goes here
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'payout_success';
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'payout_failed';
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'payout_processing';
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'payout_cancelled';
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'payout_initiated';
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'payout_expired';
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'payout_reversed';

ALTER TYPE "EventObjectType" ADD VALUE IF NOT EXISTS 'payout_details';

ALTER TYPE "EventClass" ADD VALUE IF NOT EXISTS 'payouts';
-- Your SQL goes here
ALTER TABLE authentication ADD COLUMN IF NOT EXISTS ds_trans_id VARCHAR(64);
-- Your SQL goes here
ALTER TABLE authentication ADD COLUMN IF NOT EXISTS directory_server_id VARCHAR(128);
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'AOA';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'BAM';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'BGN';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'BYN';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'CVE';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'FKP';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'GEL';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'IQD';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'LYD';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'MRU';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'MZN';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'PAB';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'RSD';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'SBD';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'SHP';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'SLE';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'SRD';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'STN';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'TND';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'TOP';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'UAH';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'VES';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'WST';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'XCD';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'ZMW';
-- Your SQL goes here
ALTER TYPE "PayoutStatus" ADD VALUE IF NOT EXISTS 'initiated';
ALTER TYPE "PayoutStatus" ADD VALUE IF NOT EXISTS 'expired';
ALTER TYPE "PayoutStatus" ADD VALUE IF NOT EXISTS 'reversed';
-- Your SQL goes here
ALTER TABLE merchant_connector_account ADD COLUMN IF NOT EXISTS connector_wallets_details BYTEA DEFAULT NULL;
-- Your SQL goes here
ALTER TABLE payouts ADD COLUMN IF NOT EXISTS payout_link_id VARCHAR(255);
-- Your SQL goes here
ALTER TABLE authentication ADD COLUMN IF NOT EXISTS acquirer_country_code VARCHAR(64);
-- First drop the primary key of payment_intent
ALTER TABLE payment_intent DROP CONSTRAINT payment_intent_pkey;

-- Create new primary key
ALTER TABLE payment_intent ADD PRIMARY KEY (payment_id, merchant_id);

-- Make the previous primary key as optional
ALTER TABLE payment_intent ALTER COLUMN id DROP NOT NULL;

-- Follow the same steps for payment attempt as well
ALTER TABLE payment_attempt DROP CONSTRAINT payment_attempt_pkey;

ALTER TABLE payment_attempt ADD PRIMARY KEY (attempt_id, merchant_id);

ALTER TABLE payment_attempt ALTER COLUMN id DROP NOT NULL;
-- Your SQL goes here
ALTER TABLE payouts ADD COLUMN IF NOT EXISTS client_secret VARCHAR(128) DEFAULT NULL;

ALTER TYPE "PayoutStatus" ADD VALUE IF NOT EXISTS 'requires_confirmation';
ALTER TABLE payouts ADD COLUMN IF NOT EXISTS priority VARCHAR(32);
CREATE INDEX connector_payout_id_merchant_id_index ON payout_attempt (connector_payout_id, merchant_id);
-- Your SQL goes here
ALTER TABLE users ALTER COLUMN password DROP NOT NULL;
-- Your SQL goes here
CREATE TABLE IF NOT EXISTS user_authentication_methods (
    id VARCHAR(64) PRIMARY KEY,
    auth_id VARCHAR(64) NOT NULL,
    owner_id VARCHAR(64) NOT NULL,
    owner_type VARCHAR(64) NOT NULL,
    auth_type VARCHAR(64) NOT NULL,
    private_config bytea,
    public_config JSONB,
    allow_signup BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS auth_id_index ON user_authentication_methods (auth_id);
CREATE INDEX IF NOT EXISTS owner_id_index ON user_authentication_methods (owner_id);
-- Your SQL goes here
ALTER TABLE payouts ALTER COLUMN payout_type DROP NOT NULL;
ALTER TABLE events ADD COLUMN metadata JSONB DEFAULT NULL;
```

#### Configuration Changes

Diff of configuration changes between <code>v1.108.0</code> and <code>v1.109.0</code>

```patch
diff --git a/config/deployments/sandbox.toml b/config/deployments/sandbox.toml
index acec5bbadf06..db6b9354d066 100644
--- a/config/deployments/sandbox.toml
+++ b/config/deployments/sandbox.toml
@@ -3,6 +3,7 @@ eps.adyen.banks = "bank_austria,bawag_psk_ag,dolomitenbank,easybank_ag,erste_ban
 eps.stripe.banks = "arzte_und_apotheker_bank,austrian_anadi_bank_ag,bank_austria,bankhaus_carl_spangler,bankhaus_schelhammer_und_schattera_ag,bawag_psk_ag,bks_bank_ag,brull_kallmus_bank_ag,btv_vier_lander_bank,capital_bank_grawe_gruppe_ag,dolomitenbank,easybank_ag,erste_bank_und_sparkassen,hypo_alpeadriabank_international_ag,hypo_noe_lb_fur_niederosterreich_u_wien,hypo_oberosterreich_salzburg_steiermark,hypo_tirol_bank_ag,hypo_vorarlberg_bank_ag,hypo_bank_burgenland_aktiengesellschaft,marchfelder_bank,oberbank_ag,raiffeisen_bankengruppe_osterreich,schoellerbank_ag,sparda_bank_wien,volksbank_gruppe,volkskreditbank_ag,vr_bank_braunau"
 ideal.adyen.banks = "abn_amro,asn_bank,bunq,ing,knab,n26,nationale_nederlanden,rabobank,regiobank,revolut,sns_bank,triodos_bank,van_lanschot,yoursafe"
 ideal.stripe.banks = "abn_amro,asn_bank,bunq,handelsbanken,ing,knab,moneyou,rabobank,regiobank,revolut,sns_bank,triodos_bank,van_lanschot"
+ideal.multisafepay.banks = "abn_amro, asn_bank, bunq, handelsbanken, nationale_nederlanden, n26, ing, knab, rabobank, regiobank, revolut, sns_bank,triodos_bank, van_lanschot, yoursafe"
 online_banking_czech_republic.adyen.banks = "ceska_sporitelna,komercni_banka,platnosc_online_karta_platnicza"
 online_banking_fpx.adyen.banks = "affin_bank,agro_bank,alliance_bank,am_bank,bank_islam,bank_muamalat,bank_rakyat,bank_simpanan_nasional,cimb_bank,hong_leong_bank,hsbc_bank,kuwait_finance_house,maybank,ocbc_bank,public_bank,rhb_bank,standard_chartered_bank,uob_bank"
 online_banking_poland.adyen.banks = "blik_psp,place_zipko,m_bank,pay_with_ing,santander_przelew24,bank_pekaosa,bank_millennium,pay_with_alior_bank,banki_spoldzielcze,pay_with_inteligo,bnp_paribas_poland,bank_nowy_sa,credit_agricole,pay_with_bos,pay_with_citi_handlowy,pay_with_plus_bank,toyota_bank,velo_bank,e_transfer_pocztowy24"
@@ -13,12 +14,13 @@ przelewy24.stripe.banks = "alior_bank,bank_millennium,bank_nowy_bfg_sa,bank_peka

 [connector_customer]
 connector_list = "stax,stripe,gocardless"
-payout_connector_list = "wise"
+payout_connector_list = "stripe,wise"

 [connectors]
 aci.base_url = "https://eu-test.oppwa.com/"
 adyen.base_url = "https://checkout-test.adyen.com/"
 adyen.secondary_base_url = "https://pal-test.adyen.com/"
+adyenplatform.base_url = "https://balanceplatform-api-test.adyen.com/"
 airwallex.base_url = "https://api-demo.airwallex.com/"
 applepay.base_url = "https://apple-pay-gateway.apple.com/"
 authorizedotnet.base_url = "https://apitest.authorize.net/xml/v1/request.api"
@@ -37,6 +39,7 @@ checkout.base_url = "https://api.sandbox.checkout.com/"
 coinbase.base_url = "https://api.commerce.coinbase.com"
 cryptopay.base_url = "https://business-sandbox.cryptopay.me"
 cybersource.base_url = "https://apitest.cybersource.com/"
+datatrans.base_url = "https://api.sandbox.datatrans.com/"
 dlocal.base_url = "https://sandbox.dlocal.com/"
 dummyconnector.base_url = "http://localhost:8080/dummy-connector"
 ebanx.base_url = "https://sandbox.ebanxpay.com/"
@@ -45,9 +48,11 @@ forte.base_url = "https://sandbox.forte.net/api/v3"
 globalpay.base_url = "https://apis.sandbox.globalpay.com/ucp/"
 globepay.base_url = "https://pay.globepay.co/"
 gocardless.base_url = "https://api-sandbox.gocardless.com"
+gpayments.base_url = "https://{{merchant_endpoint_prefix}}-test.api.as1.gpayments.net"
 helcim.base_url = "https://api.helcim.com/"
 iatapay.base_url = "https://sandbox.iata-pay.iata.org/api/v1"
-klarna.base_url = "https://api-na.playground.klarna.com/"
+klarna.base_url = "https://api{{klarna_region}}.playground.klarna.com/"
+mifinity.base_url = "https://demo.mifinity.com/"
 mollie.base_url = "https://api.mollie.com/v2/"
 mollie.secondary_base_url = "https://api.cc.mollie.com/v1/"
 multisafepay.base_url = "https://testapi.multisafepay.com/"
@@ -60,6 +65,7 @@ opayo.base_url = "https://pi-test.sagepay.com/"
 opennode.base_url = "https://dev-api.opennode.com"
 payeezy.base_url = "https://api-cert.payeezy.com/"
 payme.base_url = "https://sandbox.payme.io/"
+payone.base_url = "https://payment.preprod.payone.com/"
 paypal.base_url = "https://api-m.sandbox.paypal.com/"
 payu.base_url = "https://secure.snd.payu.com/"
 placetopay.base_url = "https://test.placetopay.com/rest/gateway"
@@ -110,6 +116,12 @@ refund_tolerance = 100
 refund_ttl = 172800
 slack_invite_url = "https://join.slack.com/t/hyperswitch-io/shared_invite/zt-2awm23agh-p_G5xNpziv6yAiedTkkqLg"

+[user]
+password_validity_in_days = 90
+two_factor_auth_expiry_in_secs = 300
+totp_issuer_name = "Hyperswitch Sandbox"
+base_url = "https://app.hyperswitch.io"
+
 [frm]
 enabled = true

@@ -123,9 +135,9 @@ pay_later.klarna.connector_list = "adyen"
 wallet.apple_pay.connector_list = "stripe,adyen,cybersource,noon,bankofamerica"
 wallet.google_pay.connector_list = "stripe,adyen,cybersource,bankofamerica"
 wallet.paypal.connector_list = "adyen"
-bank_redirect.ideal.connector_list = "stripe,adyen,globalpay"
+bank_redirect.ideal.connector_list = "stripe,adyen,globalpay,multisafepay"
 bank_redirect.sofort.connector_list = "stripe,adyen,globalpay"
-bank_redirect.giropay.connector_list = "adyen,globalpay"
+bank_redirect.giropay.connector_list = "adyen,globalpay,multisafepay"

 [mandates.update_mandate_supported]
 card.credit = { connector_list = "cybersource" }
@@ -171,7 +183,7 @@ we_chat_pay = { country = "AU,NZ,CN,JP,HK,SG,ES,GB,SE,NO,AT,NL,DE,CY,CH,BE,FR,DK
 [pm_filters.adyen]
 ach = { country = "US", currency = "USD" }
 affirm = { country = "US", currency = "USD" }
-afterpay_clearpay = { country = "AU,NZ,ES,GB,FR,IT,CA,US", currency = "GBP" }
+afterpay_clearpay = { country = "US,CA,GB,AU,NZ", currency = "GBP,AUD,NZD,CAD,USD" }
 alfamart = { country = "ID", currency = "IDR" }
 ali_pay = { country = "AU,JP,HK,SG,MY,TH,ES,GB,SE,NO,AT,NL,DE,CY,CH,BE,FR,DK,FI,RO,MT,SI,GR,PT,IE,IT,CA,US", currency = "USD,EUR,GBP,JPY,AUD,SGD,CHF,SEK,NOK,NZD,THB,HKD,CAD" }
 ali_pay_hk = { country = "HK", currency = "HKD" }
@@ -242,6 +254,12 @@ debit = { currency = "USD" }
 apple_pay = { currency = "USD" }
 google_pay = { currency = "USD" }

+[pm_filters.cybersource]
+credit = { currency = "USD" }
+debit = { currency = "USD" }
+apple_pay = { currency = "USD" }
+google_pay = { currency = "USD" }
+
 [pm_filters.braintree]
 paypal.currency = "AUD,BRL,CAD,CNY,CZK,DKK,EUR,HKD,HUF,ILS,JPY,MYR,MXN,TWD,NZD,NOK,PHP,PLN,GBP,RUB,SGD,SEK,CHF,THB,USD"

@@ -260,9 +278,13 @@ we_chat_pay.currency = "GBP,CNY"
 [pm_filters.klarna]
 klarna = { country = "AU,AT,BE,CA,CZ,DK,FI,FR,DE,GR,IE,IT,NL,NZ,NO,PL,PT,ES,SE,CH,GB,US", currency = "CHF,DKK,EUR,GBP,NOK,PLN,SEK,USD,AUD,NZD,CAD" }

+[pm_filters.mifinity]
+mifinity = { country = "BR,CN,SG,MY,DE,CH,DK,GB,ES,AD,GI,FI,FR,GR,HR,IT,JP,MX,AR,CO,CL,PE,VE,UY,PY,BO,EC,GT,HN,SV,NI,CR,PA,DO,CU,PR,NL,NO,PL", currency = "AUD,CAD,CHF,CNY,CZK,DKK,EUR,GBP,INR,JPY,NOK,NZD,PLN,RUB,SEK,ZAR,USD" }
+
 [pm_filters.prophetpay]
 card_redirect.currency = "USD"

+
 [pm_filters.stax]
 ach = { country = "US", currency = "USD" }

@@ -327,3 +349,6 @@ connectors_with_webhook_source_verification_call = "paypal"

 [unmasked_headers]
 keys = "user-agent"
+
+[saved_payment_methods]
+sdk_eligible_payment_methods = "card"
```

```patch
diff --git a/config/deployments/env_specific.toml b/config/deployments/env_specific.toml
index c725a8bd69d3..68df3d28e243 100644
--- a/config/deployments/env_specific.toml
+++ b/config/deployments/env_specific.toml
@@ -58,7 +58,6 @@ wildcard_origin = false                 # If true, allows any origin to make req
 [email]
 sender_email = "example@example.com" # Sender email
 aws_region = ""                      # AWS region used by AWS SES
-base_url = ""                        # Dashboard base url used when adding links that should redirect to self, say https://app.hyperswitch.io for example
 allowed_unverified_days = 1          # Number of days the api calls ( with jwt token ) can be made without verifying the email
 active_email_client = "SES"          # The currently active email client

@@ -81,6 +80,8 @@ outgoing_webhook_logs_topic = "topic" # Kafka topic to be used for outgoing webh
 dispute_analytics_topic = "topic"          # Kafka topic to be used for Dispute events
 audit_events_topic = "topic"               # Kafka topic to be used for Payment Audit events
 payout_analytics_topic = "topic"           # Kafka topic to be used for Payouts and PayoutAttempt events
+consolidated_events_topic = "topic"        # Kafka topic to be used for Consolidated events
+authentication_analytics_topic = "topic"   # Kafka topic to be used for Authentication events

 # File storage configuration
 [file_storage]
@@ -115,6 +116,8 @@ mock_locker = true                                                    # Emulate
 locker_signing_key_id = "1"                                           # Key_id to sign basilisk hs locker
 locker_enabled = true                                                 # Boolean to enable or disable saving cards in locker
 redis_temp_locker_encryption_key = "redis_temp_locker_encryption_key" # Encryption key for redis temp locker
+ttl_for_storage_in_secs = 220752000                                   # Time to live for storage entries in locker
+

 [log.console]
 enabled = true
@@ -136,6 +139,7 @@ otel_exporter_otlp_endpoint = "http://localhost:4317" # endpoint to send metrics
 otel_exporter_otlp_timeout = 5000                     # timeout (in milliseconds) for sending metrics and traces
 use_xray_generator = false                            # Set this to true for AWS X-ray compatible traces
 route_to_trace = ["*/confirm"]
+bg_metrics_collection_interval_in_secs = 15           # Interval for collecting the metrics in background thread

 [lock_settings]
 delay_between_retries_in_milliseconds = 500 # Delay between retries in milliseconds
@@ -152,6 +156,31 @@ pool_size = 5             # Number of connections to keep open
 connection_timeout = 10   # Timeout for database connection in seconds
 queue_strategy = "Fifo"   # Add the queue strategy used by the database bb8 client

+[generic_link]
+[generic_link.payment_method_collect]
+sdk_url = "http://localhost:9090/0.16.7/v0/HyperLoader.js"
+expiry = 900
+[generic_link.payment_method_collect.ui_config]
+theme = "#4285F4"
+logo = "https://app.hyperswitch.io/HyperswitchFavicon.png"
+merchant_name = "HyperSwitch"
+[generic_link.payment_method_collect.enabled_payment_methods]
+card = ["credit", "debit"]
+bank_transfer = ["ach", "bacs", "sepa"]
+wallet = ["paypal", "pix", "venmo"]
+
+[generic_link.payout_link]
+sdk_url = "http://localhost:9090/0.16.7/v0/HyperLoader.js"
+expiry = 900
+[generic_link.payout_link.ui_config]
+theme = "#4285F4"
+logo = "https://app.hyperswitch.io/HyperswitchFavicon.png"
+merchant_name = "HyperSwitch"
+[generic_link.payout_link.enabled_payment_methods]
+card = ["credit", "debit"]
+bank_transfer = ["ach", "bacs", "sepa"]
+wallet = ["paypal", "pix", "venmo"]
+
 [payment_link]
 sdk_url = "http://localhost:9090/0.16.7/v0/HyperLoader.js"

@@ -227,7 +256,6 @@ recon_admin_api_key = "recon_test_admin" # recon_admin API key for recon authent

 # Server configuration
 [server]
-base_url = "https://server_base_url"
 workers = 8
 port = 8080
 host = "127.0.0.1"
@@ -250,3 +278,13 @@ encryption_manager = "aws_kms" # Encryption manager client to be used
 [encryption_management.aws_kms]
 key_id = "kms_key_id" # The AWS key ID used by the KMS SDK for decrypting data.
 region = "kms_region" # The AWS region used by the KMS SDK for decrypting data.
+
+[multitenancy]
+enabled = false
+global_tenant = { schema = "public", redis_key_prefix = "" }
+
+[multitenancy.tenants]
+public = { name = "hyperswitch", base_url = "http://localhost:8080", schema = "public", redis_key_prefix = "", clickhouse_database = "default"}
+
+[user_auth_methods]
+encryption_key = "user_auth_table_encryption_key" # Encryption key used for encrypting data in user_authentication_methods table

```

**Full Changelog:** [`v1.108.0...v1.109.0`](https://github.com/juspay/hyperswitch/compare/v1.108.0...v1.109.0)

### [Hyperswitch Control Center v1.31.0 (2024-06-08)](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.31.0)

- **Product Name**: [Hyperswitch-control-center](https://github.com/juspay/hyperswitch-control-center)
- **Version**: [v1.31.0](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.31.0)
- **Release Date**: 08-06-2024

We are excited to release the latest version of the Hyperswitch control center! This release represents yet another achievement in our ongoing efforts to deliver a flexible, cutting-edge, and community-focused payment solution.

**Features**

- Force Sync for Refunds ([#654](https://github.com/juspay/hyperswitch-control-center/pull/654))
- Payouts Operation ([#774](https://github.com/juspay/hyperswitch-control-center/pull/774))
- Payment Methods Configuration ([#495](https://github.com/juspay/hyperswitch-control-center/pull/495))
- 3DS Authentication Analytics ([#678](https://github.com/juspay/hyperswitch-control-center/pull/678))
- Added new connector MiFinity

**Enhancement**

- Payment and Refund Filter Enhancement ([#683](https://github.com/juspay/hyperswitch-control-center/pull/683)) ([#620](https://github.com/juspay/hyperswitch-control-center/pull/620)) ([#690](https://github.com/juspay/hyperswitch-control-center/pull/690)) ([#699](https://github.com/juspay/hyperswitch-control-center/pull/699))

- Payment Details Page Enhancement ([#703](https://github.com/juspay/hyperswitch-control-center/pull/703)) ([#736](https://github.com/juspay/hyperswitch-control-center/pull/736))
- Events and Logs UI Enhancement ([#735](https://github.com/juspay/hyperswitch-control-center/pull/735))
- Select Different Payment Methods for PayPal Wallet ([#785](https://github.com/juspay/hyperswitch-control-center/pull/785))

**Fixes**

- Intermittent Black Screen in Payments Order Page ([#725](https://github.com/juspay/hyperswitch-control-center/pull/725))
- Minor UI Fixes ([#699](https://github.com/juspay/hyperswitch-control-center/pull/699)) ([#686](https://github.com/juspay/hyperswitch-control-center/pull/686)) ([#670](https://github.com/juspay/hyperswitch-control-center/pull/670)) ([#673](https://github.com/juspay/hyperswitch-control-center/pull/673)) ([#692](https://github.com/juspay/hyperswitch-control-center/pull/692)) ([#697](https://github.com/juspay/hyperswitch-control-center/pull/697)) ([726](https://github.com/juspay/hyperswitch-control-center/pull/726)) ([#752](https://github.com/juspay/hyperswitch-control-center/pull/752)) ([#803](https://github.com/juspay/hyperswitch-control-center/pull/803)) ([#834](https://github.com/juspay/hyperswitch-control-center/pull/834)) ([#839](https://github.com/juspay/hyperswitch-control-center/pull/839))

#### Compatibility

This version of the Hyperswitch App server is compatible with the following versions of other components:

- App Server Version: [v1.109.0](https://github.com/juspay/hyperswitch/releases/tag/v1.109.0)
- Web Client Version: [v0.71.11](https://github.com/juspay/hyperswitch-web/releases/tag/v0.71.11)
- WooCommerce Plugin Version: [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1)
- Card Vault Version: [v0.4.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.4.0)

**Full Changelog**: https://github.com/juspay/hyperswitch-control-center/compare/v1.30.1...v1.31.0

### [Hyperswitch Web Client v0.71.11 (2024-06-08)](https://github.com/juspay/hyperswitch-web/releases/tag/v0.71.11)

- fix: customer payment methods promise ([#266](https://github.com/juspay/hyperswitch-web/pull/266))
- feat(3ds): three DS SDK - adding logs to track milestone events ([#265](https://github.com/juspay/hyperswitch-web/pull/265))
- feat: giropay dynamic fields added ([#267](https://github.com/juspay/hyperswitch-web/pull/267))
- fix: app rendered event latency calculation ([#273](https://github.com/juspay/hyperswitch-web/pull/273))
- feat: logging payment data filled ([#269](https://github.com/juspay/hyperswitch-web/pull/269))
- feat: locale-string added for rest locales ([#247](https://github.com/juspay/hyperswitch-web/pull/247))
- fix: disable sdk button changes ([#244](https://github.com/juspay/hyperswitch-web/pull/244))
- fix: payment data filled google pay ([#281](https://github.com/juspay/hyperswitch-web/pull/281))
- fix: paypal issue for Ideal Fix ([#290](https://github.com/juspay/hyperswitch-web/pull/290))
- feat: added new redirection payment method local bank transfer ([#288](https://github.com/juspay/hyperswitch-web/pull/288))
- feat: mandate Changes for the Saved card screen & SDK Button Loader changes ([#289](https://github.com/juspay/hyperswitch-web/pull/289))
- fix(hyper.res): prefetch assets instead of preload ([#291](https://github.com/juspay/hyperswitch-web/pull/291))
- feat: (revert) mandate Changes for the Saved card screen & SDK Button Loader changes ([#301](https://github.com/juspay/hyperswitch-web/pull/301))
- fix: (paymenthelpers, paymentelement) promise being unresolved ([@297](https://github.com/juspay/hyperswitch-web/pull/297))
- refactor: Moved HTTP requests to within iframe ([#128](https://github.com/juspay/hyperswitch-web/pull/128))
- fix: mandate data pass hide checkbox ([#308](https://github.com/juspay/hyperswitch-web/pull/308))
- feat: mandate changes for Saved Card flow ([#309](https://github.com/juspay/hyperswitch-web/pull/309))
- fix(threedsmethod): changed Three DS method API call to hidden Form Post ([#302](https://github.com/juspay/hyperswitch-web/pull/302))
- feat: normal mandate changes ([#314](https://github.com/juspay/hyperswitch-web/pull/314))
- feat: polling status for 3ds flow Part 1 ([#329](https://github.com/juspay/hyperswitch-web/pull/329))
- feat: three_ds polling part2 ([#334](https://github.com/juspay/hyperswitch-web/pull/334))
- fix: move applepay thirdparty event listeners outside ([#336](https://github.com/juspay/hyperswitch-web/pull/336))
- feat: added one click widgets (applepay, googlepay, paypal) ([#271](https://github.com/juspay/hyperswitch-web/pull/271))
- feat: compressed theme layout ([#320](https://github.com/juspay/hyperswitch-web/pull/320))
- fix: remove expired saved cards ([#345](https://github.com/juspay/hyperswitch-web/pull/345))
- feat: identifying in-app browsers from user agents ([#317](https://github.com/juspay/hyperswitch-web/pull/317))
- feat: hideExpiredPaymentMethods prop added ([#350](https://github.com/juspay/hyperswitch-web/pull/350))
- refactor: moved Card Number, Cvc and Expiry to Dynamic Fields for Card Payment method ([#282](https://github.com/juspay/hyperswitch-web/pull/282))
- docs: locally connect documentation ([#335](https://github.com/juspay/hyperswitch-web/pull/335))
- fix: combined Dynamic Fields for credit and debit ([#351](https://github.com/juspay/hyperswitch-web/pull/351))
- fix: fixed Saveds Card Confirm Body Sending card details ([#351](https://github.com/juspay/hyperswitch-web/pull/352))
- fix: api-endpoint-url fix for custom backend url ([#357](https://github.com/juspay/hyperswitch-web/pull/357))
- fix: card brand configuration error added ([#362](https://github.com/juspay/hyperswitch-web/pull/362))
- feat: phone country dropdown added ([#270](https://github.com/juspay/hyperswitch-web/pull/270))
- feat: address collection for one click widgets ([#361](https://github.com/juspay/hyperswitch-web/pull/361))
- feat: unsupported card networks validation ([#370](https://github.com/juspay/hyperswitch-web/pull/370))
- fix: sdk button loader issue ([#400]https://github.com/juspay/hyperswitch-web/pull/400)
- feat: 3DS netcetra Part B ([#383](https://github.com/juspay/hyperswitch-web/pull/383))
- fix: added Fixes for one click widgets ([#399](https://github.com/juspay/hyperswitch-web/pull/399))
- fix: fixed ApplePay Event Handler ([#406](https://github.com/juspay/hyperswitch-web/pull/406))
- feat: added PayPal SDK Via PayPal ([#404](https://github.com/juspay/hyperswitch-web/pull/404))
- fix: hide terms based upon prop ([#408](https://github.com/juspay/hyperswitch-web/pull/408))
- fix: allow customer to pay with different payment method on cancel of… ([#409](https://github.com/juspay/hyperswitch-web/pull/409))
- feat: ali pay hk added, fix for disableSavedPaymentMethods prop ([#410](https://github.com/juspay/hyperswitch-web/pull/410))
- fix: fixed polling status and firefox form rendering ([#411](https://github.com/juspay/hyperswitch-web/pull/411))
- feat: enabled afterpay with dynamic fields ([#416](https://github.com/juspay/hyperswitch-web/pull/416))
- feat: added Klarna as a one click widget ([#420](https://github.com/juspay/hyperswitch-web/pull/420))
- feat: self serve url in env ([#425](https://github.com/juspay/hyperswitch-web/pull/425))
- feat: crypto currency network added ([#403](https://github.com/juspay/hyperswitch-web/pull/403))
- fix: removed fallback in case of sessions call fail based on payment experience ([#440](https://github.com/juspay/hyperswitch-web/pull/440))
- feat: log href without including search params ([#439](https://github.com/juspay/hyperswitch-web/pull/439))
- feat: added confirm and get handler for last used payment ([#428](https://github.com/juspay/hyperswitch-web/pull/428))
- feat: added prop for displayDefaultSavedPaymentIcon ([#434](https://github.com/juspay/hyperswitch-web/pull/434))
- feat: hideCardNicknameField added ([#445](https://github.com/juspay/hyperswitch-web/pull/445))
- feat: add datepicker library ([#449](https://github.com/juspay/hyperswitch-web/pull/449))
- feat: mifinity wallet addition ([#451](https://github.com/juspay/hyperswitch-web/pull/451))
- feat: phone country code accept ([#452](https://github.com/juspay/hyperswitch-web/pull/452))
- feat: headless applepay and googlepay ([#454](https://github.com/juspay/hyperswitch-web/pull/454))
- fix: fixed Saved Methods ApplePay and GooglePay Handler ([#455](https://github.com/juspay/hyperswitch-web/pull/455))
- feat: add payout widget ([#435](https://github.com/juspay/hyperswitch-web/pull/435))
- fix: fixed Appearance and Headless PaymentMethodId ([#462](https://github.com/juspay/hyperswitch-web/pull/462))
- fix: manual retries ([#453](https://github.com/juspay/hyperswitch-web/pull/453))
- fix: googlePay and applePay billing details not being passed in confirm call for saved methods ([#464](https://github.com/juspay/hyperswitch-web/pull/464))

**Full Changelog**: https://github.com/juspay/hyperswitch-web/compare/v0.35.4...v0.71.11

#### Compatibility

This version of the Hyperswitch App server is compatible with the following versions of other components:

- App server Version: [v0.71.11](https://github.com/juspay/hyperswitch/releases/tag/v1.109.0)
- Control Center Version: [v1.31.0](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.31.0)
- WooCommerce Plugin Version: [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1)
- Card Vault Version: [v0.4.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.4.0)

### [Hyperswitch WooCommerce Plugin v1.6.1 (2024-05-13)](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1)

- Update stable version (1.5.1) in docs ([#9](https://github.com/juspay/hyperswitch-woocommerce-plugin/pull/9))
- Code Formatting, Nonce verification with sanitization first ([#11](https://github.com/juspay/hyperswitch-woocommerce-plugin/pull/11))
- Feat/v1.6.0 wordpress release ([#13](https://github.com/juspay/hyperswitch-woocommerce-plugin/pull/13))
- Feat/profile id compatibility ([#14](https://github.com/juspay/hyperswitch-woocommerce-plugin/pull/14))

**Full Changelog**: https://github.com/juspay/hyperswitch-woocommerce-plugin/compare/v1.5.1...v1.6.1

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

## Hyperswitch Suite v1.2

### [Hyperswitch App Server v1.108.0 (2024-05-03)](https://github.com/juspay/hyperswitch/releases/tag/v1.108.0)

#### Docker Release

[v1.108.0](https://hub.docker.com/layers/juspaydotin/hyperswitch-router/v1.108.0/images/sha256-11923fd610d89982c25a37f4de22b822e24dd80e052e348a7a23a2d7fb44166f?context=explore) (with KMS)

[v1.108.0-standalone](https://hub.docker.com/layers/juspaydotin/hyperswitch-router/v1.108.0-standalone/images/sha256-32eeb924045e0d686d0eb048de4d7190b705fa6f6bdfc6dd83f030cbbd8f5007?context=explore) (without KMS)

#### Features

- **connector:**
  - [3dsecure.io] Add threedsecureio three_ds authentication connector ([#4004](https://github.com/juspay/hyperswitch/pull/4004))
  - [Checkout] add support for external authentication for checkout connector ([#4006](https://github.com/juspay/hyperswitch/pull/4006))
  - [AUTHORIZEDOTNET] Audit Connector ([#4035](https://github.com/juspay/hyperswitch/pull/4035))
  - [billwerk] implement payment and refund flows ([#4245](https://github.com/juspay/hyperswitch/pull/4245))
  - [Netcetera] Integrate netcetera connector with pre authentication flow ([#4293](https://github.com/juspay/hyperswitch/pull/4293))
  - [NMI] External 3DS flow for Cards ([#4385](https://github.com/juspay/hyperswitch/pull/4385))
  - [Netcetera] Implement authentication flow for netcetera ([#4334](https://github.com/juspay/hyperswitch/pull/4334))
  - [Netcetera] Add webhook support for netcetera ([#4382](https://github.com/juspay/hyperswitch/pull/4382))
  - [BOA] implement mandates for cards and wallets ([#4232](https://github.com/juspay/hyperswitch/pull/4232))
  - [Ebanx] Add payout flows ([#4146](https://github.com/juspay/hyperswitch/pull/4146))
  - [Paypal] Add payout flow for wallet(Paypal and Venmo) ([#4406](https://github.com/juspay/hyperswitch/pull/4406))
  - [BOA/Cybersource] add avs_response and cvv validation result in the response ([#4376](https://github.com/juspay/hyperswitch/pull/4376))
  - [Cybersource] Add NTID flow for cybersource ([#4193](https://github.com/juspay/hyperswitch/pull/4193))
- Add api_models for external 3ds authentication flow ([#3858](https://github.com/juspay/hyperswitch/pull/3858))
- Add core functions for external authentication ([#3969](https://github.com/juspay/hyperswitch/pull/3969))
- Confirm flow and authorization api changes for external authentication ([#4015](https://github.com/juspay/hyperswitch/pull/4015))
- Add incoming header request logs ([#3939](https://github.com/juspay/hyperswitch/pull/3939))
- Add payments authentication api flow ([#3996](https://github.com/juspay/hyperswitch/pull/3996))
- Add routing support for token-based mit payments ([#4012](https://github.com/juspay/hyperswitch/pull/4012))
- Add local bank transfer payment method ([#4294](https://github.com/juspay/hyperswitch/pull/4294))
- Add external authentication webhooks flow ([#4339](https://github.com/juspay/hyperswitch/pull/4339))
- Add retrieve poll status api ([#4358](https://github.com/juspay/hyperswitch/pull/4358))
- Handle authorization for frictionless flow in external 3ds flow ([#4471](https://github.com/juspay/hyperswitch/pull/4471))
- Customer kv impl ([#4267](https://github.com/juspay/hyperswitch/pull/4267))
- Add cypress test cases ([#4271](https://github.com/juspay/hyperswitch/pull/4271))
- Add audit events scaffolding ([#3863](https://github.com/juspay/hyperswitch/pull/3863))
- Add APIs to list webhook events and webhook delivery attempts ([#4131](https://github.com/juspay/hyperswitch/pull/4131))
- Add events framework for registering events ([#4115](https://github.com/juspay/hyperswitch/pull/4115))
- Add payment cancel events ([#4166](https://github.com/juspay/hyperswitch/pull/4166))
- Dashboard globalsearch apis ([#3831](https://github.com/juspay/hyperswitch/pull/3831))
- Add kv support for mandate ([#4275](https://github.com/juspay/hyperswitch/pull/4275))
- Allow off-session payments using `payment_method_id` ([#4132](https://github.com/juspay/hyperswitch/pull/4132))
- Added display_sdk_only option for displaying only sdk without payment details ([#4363](https://github.com/juspay/hyperswitch/pull/4363))
- Add support for saved payment method option for payment link ([#4373](https://github.com/juspay/hyperswitch/pull/4373))
- API to list countries and currencies supported by a country and payment method type ([#4126](https://github.com/juspay/hyperswitch/pull/4126))
- Added kv support for payment_methods table ([#4311](https://github.com/juspay/hyperswitch/pull/4311))
- Implement Single Connector Retry for Payouts ([#3908](https://github.com/juspay/hyperswitch/pull/3908))
- Implement KVRouterStore ([#3889](https://github.com/juspay/hyperswitch/pull/3889))
- Implement list and filter APIs ([#3651](https://github.com/juspay/hyperswitch/pull/3651))
- Support different pm types in PM auth ([#3114](https://github.com/juspay/hyperswitch/pull/3114))
- Add new API get the user and role details of specific user ([#3988](https://github.com/juspay/hyperswitch/pull/3988))
- Implement automatic retries for failed webhook deliveries using scheduler ([#3842](https://github.com/juspay/hyperswitch/pull/3842))
- Allow manually retrying delivery of outgoing webhooks ([#4176](https://github.com/juspay/hyperswitch/pull/4176))
- Store payment check codes and authentication data from processors ([#3958](https://github.com/juspay/hyperswitch/pull/3958))
- Stripe connect integration for payouts ([#2041](https://github.com/juspay/hyperswitch/pull/2041))
- Add support for merchant to pass public key and ttl for encrypting payload ([#4456](https://github.com/juspay/hyperswitch/pull/4456))
- Add an api for retrieving the extended card info from redis ([#4484](https://github.com/juspay/hyperswitch/pull/4484))

#### Refactors/Bug Fixes

- Use fallback to `connector_name` if `merchant_connector_id` is not present ([#4503](https://github.com/juspay/hyperswitch/pull/4503))
- Use first_name if last_name is not passed ([#4360](https://github.com/juspay/hyperswitch/pull/4360))
- Generate payment_id if not sent ([#4125](https://github.com/juspay/hyperswitch/pull/4125))
- Send valid sdk information in authentication flow netcetera ([#4474](https://github.com/juspay/hyperswitch/pull/4474))
- Fix wallet token deserialization error ([#4133](https://github.com/juspay/hyperswitch/pull/4133))
- Amount received should be zero for `pending` and `failed` status ([#4331](https://github.com/juspay/hyperswitch/pull/4331))
- Amount capturable remain same for `processing` status in capture ([#4229](https://github.com/juspay/hyperswitch/pull/4229))
- Fix 3DS mandates, for the connector \_mandate_details to be stored in the payment_methods table ([#4323](https://github.com/juspay/hyperswitch/pull/4323))
- Handle card duplication in payouts flow ([#4013](https://github.com/juspay/hyperswitch/pull/4013))
- Give higher precedence to connector mandate id over network txn id in mandates ([#4073](https://github.com/juspay/hyperswitch/pull/4073))
- Store network transaction id only when `pg_agnostic` config is enabled in the `authorize_flow` ([#4318](https://github.com/juspay/hyperswitch/pull/4318))
- Insert `locker_id` as null in case of payment method not getting stored in locker ([#3919](https://github.com/juspay/hyperswitch/pull/3919))
- Update payment method status only if existing status is not active ([#4149](https://github.com/juspay/hyperswitch/pull/4149))
- Fix token fetch logic in complete authorize flow for three ds payments ([#4052](https://github.com/juspay/hyperswitch/pull/4052))
- Handle redirection to return_url from nested iframe in separate 3ds flow ([#4164](https://github.com/juspay/hyperswitch/pull/4164))
- Capture billing country in payments request ([#4347](https://github.com/juspay/hyperswitch/pull/4347))
- Make payment_instrument optional ([#4389](https://github.com/juspay/hyperswitch/pull/4389))
- Remove enabled payment methods for payouts processor ([#3913](https://github.com/juspay/hyperswitch/pull/3913))
- Pass payment method billing to the connector module ([#3828](https://github.com/juspay/hyperswitch/pull/3828))
- Use `billing.first_name` instead of `card_holder_name` ([#4239](https://github.com/juspay/hyperswitch/pull/4239))
- Updated payments response with payment_method_id & payment_method_status ([#3883](https://github.com/juspay/hyperswitch/pull/3883))
- Log the appropriate error message if the card fails to get saved in locker ([#4296](https://github.com/juspay/hyperswitch/pull/4296))
- Make performance optimisation for payment_link ([#4092](https://github.com/juspay/hyperswitch/pull/4092))
- Decouple shimmer css from main payment_link css for better performance ([#4286](https://github.com/juspay/hyperswitch/pull/4286))
- Add a trait to retrieve billing from payment method data ([#4095](https://github.com/juspay/hyperswitch/pull/4095))
- Filter applepay payment method from mca based on customer pm ([#3953](https://github.com/juspay/hyperswitch/pull/3953))
- Enable country currency filter for cards ([#4056](https://github.com/juspay/hyperswitch/pull/4056))
- Add `network_transaction_id` column in the `payment_methods` table ([#4005](https://github.com/juspay/hyperswitch/pull/4005))
- Revamp payment methods update endpoint ([#4305](https://github.com/juspay/hyperswitch/pull/4305))
- Store `card_network` in locker ([#4425](https://github.com/juspay/hyperswitch/pull/4425))
- Deprecate Signin, Verify email and Invite v1 APIs ([#4465](https://github.com/juspay/hyperswitch/pull/4465))
- Use single purpose token and auth to accept invite ([#4498](https://github.com/juspay/hyperswitch/pull/4498))
- [Checkout] change payment and webhooks API contract ([#4023](https://github.com/juspay/hyperswitch/pull/4023))

#### Compatibility

This version of the Hyperswitch App server is compatible with the following versions of other components:

- Control Center Version: [v1.30.0](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.30.0)
- Web Client Version: [v0.35.4](https://github.com/juspay/hyperswitch-web/releases/tag/v0.35.4)
- WooCommerce Plugin Version: [v1.5.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.5.1)
- Card Vault Version: [v0.4.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.4.0)

#### Database Migrations

<details><summary>Click to view database migrations</summary>
<pre>
-- DB Difference BETWEEN v1.107.0 AND v1.108.0
CREATE TABLE IF NOT EXISTS authentication (
    authentication_id VARCHAR(64) NOT NULL,
    merchant_id VARCHAR(64) NOT NULL,
    authentication_connector VARCHAR(64) NOT NULL,
    connector_authentication_id VARCHAR(64),
    authentication_data JSONB,
    payment_method_id VARCHAR(64) NOT NULL,
    authentication_type VARCHAR(64),
    authentication_status VARCHAR(64) NOT NULL,
    authentication_lifecycle_status VARCHAR(64) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()::TIMESTAMP,
    modified_at TIMESTAMP NOT NULL DEFAULT now()::TIMESTAMP,
    error_message VARCHAR(64),
    error_code VARCHAR(64),
    PRIMARY KEY (authentication_id)
);

-- Your SQL goes here
ALTER TABLE payment_attempt
ADD COLUMN IF NOT EXISTS external_three_ds_authentication_attempted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS authentication_connector VARCHAR(64),
ADD COLUMN IF NOT EXISTS authentication_id VARCHAR(64);

-- Your SQL goes here
ALTER TABLE payment_intent
ADD COLUMN IF NOT EXISTS request_external_three_ds_authentication BOOLEAN;

-- Your SQL goes here
ALTER TYPE "ConnectorType"
ADD VALUE IF NOT EXISTS 'authentication_processor';

-- Your SQL goes here
ALTER TABLE authentication
ADD COLUMN IF NOT EXISTS connector_metadata JSONB DEFAULT NULL;

-- Your SQL goes here
ALTER TABLE payment_attempt
ADD COLUMN IF NOT EXISTS payment_method_billing_address_id VARCHAR(64);

-- Your SQL goes here
ALTER TYPE "PaymentSource"
ADD VALUE 'webhook';

ALTER TYPE "PaymentSource"
ADD VALUE 'external_authenticator';

ALTER TABLE PAYOUTS
ADD COLUMN profile_id VARCHAR(64);

UPDATE PAYOUTS AS PO
SET profile_id = POA.profile_id
FROM PAYOUT_ATTEMPT AS POA
WHERE PO.payout_id = POA.payout_id;

ALTER TABLE PAYOUTS
ALTER COLUMN profile_id
SET NOT NULL;

ALTER TABLE PAYOUTS
ADD COLUMN status "PayoutStatus";

UPDATE PAYOUTS AS PO
SET status = POA.status
FROM PAYOUT_ATTEMPT AS POA
WHERE PO.payout_id = POA.payout_id;

ALTER TABLE PAYOUTS
ALTER COLUMN status
SET NOT NULL;

-- Your SQL goes here
ALTER TABLE business_profile
ADD COLUMN IF NOT EXISTS authentication_connector_details JSONB NULL;

-- The following queries must be run before the newer version of the application is deployed.
ALTER TABLE events
ADD COLUMN merchant_id VARCHAR(64) DEFAULT NULL,
ADD COLUMN business_profile_id VARCHAR(64) DEFAULT NULL,
ADD COLUMN primary_object_created_at TIMESTAMP DEFAULT NULL,
ADD COLUMN idempotent_event_id VARCHAR(64) DEFAULT NULL,
ADD COLUMN initial_attempt_id VARCHAR(64) DEFAULT NULL,
ADD COLUMN request BYTEA DEFAULT NULL,
ADD COLUMN response BYTEA DEFAULT NULL;

UPDATE events
SET idempotent_event_id = event_id
WHERE idempotent_event_id IS NULL;

UPDATE events
SET initial_attempt_id = event_id
WHERE initial_attempt_id IS NULL;

ALTER TABLE events
ADD CONSTRAINT idempotent_event_id_unique UNIQUE (idempotent_event_id);

-- Your SQL goes here
ALTER TABLE payment_methods
ADD COLUMN network_transaction_id VARCHAR(255) DEFAULT NULL;

-- Your SQL goes here
ALTER TABLE authentication
ADD COLUMN IF NOT EXISTS maximum_supported_version JSONB,
ADD COLUMN IF NOT EXISTS threeds_server_transaction_id VARCHAR(64),
ADD COLUMN IF NOT EXISTS cavv VARCHAR(64),
ADD COLUMN IF NOT EXISTS authentication_flow_type VARCHAR(64),
ADD COLUMN IF NOT EXISTS message_version JSONB,
ADD COLUMN IF NOT EXISTS eci VARCHAR(64),
ADD COLUMN IF NOT EXISTS trans_status VARCHAR(64),
ADD COLUMN IF NOT EXISTS acquirer_bin VARCHAR(64),
ADD COLUMN IF NOT EXISTS acquirer_merchant_id VARCHAR(64),
ADD COLUMN IF NOT EXISTS three_ds_method_data VARCHAR,
ADD COLUMN IF NOT EXISTS three_ds_method_url VARCHAR,
ADD COLUMN IF NOT EXISTS acs_url VARCHAR,
ADD COLUMN IF NOT EXISTS challenge_request VARCHAR,
ADD COLUMN IF NOT EXISTS acs_reference_number VARCHAR,
ADD COLUMN IF NOT EXISTS acs_trans_id VARCHAR,
ADD COLUMN IF NOT EXISTS three_dsserver_trans_id VARCHAR,
ADD COLUMN IF NOT EXISTS acs_signed_content VARCHAR,
ADD COLUMN IF NOT EXISTS connector_metadata JSONB;

-- Your SQL goes here
ALTER TABLE payment_methods
ADD COLUMN IF NOT EXISTS client_secret VARCHAR(128) DEFAULT NULL;

ALTER TABLE payment_methods
ALTER COLUMN payment_method DROP NOT NULL;

CREATE UNIQUE INDEX events_merchant_id_event_id_index ON events (merchant_id, event_id);

CREATE INDEX events_merchant_id_initial_attempt_id_index ON events (merchant_id, initial_attempt_id);

CREATE INDEX events_merchant_id_initial_events_index ON events (merchant_id, (event_id = initial_attempt_id));

CREATE INDEX events_business_profile_id_initial_attempt_id_index ON events (business_profile_id, initial_attempt_id);

CREATE INDEX events_business_profile_id_initial_events_index ON events (
business_profile_id,
(event_id = initial_attempt_id)
);

CREATE TYPE "WebhookDeliveryAttempt" AS ENUM (
'initial_attempt',
'automatic_retry',
'manual_retry'
);

ALTER TABLE events
ADD COLUMN delivery_attempt "WebhookDeliveryAttempt" DEFAULT NULL;

-- Your SQL goes here
ALTER TABLE authentication
ADD COLUMN profile_id VARCHAR(64) NOT NULL;

-- Your SQL goes here
ALTER TABLE authentication
ADD COLUMN payment_id VARCHAR(255);

-- Your SQL goes here
ALTER TYPE "DashboardMetadata"
ADD VALUE IF NOT EXISTS 'onboarding_survey';

-- Your SQL goes here
ALTER TABLE authentication
ADD COLUMN merchant_connector_id VARCHAR(128) NOT NULL;

</pre>
</details>

> [!CAUTION]
> Proceed with caution when running the following migrations as they are destructive.

<details><summary>Click here to view database migrations to be run after the newer version is deployed</summary>
<pre>
-- Running these queries can even be deferred for some time (a couple of weeks or even a month) until the
-- new version being deployed is considered stable.
-- Make `event_id` primary key instead of `id`
ALTER TABLE events DROP CONSTRAINT events_pkey;

ALTER TABLE events ADD PRIMARY KEY (event_id);

ALTER TABLE events DROP CONSTRAINT event_id_unique;

-- Dropping unused columns
ALTER TABLE events
DROP COLUMN id,
DROP COLUMN intent_reference_id;

</pre>
</details>

#### Configuration Changes

Diff of configuration changes between <code>v1.107.0</code> and <code>v1.108.0</code>

```patch
diff --git a/config/deployments/production.toml b/config/deployments/production.toml
index 4be067dade24..1bc4319b2d37 100644
--- a/config/deployments/production.toml
+++ b/config/deployments/production.toml
@@ -17,13 +17,15 @@ payout_connector_list = "wise"

 [connectors]
 aci.base_url = "https://eu-test.oppwa.com/"
-adyen.base_url = "https://{{merchant_endpoint_prefix}}-checkout-live.adyenpayments.com/"
+adyen.base_url = "https://{{merchant_endpoint_prefix}}-checkout-live.adyenpayments.com/checkout/"
 adyen.secondary_base_url = "https://{{merchant_endpoint_prefix}}-pal-live.adyenpayments.com/"
 airwallex.base_url = "https://api-demo.airwallex.com/"
 applepay.base_url = "https://apple-pay-gateway.apple.com/"
-authorizedotnet.base_url = "https://apitest.authorize.net/xml/v1/request.api"
+authorizedotnet.base_url = "https://api.authorize.net/xml/v1/request.api"
 bambora.base_url = "https://api.na.bambora.com"
 bankofamerica.base_url = "https://api.merchant-services.bankofamerica.com/"
+billwerk.base_url = "https://api.reepay.com/"
+billwerk.secondary_base_url = "https://card.reepay.com/"
 bitpay.base_url = "https://bitpay.com"
 bluesnap.base_url = "https://ws.bluesnap.com/"
 bluesnap.secondary_base_url = "https://pay.bluesnap.com/"
@@ -37,6 +39,7 @@ cryptopay.base_url = "https://business.cryptopay.me/"
 cybersource.base_url = "https://api.cybersource.com/"
 dlocal.base_url = "https://sandbox.dlocal.com/"
 dummyconnector.base_url = "http://localhost:8080/dummy-connector"
+ebanx.base_url = "https://sandbox.ebanxpay.com/"
 fiserv.base_url = "https://cert.api.fiservapps.com/"
 forte.base_url = "https://sandbox.forte.net/api/v3"
 globalpay.base_url = "https://apis.sandbox.globalpay.com/ucp/"
@@ -80,6 +83,9 @@ worldline.base_url = "https://eu.sandbox.api-ingenico.com/"
 worldpay.base_url = "https://try.access.worldpay.com/"
 zen.base_url = "https://api.zen.com/"
 zen.secondary_base_url = "https://secure.zen.com/"
+zsl.base_url = "https://api.sitoffalb.net/"
+threedsecureio.base_url = "https://service.3dsecure.io"
+netcetera.base_url = "https://{{merchant_endpoint_prefix}}.3ds-server.prev.netcetera-cloud-payment.ch"

 [delayed_session_response]
 connectors_with_delayed_session_response = "trustpay,payme"
@@ -102,7 +108,7 @@ refund_retrieve_duration = 500
 refund_retrieve_tolerance = 100
 refund_tolerance = 100
 refund_ttl = 172800
-slack_invite_url = "https://join.slack.com/t/hyperswitch-io/shared_invite/zt-1k6cz4lee-SAJzhz6bjmpp4jZCDOtOIg"
+slack_invite_url = "https://join.slack.com/t/hyperswitch-io/shared_invite/zt-2awm23agh-p_G5xNpziv6yAiedTkkqLg"

 [frm]
 enabled = false
@@ -111,11 +117,11 @@ enabled = false
 bank_debit.ach.connector_list = "gocardless"
 bank_debit.becs.connector_list = "gocardless"
 bank_debit.sepa.connector_list = "gocardless"
-card.credit.connector_list = "stripe,adyen,authorizedotnet,cybersource,globalpay,worldpay,multisafepay,nmi,nexinets,noon"
-card.debit.connector_list = "stripe,adyen,authorizedotnet,cybersource,globalpay,worldpay,multisafepay,nmi,nexinets,noon"
+card.credit.connector_list = "stripe,adyen,authorizedotnet,cybersource,globalpay,worldpay,multisafepay,nmi,nexinets,noon,bankofamerica"
+card.debit.connector_list = "stripe,adyen,authorizedotnet,cybersource,globalpay,worldpay,multisafepay,nmi,nexinets,noon,bankofamerica"
 pay_later.klarna.connector_list = "adyen"
-wallet.apple_pay.connector_list = "stripe,adyen,cybersource,noon"
-wallet.google_pay.connector_list = "stripe,adyen,cybersource"
+wallet.apple_pay.connector_list = "stripe,adyen,cybersource,noon,bankofamerica"
+wallet.google_pay.connector_list = "stripe,adyen,cybersource,bankofamerica"
 wallet.paypal.connector_list = "adyen"
 bank_redirect.ideal.connector_list = "stripe,adyen,globalpay"
 bank_redirect.sofort.connector_list = "stripe,adyen,globalpay"
@@ -285,6 +291,9 @@ pse = { country = "CO", currency = "COP" }
 red_compra = { country = "CL", currency = "CLP" }
 red_pagos = { country = "UY", currency = "UYU" }

+[pm_filters.zsl]
+local_bank_transfer = { country = "CN", currency = "CNY" }
+
 [temp_locker_enable_config]
 bluesnap.payment_method = "card"
 nuvei.payment_method = "card"
@@ -304,9 +313,13 @@ payme = { long_lived_token = false, payment_method = "card" }
 square = { long_lived_token = false, payment_method = "card" }
 stax = { long_lived_token = true, payment_method = "card,bank_debit" }
 stripe = { long_lived_token = false, payment_method = "wallet", payment_method_type = { list = "google_pay", type = "disable_only" } }
+billwerk = {long_lived_token = false, payment_method = "card"}

 [webhooks]
 outgoing_enabled = true

 [webhook_source_verification_call]
 connectors_with_webhook_source_verification_call = "paypal"
+
+[unmasked_headers]
+keys = "user-agent"
```

**Full Changelog:** [`v1.107.0...v1.108.0`](https://github.com/juspay/hyperswitch/compare/v1.107.0...v1.108.0)

### [Hyperswitch Control Center v1.30.0 (2024-05-06)](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.30.0)

**Product Name**: [Hyperswitch-control-center](https://github.com/juspay/hyperswitch-control-center)  
**Version**: [v1.30.0](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.30.0)
**Release Date**: 03-05-2024
We are excited to release the latest version of the Hyperswitch control center! This release represents yet another achievement in our ongoing efforts to deliver a flexible, cutting-edge, and community-focused payment solution.

#### New Features:

- Global search using identifiers is now available in the control center!([#523](https://github.com/juspay/hyperswitch-control-center/pull/523))
- Configure whether to show payment methods based on country and currency ([#495](https://github.com/juspay/hyperswitch-control-center/pull/495))
- Configure 3DS authenticators directly from the control center([#444](https://github.com/juspay/hyperswitch-control-center/pull/444), [#491](https://github.com/juspay/hyperswitch-control-center/pull/491))
- Audit logs are now available for all the connectors ([#538](https://github.com/juspay/hyperswitch-control-center/pull/538))
- Added dispute analytics module ([#470](https://github.com/juspay/hyperswitch-control-center/pull/470))

#### Improvements:

- Added ability to update profile name and made UX improvements ([#610](https://github.com/juspay/hyperswitch-control-center/pull/610), [#566](https://github.com/juspay/hyperswitch-control-center/pull/566))
- Added more connectors in the control center ([#578](https://github.com/juspay/hyperswitch-control-center/pull/578), [#561](https://github.com/juspay/hyperswitch-control-center/pull/561))

#### Bugs:

- Added delete 3DS rule ([#534](https://github.com/juspay/hyperswitch-control-center/pull/534))
- Minor UI fixes ([#582](https://github.com/juspay/hyperswitch-control-center/pull/582), [#584](https://github.com/juspay/hyperswitch-control-center/pull/584), [#582](https://github.com/juspay/hyperswitch-control-center/pull/582))

#### Compatibility:

- **App server Version**: [v1.108.0](https://github.com/juspay/hyperswitch/releases/tag/v1.108.0)
- **Web Version**: [v0.35.4](https://github.com/juspay/hyperswitch-web/releases/tag/v0.35.4)

### [Hyperswitch Web Client v0.35.4 (2024-05-06)](https://github.com/juspay/hyperswitch-web/releases/tag/v0.35.4)

- fix(boleto): boleto Icon fill color and size fix ([#210](https://github.com/juspay/hyperswitch-web/pull/210))
- refactor: start using @rescript/core package ([#205](https://github.com/juspay/hyperswitch-web/pull/205))
- feat(PaymentElement): moved SavedCards component outside card form ([#197](https://github.com/juspay/hyperswitch-web/pull/197))
- feat: props divide disableSave cards to checkbox and api ([#206](https://github.com/juspay/hyperswitch-web/pull/206))
- fix: added Wallets to Saved Payment Methods ([#213](https://github.com/juspay/hyperswitch-web/pull/213))
- feat: Support to handle confirm button (E2E) ([#198](https://github.com/juspay/hyperswitch-web/pull/198))
- feat: Added Payment Session Headless ([#209](https://github.com/juspay/hyperswitch-web/pull/209))
- fix: card payment customer_acceptance ([#220](https://github.com/juspay/hyperswitch-web/pull/220))
- refactor: refactor masking logic ([#219](https://github.com/juspay/hyperswitch-web/pull/219))
- refactor: library update ([#216](https://github.com/juspay/hyperswitch-web/pull/216))
- fix: added ordering for saved payment methods ([#222](https://github.com/juspay/hyperswitch-web/pull/222))
- fix: disable and enable Pay now button ([#221](https://github.com/juspay/hyperswitch-web/pull/221))
- fix: pay now button text & theme based changes ([#223](https://github.com/juspay/hyperswitch-web/pull/223))
- feat: cvc nickname gpay ([#224](https://github.com/juspay/hyperswitch-web/pull/224))
- feat: added prop for PaymentHeader Text ([#226](https://github.com/juspay/hyperswitch-web/pull/226))
- fix(ideal): bank name not being populated ([#227](https://github.com/juspay/hyperswitch-web/pull/227))
- fix: added paymentType to be passed in the confirm body ([#228](https://github.com/juspay/hyperswitch-web/pull/228))
- fix(PayNowButton): update loader and disable states of pay now button after confirm ([#229](https://github.com/juspay/hyperswitch-web/pull/229))
- fix: not require_cvc disable the pay now button ([#230](https://github.com/juspay/hyperswitch-web/pull/230))
- fix: react hook errors ([#225](https://github.com/juspay/hyperswitch-web/pull/225))
- refactor: rescript core changes json, dict, string, nullable & array ([#212](https://github.com/juspay/hyperswitch-web/pull/212))
- refactor: Update rescript v11 ([#232](https://github.com/juspay/hyperswitch-web/pull/232))
- chore: formatting rescript code ([#234](https://github.com/juspay/hyperswitch-web/pull/234))
- fix(applepay): added logger instance for ApplePay intent calls ([#218](https://github.com/juspay/hyperswitch-web/pull/218))
- chore: react useeffect changes for useeffect0 ([#237](https://github.com/juspay/hyperswitch-web/pull/237))
- fix: saved Payment Method stuck in loading state and Card Holder Name for every saved card ([#241](https://github.com/juspay/hyperswitch-web/pull/241))
- fix: hotfix changes for postal code ([#245](https://github.com/juspay/hyperswitch-web/pull/245))
- fix(savedcarditem): fixed Dynamic Fields not rendering for some saved… ([#246](https://github.com/juspay/hyperswitch-web/pull/246))
- feat: 3DS without redirection ([#249](https://github.com/juspay/hyperswitch-web/pull/249))
- fix: applePay Dynamic Fields Error Handling and Dynamic Fields PostalCode Error ([#250](https://github.com/juspay/hyperswitch-web/pull/250))
- fix(3ds method iframe): 3ds failing with no cors and color depth … ([#253](https://github.com/juspay/hyperswitch-web/pull/253))
- fix: add saved payment methods throughout checkout ([#254](https://github.com/juspay/hyperswitch-web/pull/254))
- feat(logger): calculate loading latency from iframe init to render ([#248](https://github.com/juspay/hyperswitch-web/pull/248))
- fix: pk_dev added for development purpose ([#259](https://github.com/juspay/hyperswitch-web/pull/259))
- chore: promise core changes ([#236](https://github.com/juspay/hyperswitch-web/pull/236))
- chore: useCallback changes from 0-7 to useCallback ([#240](https://github.com/juspay/hyperswitch-web/pull/240))
- chore: useMemo changes from 0-7 to useMemo ([#239](https://github.com/juspay/hyperswitch-web/pull/239))

**Full Changelog**: https://github.com/juspay/hyperswitch-web/compare/v0.27.2...v0.35.4

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

#### Features

- **router:** Use only card number for card duplication check ([#57](https://github.com/juspay/hyperswitch-card-vault/pull/57))

#### Miscellaneous Tasks

- **deps:** Update version of aws dependencies ([#54](https://github.com/juspay/hyperswitch-card-vault/pull/54))
- **utils:**
  - Add jwe operations in utils binary ([#60](https://github.com/juspay/hyperswitch-card-vault/pull/60))
  - Fix jwe operations in utils binary ([#61](https://github.com/juspay/hyperswitch-card-vault/pull/61))

**Full Changelog:** [`v0.1.3...v0.2.0`](https://github.com/juspay/hyperswitch-card-vault/compare/v0.1.3...v0.2.0)
