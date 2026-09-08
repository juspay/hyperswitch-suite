# ArgoCD self-management application (argo-cd Helm chart).
# install-argocd.sh installs this chart first with plain helm; once the root
# app-of-apps is synced, this Application takes over managing ArgoCD itself.
applications:
  argocd:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: argocd
      app.kubernetes.io/part-of: argocd
    project: infra

    sources:
      - repoURL: https://argoproj.github.io/argo-helm
        chart: argo-cd
        targetRevision: 9.5.13
        helm:
          releaseName: argocd
          valueFiles:
            - $values/infra-configurations/argocd/values.yaml
      - repoURL: __MERCHANT_REPO_URL__
        targetRevision: main
        ref: values

    destination:
      server: https://kubernetes.default.svc
      namespace: argocd

    syncPolicy:
      syncOptions:
        - CreateNamespace=true
        - ServerSideApply=true
