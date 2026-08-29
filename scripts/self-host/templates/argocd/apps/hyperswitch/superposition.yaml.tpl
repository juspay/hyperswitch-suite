## ApplicationSet for Superposition (config management service)
applicationsets:
  superposition:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: superposition
      app.kubernetes.io/part-of: hyperswitch
    generators:
      - list:
          elements:
            - cluster: __MERCHANT_NAME__
              server: https://kubernetes.default.svc
              namespace: superposition
              releaseName: superposition
              chartVersion: v0.97.0
              environment: __ENVIRONMENT__
              s3Bucket: __STATE_BUCKET__
              region: __AWS_REGION__
              infraValues: values.yaml
    template:
      metadata:
        name: 'superposition-{{cluster}}'
        labels:
          app.kubernetes.io/name: superposition
          app.kubernetes.io/part-of: hyperswitch
      spec:
        project: hyperswitch
        sources:
          - repoURL: https://github.com/juspay/superposition
            targetRevision: '{{chartVersion}}'
            path: helm
            helm:
              releaseName: '{{releaseName}}'
              parameters:
                - name: $tfstate.rds
                  value: 's3://{{s3Bucket}}/{{environment}}/{{region}}/database/terraform.tfstate'
              valueFiles:
                - '$values/infra-configurations/superposition/{{infraValues}}'
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
            - PruneLast=true
