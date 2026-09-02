## Ref: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/
projects:
  hyperswitch:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: hyperswitch
      app.kubernetes.io/part-of: hyperswitch-stack

    description: "ArgoCD project for the Hyperswitch stack"

    sourceRepos:
      - "__MERCHANT_REPO_URL__"
      - "https://github.com/juspay/hyperswitch-helm"

    destinations:
      - namespace: "hyperswitch"
        server: "https://kubernetes.default.svc"

    clusterResourceWhitelist:
      - group: ''
        kind: Namespace
      - group: 'rbac.authorization.k8s.io'
        kind: ClusterRole
      - group: 'rbac.authorization.k8s.io'
        kind: ClusterRoleBinding
