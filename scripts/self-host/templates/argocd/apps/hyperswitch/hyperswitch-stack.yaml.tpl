## ApplicationSet for the Hyperswitch stack (umbrella chart)
## Shape mirrors the upstream hyperswitch deployments: a list generator with
## one element per cluster — add another element to deploy a second region.
applicationsets:
  hyperswitch:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: hyperswitch
      app.kubernetes.io/part-of: hyperswitch
    generators:
      - list:
          elements:
            - cluster: __MERCHANT_NAME__
              server: https://kubernetes.default.svc
              namespace: hyperswitch
              releaseName: hyperswitch
              chartVersion: __HS_CHART_VERSION__
              environment: __ENVIRONMENT__
              s3Bucket: __STATE_BUCKET__
              region: __AWS_REGION__
              infraValues: values.yaml
              deploymentValues: values-dep.yaml
    template:
      metadata:
        name: 'hyperswitch-{{cluster}}'
        labels:
          app.kubernetes.io/name: 'hyperswitch-{{environment}}'
          app.kubernetes.io/part-of: hyperswitch
      spec:
        project: hyperswitch
        sources:
          # Primary source: hyperswitch-stack umbrella chart
          - repoURL: https://github.com/juspay/hyperswitch-helm
            targetRevision: '{{chartVersion}}'
            path: charts/incubator/hyperswitch-stack
            helm:
              releaseName: '{{releaseName}}'
              parameters:
                - name: $tfstate.rds
                  value: 's3://{{s3Bucket}}/{{environment}}/{{region}}/database/terraform.tfstate'
                - name: $tfstate.redis
                  value: 's3://{{s3Bucket}}/{{environment}}/{{region}}/elasticache/terraform.tfstate'
                - name: $tfstate.eks
                  value: 's3://{{s3Bucket}}/{{environment}}/{{region}}/application-stack/eks-01/terraform.tfstate'
              # Reference values from the second source using the $values prefix
              valueFiles:
                - '$values/infra-configurations/hyperswitch-stack/{{infraValues}}'
                - '$values/deployment-configs/hyperswitch-stack/{{deploymentValues}}'
          # Secondary source: this repo (your fork)
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
        ignoreDifferences:
          - group: networking.istio.io
            kind: DestinationRule
            managedFieldsManagers:
              - rollouts-controller
        info:
          - name: "Documentation"
            value: "https://docs.hyperswitch.io"
