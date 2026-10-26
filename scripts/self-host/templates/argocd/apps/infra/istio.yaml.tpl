## ApplicationSet for Istio (upstream charts: base CRDs + istiod control plane)
## Sync order: istio-base first, then istiod.
## The hyperswitch services expose their own ALB ingresses, so the istio
## ingress gateway is not installed by default — to add it, append an element
## with chart `gateway` (same repo/version) and a values file for it.
applicationsets:
  istio:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: istio
      app.kubernetes.io/part-of: infra
    generators:
      - list:
          elements:
            - component: base
              chart: base
              releaseName: istio-base
              server: https://kubernetes.default.svc
              namespace: istio-system
              chartVersion: "1.28.2"
              infraValues: base-values.yaml
            - component: istiod
              chart: istiod
              releaseName: istiod
              server: https://kubernetes.default.svc
              namespace: istio-system
              chartVersion: "1.28.2"
              infraValues: istiod-values.yaml
    template:
      metadata:
        name: 'istio-{{component}}'
        labels:
          app.kubernetes.io/name: 'istio-{{component}}'
          app.kubernetes.io/part-of: infra
      spec:
        project: infra
        sources:
          - repoURL: https://istio-release.storage.googleapis.com/charts
            chart: '{{chart}}'
            targetRevision: '{{chartVersion}}'
            helm:
              releaseName: '{{releaseName}}'
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
