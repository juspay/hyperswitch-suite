## ApplicationSet for Vector (log shipper, agent role -> loki)
applicationsets:
  vector:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: vector
      app.kubernetes.io/part-of: monitoring
    generators:
      - list:
          elements:
            - cluster: __MERCHANT_NAME__
              server: https://kubernetes.default.svc
              namespace: vector
              releaseName: vector
              chartVersion: "0.33.0"
              infraValues: values.yaml
    template:
      metadata:
        name: 'vector-{{cluster}}'
        labels:
          app.kubernetes.io/name: vector
          app.kubernetes.io/part-of: monitoring
      spec:
        project: monitoring
        sources:
          - repoURL: https://helm.vector.dev
            chart: vector
            targetRevision: '{{chartVersion}}'
            helm:
              releaseName: '{{releaseName}}'
              valueFiles:
                - '$values/infra-configurations/vector/{{infraValues}}'
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
