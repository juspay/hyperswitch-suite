# eks-kubernetes-resources (OCI) → OKE Kubernetes Resources

OCI equivalent of `terraform/aws/modules/composition/eks-kubernetes-resources`. The `kubernetes`/`helm` provider
resources (RBAC roles, namespaces, `helm_release`) are cloud-agnostic and carry over essentially unchanged; only
the cloud-specific pieces differ.

## What changed vs. the AWS module

| AWS | OCI |
|---|---|
| `data.aws_eks_cluster_auth` token | `exec` block calling `oci ce cluster generate-token` (the `oci` CLI must be installed and configured wherever Terraform runs this module) |
| StorageClass provisioner `ebs.csi.aws.com` | `blockvolume.csi.oraclecloud.com` (OKE's bundled Block Volume CSI driver) |
| Cluster Autoscaler `--cloud-provider=aws` + ASG tag auto-discovery | `--cloud-provider=oci` + explicit `--nodes=min:max:pool-ocid` per node pool (`var.cluster_autoscaler_node_pools`) — OCI has no ASG-tag-style auto-discovery mechanism for OKE node pools |
| Cluster Autoscaler IRSA role | Instance-principal dynamic group + policy scoped to the OKE cluster's OCID. Swap for OKE **Workload Identity** (`oidc_discovery_enabled` on the `../eks` module) if you need namespace/service-account-scoped credentials matching IRSA more closely — instance principals here are broader (any pod on any node in the pool where the autoscaler runs can use them unless further isolated) |
| ECR registry secret + `aws ecr get-login-password` (rotates automatically per-apply) | OCIR registry secret using a long-lived **OCI Auth Token** (`var.ocir_auth_token`) — OCIR tokens don't auto-rotate the way ECR's temporary tokens do; rotate the auth token out-of-band and re-apply, or move to a short-lived-token flow via `oci_identity_auth_token` lifecycle management |
| Cluster Autoscaler image sync from a public registry into ECR (Docker-based `local-exec` provisioner) | Not reproduced — OCI publishes official cluster-autoscaler images directly to `<region-key>.ocir.io/oracle/oci-cluster-autoscaler`, so there's no need to mirror a public image into your own registry the way the AWS module does for private-VPC air-gapped clusters. If your OKE cluster's worker subnet also has no internet/OCIR service-gateway route, add an equivalent sync step. |
