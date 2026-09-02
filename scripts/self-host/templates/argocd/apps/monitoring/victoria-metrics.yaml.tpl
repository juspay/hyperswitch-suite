## ApplicationSet for VictoriaMetrics k8s stack (metrics + vmagent + operator)
applicationsets:
  victoria-metrics:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: victoria-metrics
      app.kubernetes.io/part-of: monitoring
    generators:
      - list:
          elements:
            - cluster: __MERCHANT_NAME__
              server: https://kubernetes.default.svc
              namespace: monitoring
              releaseName: vm
              chartVersion: "0.71.1"
              infraValues: values.yaml
    template:
      metadata:
        name: 'victoria-metrics-{{cluster}}'
        labels:
          app.kubernetes.io/name: victoria-metrics
          app.kubernetes.io/part-of: monitoring
      spec:
        project: monitoring
        sources:
          - repoURL: https://victoriametrics.github.io/helm-charts
            chart: victoria-metrics-k8s-stack
            targetRevision: '{{chartVersion}}'
            helm:
              releaseName: '{{releaseName}}'
              valueFiles:
                - '$values/infra-configurations/victoria-metrics/{{infraValues}}'
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
            - RespectIgnoreDifferences=true
        ignoreDifferences:
          - group: ''
            kind: Secret
            name: vm-victoria-metrics-operator-validation
            jsonPointers:
              - /data
          - group: admissionregistration.k8s.io
            kind: ValidatingWebhookConfiguration
            jqPathExpressions:
              - '.webhooks[].clientConfig.caBundle'
