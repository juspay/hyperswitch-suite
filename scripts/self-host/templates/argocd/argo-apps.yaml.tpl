# ===========================================================================
#                     ROOT APP-OF-APPS (argocd-apps chart)
# ===========================================================================
# Rendered by scripts/self-host/generate.sh. This is a values file for the
# argoproj argocd-apps Helm chart; install-argocd.sh installs it, after which
# it self-manages from the git repo below.
## Ref: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/
applications:
  argoapps:
    namespace: argocd
    additionalLabels:
      app.kubernetes.io/name: argoapps
      app.kubernetes.io/part-of: argocd
    project: infra

    # Multiple sources approach (ArgoCD v2.6+)
    sources:
      # Primary source: Helm chart repository
      - repoURL: https://argoproj.github.io/argo-helm
        chart: argocd-apps
        targetRevision: 2.0.5
        helm:
          releaseName: argoapps
          # Reference values from the second source using the $values prefix
          valueFiles:
            # Base file (this file)
            - $values/argocd/argo-apps.yaml
            # ArgoCD self-management
            - $values/argocd/bootstrap/argocd.yaml
            # Projects
            - $values/argocd/projects/infra.yaml
            - $values/argocd/projects/hyperswitch.yaml
            - $values/argocd/projects/monitoring.yaml
            # Infra applications
            - $values/argocd/apps/infra/alb-controller.yaml
            - $values/argocd/apps/infra/istio.yaml__OPTIONAL_APP_VALUEFILES__
            # Hyperswitch applications (superposition is bundled in the stack chart)
            - $values/argocd/apps/hyperswitch/hyperswitch-stack.yaml
            # Monitoring applications
            - $values/argocd/apps/monitoring/loki.yaml
            - $values/argocd/apps/monitoring/grafana.yaml
            - $values/argocd/apps/monitoring/victoria-metrics.yaml
            - $values/argocd/apps/monitoring/vector.yaml

      # Secondary source: this repo (your fork)
      - repoURL: __MERCHANT_REPO_URL__
        targetRevision: main
        ref: values

    destination:
      server: https://kubernetes.default.svc
      namespace: argocd

    syncPolicy:
      automated:
        enabled: true
        prune: true
      syncOptions:
        - ServerSideApply=true

    info:
      - name: "Environment"
        value: "__ENVIRONMENT__"

applicationsets: {}
itemTemplates: []
extensions: {}
