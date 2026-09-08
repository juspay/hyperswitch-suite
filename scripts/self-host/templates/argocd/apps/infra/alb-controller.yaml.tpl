## ApplicationSet for the AWS Load Balancer Controller
applicationsets:
  alb-controller:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: alb-controller
      app.kubernetes.io/part-of: infra
    generators:
      - list:
          elements:
            - cluster: __MERCHANT_NAME__
              server: https://kubernetes.default.svc
              namespace: kube-system
              releaseName: aws-load-balancer-controller
              chartVersion: 1.8.1
              environment: __ENVIRONMENT__
              s3Bucket: __STATE_BUCKET__
              region: __AWS_REGION__
              infraValues: values.yaml
    template:
      metadata:
        name: 'alb-controller-{{cluster}}'
        labels:
          app.kubernetes.io/name: alb-controller
          app.kubernetes.io/part-of: infra
      spec:
        project: infra
        sources:
          - repoURL: https://aws.github.io/eks-charts
            chart: aws-load-balancer-controller
            targetRevision: '{{chartVersion}}'
            helm:
              releaseName: '{{releaseName}}'
              parameters:
                - name: $tfstate.eks
                  value: 's3://{{s3Bucket}}/{{environment}}/{{region}}/application-stack/eks-01/terraform.tfstate'
              valueFiles:
                - '$values/infra-configurations/alb-controller/{{infraValues}}'
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
