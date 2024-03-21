<p align="center">
  <img src="./img/hyperswitch-logo-dark.svg#gh-dark-mode-only" alt="Hyperswitch-Logo" width="40%" />
  <img src="./img/hyperswitch-logo-light.svg#gh-light-mode-only" alt="Hyperswitch-Logo" width="40%" />
</p>

<h1 align="center">The open-source payments switch</h1>

<div align="center" >
The single API to access payment ecosystems across 130+ countries</div>

<p align="center">
  <a href="#supported-features">Supported Features</a> •
  <a href="#whats-included">What's Included</a> •
  <a href="#join-us-in-building-hyperswitch">Join us in building HyperSwitch</a> •
  <a href="#community">Community</a> •
  <a href="#versioning">Versioning</a> •
  <a href="#copyright-and-license">Copyright and License</a>
</p>

---

<p align="center">
<img src="./img/switch.png" alt="Hyperswitch as a switch integrating multiple payment processors" width="80%">
</p>

Hyperswitch is a community-led, open payments switch to enable access to the
best payments infrastructure for every digital business.

Using Hyperswitch, you can:

- ⬇️ **Reduce dependency** on a single processor like Stripe or Braintree
- 🧑‍💻 **Reduce Dev effort** by 90% to add & maintain integrations
- 🚀 **Improve success rates** with seamless failover and auto-retries
- 💸 **Reduce processing fees** with smart routing
- 🎨 **Customize payment flows** with full visibility and control
- 🌐 **Increase business reach** with local/alternate payment methods

<p align="center">
<img src="./img/hyperswitch-product.png" alt="Hyperswitch-Product" width="50%"/>
</p>

## Supported Features

### Supported Payment Processors and Methods

As of March 2024, we support 50+ payment processors and multiple global payment
methods.
In addition, we are continuously integrating new processors based on their reach
and community requests.
You can find the latest list of payment processors, supported methods, and
features [here][supported-connectors-and-features].

[supported-connectors-and-features]: https://hyperswitch.io/pm-list

### Hosted Version

In addition to all the features of the open-source product, our hosted version
provides features and support to manage your payment infrastructure, compliance,
analytics, and operations end-to-end:

- **System Performance & Reliability**

  - Scalable to support 50000 tps
  - System uptime of up to 99.99%
  - Deployment with very low latency
  - Hosting option with AWS or GCP

- **Value Added Services**

  - Compliance Support, incl. PCI, GDPR, Card Vault etc
  - Customize the integration or payment experience
  - Control Center with elaborate analytics and reporting
  - Integration with Risk Management Solutions
  - Integration with other platforms like Subscription, E-commerce, Accounting,
    etc.

- **Enterprise Support**

  - 24x7 Email / On-call Support
  - Dedicated Relationship Manager
  - Custom dashboards with deep analytics, alerts, and reporting
  - Expert team to consult and improve business metrics

You can [try the hosted version in our sandbox][dashboard].

[dashboard]: https://app.hyperswitch.io/register

## What's Included?

Hyperswitch is architected as a comprehensive suite comprising multiple
components, each housed in separate repositories and open-sourced.

- At its core lies the [Hyperswitch app server][hyperswitch], serving as the
  central hub orchestrating various functionalities.
- The suite extends further with the [Hyperswitch web client][hyperswitch-web],
  responsible for collecting payment information from end-users.
- Additionally, the Hyperswitch web client offers seamless integration options,
  including a dedicated wrapper for WooCommerce merchants known as the
  [Hyperswitch WooCommerce plugin][hyperswitch-woocommerce-plugin].
- [Hyperswitch Vault][hyperswitch-card-vault] is the component that is
  responsible for storing card and other payment method details securely in a
  PCI compliant manner away from the main app server.
- For merchants, the [Hyperswitch Control Center][hyperswitch-control-center]
  serves as a centralized dashboard, granting access to payment data and
  analytics.
- Throughout this ecosystem, interaction predominantly occurs with the
  Hyperswitch app server, facilitating the seamless exchange of payment-related
  information.

