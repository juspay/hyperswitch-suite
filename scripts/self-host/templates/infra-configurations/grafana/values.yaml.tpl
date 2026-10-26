# Grafana values — PVC storage, loki + victoria-metrics datasources.
persistence:
  enabled: true
  size: 10Gi
  storageClassName: ebs-gp3

# Set the admin password via a pre-created secret (see SELF_HOST.md):
#   kubectl -n monitoring create secret generic grafana-admin \
#     --from-literal=admin-user=admin --from-literal=admin-password=<strong-password>
admin:
  existingSecret: grafana-admin
  userKey: admin-user
  passwordKey: admin-password

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Loki
        type: loki
        url: http://loki-gateway.loki.svc.cluster.local
        access: proxy
      - name: VictoriaMetrics
        type: prometheus
        url: http://vmsingle-vm.monitoring.svc.cluster.local:8429
        access: proxy
        isDefault: true
