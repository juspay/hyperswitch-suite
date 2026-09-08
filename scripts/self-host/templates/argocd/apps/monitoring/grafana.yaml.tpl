## ApplicationSet for Grafana
applicationsets:
  grafana:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: grafana
      app.kubernetes.io/part-of: monitoring
    generators:
      - list:
          elements:
            - cluster: __MERCHANT_NAME__
              server: https://kubernetes.default.svc
              namespace: monitoring
              releaseName: grafana
              chartVersion: "12.11.1"
              infraValues: values.yaml
    template:
      metadata:
        name: 'grafana-{{cluster}}'
        labels:
          app.kubernetes.io/name: grafana
          app.kubernetes.io/part-of: monitoring
      spec:
        project: monitoring
        sources:
          - repoURL: https://grafana-community.github.io/helm-charts
            chart: grafana
            targetRevision: '{{chartVersion}}'
            helm:
              releaseName: '{{releaseName}}'
              valueFiles:
                - '$values/infra-configurations/grafana/{{infraValues}}'
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
