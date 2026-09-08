## ApplicationSet for the External Secrets Operator (optional)
applicationsets:
  external-secrets-operator:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: external-secrets-operator
      app.kubernetes.io/part-of: infra
    generators:
      - list:
          elements:
            - cluster: __MERCHANT_NAME__
              server: https://kubernetes.default.svc
              namespace: external-secrets
              releaseName: external-secrets
              chartVersion: 0.10.4
    template:
      metadata:
        name: 'external-secrets-operator-{{cluster}}'
        labels:
          app.kubernetes.io/name: external-secrets-operator
          app.kubernetes.io/part-of: infra
      spec:
        project: infra
        sources:
          - repoURL: https://charts.external-secrets.io
            chart: external-secrets
            targetRevision: '{{chartVersion}}'
            helm:
              releaseName: '{{releaseName}}'
        destination:
          server: '{{server}}'
          namespace: '{{namespace}}'
        syncPolicy:
          syncOptions:
            - CreateNamespace=true
            - ServerSideApply=true
