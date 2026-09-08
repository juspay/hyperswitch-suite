## Ref: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/
projects:
  infra:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: infra
      app.kubernetes.io/part-of: infra

    description: "Infrastructure applications (argocd, ingress, istio, secrets)"

    sourceRepos:
      - "__MERCHANT_REPO_URL__"
      - "https://argoproj.github.io/argo-helm"
      - "https://aws.github.io/eks-charts"
      - "https://charts.external-secrets.io"
      - "https://istio-release.storage.googleapis.com/charts"

    destinations:
      - namespace: "argocd"
        server: "https://kubernetes.default.svc"
      - namespace: "kube-system"
        server: "https://kubernetes.default.svc"
      - namespace: "istio-system"
        server: "https://kubernetes.default.svc"
      - namespace: "external-secrets"
        server: "https://kubernetes.default.svc"
      - namespace: "karpenter"
        server: "https://kubernetes.default.svc"

    clusterResourceWhitelist:
      - group: '*'
        kind: '*'
