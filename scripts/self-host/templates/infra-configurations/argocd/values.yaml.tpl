# ArgoCD (argo-cd chart) values for a self-hosted, in-cluster deployment.
# The repoServer initContainer installs the helm tfstate downloader plugin so
# application values can reference terraform outputs via $tfstate parameters
# and $<module.output>$ interpolation.
global:
  domain: argocd.local # change to your ArgoCD domain if you expose it

configs:
  params:
    # Terminate TLS at your load balancer / port-forward instead
    server.insecure: true
  cm:
    # Track applications by annotation to survive resource renames
    application.resourceTrackingMethod: annotation+label
    timeout.reconciliation: 180s

server:
  replicas: 1

controller:
  replicas: 1

repoServer:
  replicas: 1

  # -- Init containers to add to the repo server pods
  # Installs the helm-terraform-states plugin ("$tfstate" parameters).
  initContainers:
    - name: helm-terraform-states
      image: __TFSTATE_PLUGIN_IMAGE__
      volumeMounts:
        - mountPath: /helm-working-dir
          name: helm-working-dir
      command: ["/bin/sh", "-c"]
      args:
        - |
          cp /helm-dir/helm /helm-working-dir/
          mkdir -p /helm-working-dir/plugins
          cp -r /helm-dir/plugins/* /helm-working-dir/plugins/

  # -- Use the plugin-wrapped helm binary
  volumeMounts:
    - mountPath: /usr/local/sbin/helm
      subPath: helm
      name: helm-working-dir

  env:
    # The tfstate plugin reads terraform state from S3 using the pod's AWS
    # credentials (node role by default; the eks-01 unit grants the node role
    # read access to the state bucket).
    - name: AWS_REGION
      value: __AWS_REGION__

redis:
  enabled: true

dex:
  enabled: false

notifications:
  enabled: false
