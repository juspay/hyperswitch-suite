## ApplicationSet for Loki (log store, single-binary + PVC storage)
applicationsets:
  loki:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: loki
      app.kubernetes.io/part-of: monitoring
    generators:
      - list:
          elements:
            - cluster: __MERCHANT_NAME__
              server: https://kubernetes.default.svc
              namespace: loki
              releaseName: loki
              chartVersion: "6.46.0"
              infraValues: values.yaml
    template:
      metadata:
        name: 'loki-{{cluster}}'
        labels:
          app.kubernetes.io/name: loki
          app.kubernetes.io/part-of: monitoring
      spec:
        project: monitoring
        sources:
          - repoURL: https://grafana.github.io/helm-charts
            chart: loki
            targetRevision: '{{chartVersion}}'
            helm:
              releaseName: '{{releaseName}}'
              valueFiles:
                - '$values/infra-configurations/loki/{{infraValues}}'
          - repoURL: __MERCHANT_REPO_URL__
            targetRevision: main
            ref: values
        destination:
          server: '{{server}}'
          namespace: '{{namespace}}'
        syncPolicy:
          syncOptions:
            - CreateNamespace=true
            - ServerSideApply=true
