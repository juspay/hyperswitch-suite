# Hyperswitch stack (umbrella chart) values — infra layer.
#
# $<module.output>$ tokens are resolved by the ArgoCD tfstate helm plugin from
# the terraform state files declared as $tfstate.* parameters in
# argocd/apps/hyperswitch/hyperswitch-stack.yaml.
#
# NOTE: verify these value paths against the pinned hyperswitch-stack chart tag
# (__HS_CHART_VERSION__) when bumping chart versions.

services:
  router:
    host: https://__ROUTER_DOMAIN__
  sdk:
    host: https://__SDK_DOMAIN__

global:
  imageRegistry: __IMAGE_REGISTRY__

hyperswitch-app:
  # ---------------------------------------------------------------------------
  # External data stores (provisioned by the terragrunt standalone stack).
  # The chart validates that exactly one of bundled/external is enabled.
  # ---------------------------------------------------------------------------
  postgresql:
    enabled: false
  redis:
    enabled: false

  externalPostgresql:
    enabled: true
    primary:
      host: $<rds.endpoint>$
      auth:
        username: hyperswitch
        database: hyperswitch
        # Password comes from a pre-created secret (see SELF_HOST.md, secrets step)
        password:
          _secretRef:
            name: hyperswitch-db-credentials
            key: password
        plainpassword:
          _secretRef:
            name: hyperswitch-db-credentials
            key: password
    readOnly:
      enabled: true
      host: $<rds.reader_endpoint>$
      auth:
        username: hyperswitch
        database: hyperswitch
        password:
          _secretRef:
            name: hyperswitch-db-credentials
            key: password

  externalRedis:
    enabled: true
    host: $<redis.replication_group_configuration_endpoint_address>$
    auth:
      enabled: false

  # Run diesel migrations against the external database on install/upgrade
  initDB:
    enable: true

  server:
    ingress:
      enabled: true
      className: alb
      annotations:
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
        alb.ingress.kubernetes.io/ssl-redirect: "443"
        alb.ingress.kubernetes.io/certificate-arn: __ACM_CERT_ARN__
        alb.ingress.kubernetes.io/backend-protocol: HTTP
      hostname: __ROUTER_DOMAIN__

# The standalone monitoring apps (loki/grafana/victoria-metrics/vector) own
# observability; disable the bundled monitoring subchart.
hyperswitch-monitoring:
  enabled: false

# Card vault requires a locker deployment and a master-key ceremony — out of
# scope for the default self-host bundle.
hyperswitch-card-vault:
  enabled: false

hyperswitch-control-center:
  enabled: __CONTROL_CENTER_ENABLED__
  ingress:
    enabled: __CONTROL_CENTER_ENABLED__
    className: alb
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/ssl-redirect: "443"
      alb.ingress.kubernetes.io/certificate-arn: __ACM_CERT_ARN__
    hosts:
      - host: __CONTROL_CENTER_DOMAIN__
        paths:
          - path: /
            pathType: Prefix

hyperswitch-web:
  enabled: true
  ingress:
    enabled: true
    className: alb
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/ssl-redirect: "443"
      alb.ingress.kubernetes.io/certificate-arn: __ACM_CERT_ARN__
    hosts:
      - host: __SDK_DOMAIN__
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: hyperswitch-web
                port:
                  number: 80
