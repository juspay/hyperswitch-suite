## ApplicationSet for Istio (in-repo chart at helm/charts/istio)
applicationsets:
  istio:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: istio
      app.kubernetes.io/part-of: infra
    generators:
      - list:
          elements:
            - cluster: __MERCHANT_NAME__
              server: https://kubernetes.default.svc
              namespace: istio-system
              releaseName: istio
              chartVersion: main
              environment: __ENVIRONMENT__
              s3Bucket: __STATE_BUCKET__
              region: __AWS_REGION__
              infraValues: values.yaml
    template:
      metadata:
        name: 'istio-{{cluster}}'
        labels:
          app.kubernetes.io/name: istio
          app.kubernetes.io/part-of: infra
      spec:
        project: infra
        sources:
          - repoURL: __MERCHANT_REPO_URL__
            targetRevision: '{{chartVersion}}'
            path: helm/charts/istio
            helm:
              releaseName: '{{releaseName}}'
              parameters:
                - name: $tfstate.eks
                  value: 's3://{{s3Bucket}}/{{environment}}/{{region}}/application-stack/eks-01/terraform.tfstate'
              valueFiles:
                - '$values/infra-configurations/istio/{{infraValues}}'
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
          - group: admissionregistration.k8s.io
            kind: ValidatingWebhookConfiguration
            managedFieldsManagers:
              - pilot-discovery
