## Ref: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/
projects:
  monitoring:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: monitoring
      app.kubernetes.io/part-of: monitoring

    description: "Observability stack (loki, grafana, victoria-metrics, vector)"

    sourceRepos:
      - "__MERCHANT_REPO_URL__"
      - "https://grafana.github.io/helm-charts"
      - "https://grafana-community.github.io/helm-charts"
      - "https://victoriametrics.github.io/helm-charts"
      - "https://helm.vector.dev"

    destinations:
      - namespace: "monitoring"
        server: "https://kubernetes.default.svc"
      - namespace: "loki"
        server: "https://kubernetes.default.svc"
      - namespace: "vector"
        server: "https://kubernetes.default.svc"

    clusterResourceWhitelist:
      - group: '*'
        kind: '*'
