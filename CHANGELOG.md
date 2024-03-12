# Changelog

All notable changes to Hyperswitch will be documented here.

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

**Key Features**:

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

#### Bugs

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
