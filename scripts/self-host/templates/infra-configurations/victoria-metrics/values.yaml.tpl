# VictoriaMetrics k8s stack values — single-instance with PVC retention.
# Includes vmagent (metrics scraping) and vmsingle (storage); grafana comes
# from the standalone grafana app instead of this chart's subchart.
vmsingle:
  enabled: true
  spec:
    retentionPeriod: "30d"
    storage:
      storageClassName: ebs-gp3
      resources:
        requests:
          storage: 50Gi

vmagent:
  enabled: true

alertmanager:
  enabled: false

grafana:
  enabled: false

defaultDashboards:
  enabled: false
