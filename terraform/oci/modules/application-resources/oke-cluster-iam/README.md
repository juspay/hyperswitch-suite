# -----------------------------------------------------------------------------
# oke-cluster-iam - the OKE control-plane (cluster-service-principal) IAM.
#
# WHY THIS MODULE EXISTS, SEPARATELY FROM `oke-workload-identity`:
#
# OKE runs ONE Cloud Controller Manager (CCM) on the cluster control plane. When
# a Kubernetes Service of type LoadBalancer is reconciled, the CCM calls the OCI
# VirtualNetwork / LoadBalancer APIs as the CLUSTER SERVICE PRINCIPAL
# (`request.principal.type = 'cluster'`), NOT as a workload and NOT as an
# instance principal.
#
# Oracle's built-in CCM therefore requires explicit, compartment-scoped grants
# to create/place a load balancer in a specific subnet and attach it to a
# specific NSG. The two canonical statements (Oracle, "Configuring Load
# Balancers and Network Load Balancers"):
#
#   allow any-user to manage network-security-groups in compartment id <oci>
#     where request.principal.type = 'cluster'
#   allow any-user to manage vcns in compartment id <oci>
#     where request.principal.type = 'cluster'
#
# (`manage virtual-network-family ... where request.principal.type='cluster'` is
# an equivalent alternative to `manage vcns`.)
#
# These grants CANNOT live in `oke-workload-identity` (or `shared-policy`): that
# module's plan-time fail-open guard rejects any statement that names
# `any-user` without the `request.principal.type='workload'` condition, and
# `request.principal.type='cluster'` is deliberately not that. Mixing the two
# principal types into one object weakens the guard and muddies the audit
# surface. So the cluster-principal grants get their OWN `oci_identity_policy`
# object, one per environment, exactly as this module's sibling does.
#
# The AWS analogue is the EKS cluster IAM role (`aws_eks_cluster.role_arn` +
# AmazonEKSClusterPolicy), which AWS attaches during cluster creation - bundled
# into bring-up rather than a separate file. GKE's analogue is Google-owned: the
# managed control plane provisions L4 load balancers with Google's own service
# credentials, needing no user IAM at all. OKE ships neither: the grant is a
# deliberate, explicitly-authored, compartment-scoped admin step (fail-closed by
# explicit policy). On OKE every k8s Service of type LoadBalancer will fail with
# `VirtualNetwork 404 NotAuthorizedOrNotFound` until this policy exists.
#
# The GKE/`oke-workload-identity`-style "one object per environment, statements
# contributed by callers" shape is reused for the same structural reasons:
# `oci_identity_policy.name` is unique across the ENTIRE tenancy and is NOT
# updatable, so one object per environment is the only tenancy-limit-safe
# layout. Callers contribute raw statements via `statements`; the module
# normalises, sorts (`sort`+`distinct` for a stable plan), and guards them.
# -----------------------------------------------------------------------------