## ApplicationSet for Karpenter (optional skeleton — review before enabling).
## Requires the Karpenter controller IAM role / instance profile and an
## interruption SQS queue; see https://karpenter.sh/docs/getting-started/.
applicationsets:
  karpenter:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: karpenter
      app.kubernetes.io/part-of: infra
    generators:
      - list:
          elements:
            - cluster: __MERCHANT_NAME__
              server: https://kubernetes.default.svc
              namespace: karpenter
              releaseName: karpenter
              chartVersion: 1.0.6
              s3Bucket: __STATE_BUCKET__
              environment: __ENVIRONMENT__
              region: __AWS_REGION__
    template:
      metadata:
        name: 'karpenter-{{cluster}}'
        labels:
          app.kubernetes.io/name: karpenter
          app.kubernetes.io/part-of: infra
      spec:
        project: infra
        sources:
          - repoURL: public.ecr.aws/karpenter
            chart: karpenter
            targetRevision: '{{chartVersion}}'
            helm:
              releaseName: '{{releaseName}}'
              parameters:
                - name: $tfstate.eks
                  value: 's3://{{s3Bucket}}/{{environment}}/{{region}}/application-stack/eks-01/terraform.tfstate'
        destination:
          server: '{{server}}'
          namespace: '{{namespace}}'
        syncPolicy:
          syncOptions:
            - CreateNamespace=true
            - ServerSideApply=true
