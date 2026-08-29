# Istio (in-repo umbrella chart at helm/charts/istio) values for a
# single-cluster self-host deployment.
services:
  istioBase:
    enabled: true
  istiod:
    enabled: true
  istioGateway:
    enabled: true

istioGateway:
  name: istio-ingressgateway
  service:
    type: ClusterIP

# Gateway resource routing the public domains into the mesh
gateways:
  - name: hyperswitch-gateway
    servers:
      - hosts:
          - __ROUTER_DOMAIN__
          - __SDK_DOMAIN__
          - __CONTROL_CENTER_DOMAIN__
        port:
          name: http
          number: 80
          protocol: HTTP

# ALB in front of the istio ingress gateway
ingress:
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/certificate-arn: __ACM_CERT_ARN__
    alb.ingress.kubernetes.io/healthcheck-path: /healthz/ready
    alb.ingress.kubernetes.io/healthcheck-port: "15021"
  hosts:
    - host: __ROUTER_DOMAIN__
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: istio-ingressgateway
              port:
                number: 80
    - host: __SDK_DOMAIN__
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: istio-ingressgateway
              port:
                number: 80
    - host: __CONTROL_CENTER_DOMAIN__
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: istio-ingressgateway
              port:
                number: 80