[hyperswitch]: https://github.com/juspay/hyperswitch
[hyperswitch-web]: https://github.com/juspay/hyperswitch-web
[hyperswitch-control-center]: https://github.com/juspay/hyperswitch-control-center
[hyperswitch-card-vault]: https://github.com/juspay/hyperswitch-card-vault
[hyperswitch-woocommerce-plugin]: https://github.com/juspay/hyperswitch-woocommerce-plugin

## Join us in building Hyperswitch

### Our Belief

> Payments should be open, fast, reliable and affordable to serve
> the billions of people at scale.

Globally payment diversity has been growing at a rapid pace.
There are hundreds of payment processors and new payment methods like BNPL,
RTP etc.
Businesses need to embrace this diversity to increase conversion, reduce cost
and improve control.
But integrating and maintaining multiple processors needs a lot of dev effort.
Why should devs across companies repeat the same work?
Why can't it be unified and reused? Hence, Hyperswitch was born to create that
reusable core and let companies build and customize it as per their specific
requirements.

### Our Values

1. Embrace Payments Diversity: It will drive innovation in the ecosystem in
   multiple ways.
2. Make it Open Source: Increases trust; Improves the quality and reusability of
   software.
3. Be community driven: It enables participatory design and development.
4. Build it like Systems Software: This sets a high bar for Reliability,
   Security and Performance SLAs.
5. Maximize Value Creation: For developers, customers & partners.

### Contributing

This project is being created and maintained by [Juspay](https://juspay.in),
South Asia's largest payments orchestrator/switch, processing more than 50
Million transactions per day. The solution has 1Mn+ lines of Haskell code built
over ten years.
Hyperswitch leverages our experience in building large-scale, enterprise-grade &
frictionless payment solutions.
It is built afresh for the global markets as an open-source product in Rust.
We are long-term committed to building and making it useful for the community.

The product roadmap is open for the community's feedback.
We shall evolve a prioritization process that is open and community-driven.
We welcome contributions from the community.
Please read through our [contributing guidelines][contributing-guidelines].
Included are directions for opening issues, coding standards, and notes on
development.
We appreciate all types of contributions: code, documentation, demo creation, or
some new way you want to contribute to us.

[contributing-guidelines]: https://github.com/juspay/hyperswitch/docs/CONTRIBUTING.md

## Community

Get updates on Hyperswitch development and chat with the community:

- [Discord server][discord] for questions related to contributing to hyperswitch,
  questions about the architecture, components, etc.
- [Slack workspace][slack] for questions related to integrating hyperswitch,
  integrating a connector in hyperswitch, etc.
- [GitHub Discussions][github-discussions] to drop feature requests or suggest
  anything payments-related you need for your stack.

[discord]: https://discord.gg/wJZ7DVW8mm
[slack]: https://join.slack.com/t/hyperswitch-io/shared_invite/zt-2awm23agh-p_G5xNpziv6yAiedTkkqLg
[github-discussions]: https://github.com/juspay/hyperswitch/discussions

<div style="display: flex;  justify-content: center;">
  <div style="margin-right:10px">
    <a href="https://www.producthunt.com/posts/hyperswitch-2" target="_blank">
      <img src="https://api.producthunt.com/widgets/embed-image/v1/top-post-badge.svg?post_id=375220&theme=light&period=weekly" alt="Hyperswitch - Fast, reliable, and affordable open source payments switch | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" />
    </a>
  </div>
  <div style="margin-right:10px">
    <a href="https://www.producthunt.com/posts/hyperswitch-2" target="_blank">
      <img src="https://api.producthunt.com/widgets/embed-image/v1/top-post-topic-badge.svg?post_id=375220&theme=light&period=weekly&topic_id=267" alt="Hyperswitch - Fast, reliable, and affordable open source payments switch | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" />
    </a>
  </div>
  <div style="margin-right:10px">
    <a href="https://www.producthunt.com/posts/hyperswitch-2" target="_blank">
      <img src="https://api.producthunt.com/widgets/embed-image/v1/top-post-topic-badge.svg?post_id=375220&theme=light&period=weekly&topic_id=93" alt="Hyperswitch - Fast, reliable, and affordable open source payments switch | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" />
    </a>
  </div>
</div>

## Versioning

Check the [CHANGELOG.md](./CHANGELOG.md) file for details.

## Copyright and License

This product is licensed under the [Apache 2.0 License](LICENSE).
