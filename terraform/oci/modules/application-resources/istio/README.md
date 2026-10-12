# istio (OCI)

The OCI port of `terraform/aws/modules/application-resources/istio`.

Check sheet: `docs/multi-cloud-parity/oci/modules/istio.md`.
Network model: `docs/multi-cloud-parity/oci/network-security-model.md` (Option A,
NSGs only).

The only module in this batch with **no cloud identity**. It emits an empty
`policy_statements` list for uniformity with its siblings and nothing else.

## `alb-controller` disappears as a concept

AWS deploys the gateway Service as `ClusterIP` behind a `kubernetes_ingress_v1`
with `ingress_class_name = "alb"`, which only resolves because a second module
runs the AWS Load Balancer Controller in the same cluster. This module is that
controller's only consumer in the whole platform.

Every OKE cluster already runs the OCI Cloud Controller Manager. A Service of
`type = LoadBalancer` becomes a real OCI Load Balancer with no Helm chart, no
IAM role and no ServiceAccount. So: **no `Ingress` object, no
`ingress_annotations` variable, and no `alb-controller` port** (all five of its
features land on NONE). A plan for this module that creates an Ingress means
someone reintroduced the AWS shape.

## The NSG is created empty - a divergence from this module's own check sheet

`istio.md` section 5 proposes putting the 80/443/15021 ingress rules in this
module. This module creates the NSG object, exports its OCID, and writes **no
rules**, matching `composition/database`'s and `oci-cache-valkey`'s contract.

The reason is that there are two rule groups and they are not symmetrical:

- **Frontend** - 80 / 443 / 15021 inbound from the internet to this NSG.
- **Backend** - this NSG (or the LB subnet) to the **worker-node NSG** on
  NodePorts 30000-32767 and kube-proxy's health port 10256. This has **no AWS
  analogue**: the AWS Load Balancer Controller manages the node security group's
  ingress for free. On OCI, with the CCM held out of the VCN security lists,
  nothing does.

Only `composition/security-rules` can see both this NSG and `oke`'s worker NSG,
so both groups go there. Splitting them across two modules and two phases is the
arrangement the security-last split exists to prevent. There are no
`nsg_ingress_rules` variables here; do not add them.

## The annotation you must not forget

`service.beta.kubernetes.io/oci-load-balancer-security-list-management-mode` is
set to `"None"`, unconditionally. Left at its CCM default of `"All"`, the
controller auto-manages **VCN security list** rules to wire the LB to the
NodePort range - convenient, and exactly what the NSG-only decision forbids,
because security-list and NSG rules combine with union semantics and the widening
would appear nowhere in Terraform.

The risk is shipping one half without the other. Omit the annotation and the CCM
silently widens the posture. Omit the `security-rules` addition and the LB
cannot reach any node - which fails closed.

## No provider blocks in this module

Unlike the GCP `istio`, `argocd` and `external-secrets-operator` modules, there
is no inline `provider "kubernetes"` / `provider "helm"` here. `identity-model.md`
section 2.2 records the consequence of that pattern on GCP: the modules require
`cluster_endpoint` / `cluster_ca_certificate`, the catalog units pass neither,
and "those units cannot plan as committed."

The default providers are inherited from the live root's hand-written `root.hcl`
`generate "provider"` block instead. **This is a real prerequisite**: the OCI dev
root must emit `provider "helm"` and `provider "kubernetes"` against the OKE
cluster before this unit can plan. Whether that uses
`data.oci_containerengine_kube_config` or an `exec` plugin calling `oci ce
cluster generate-token` is check sheet section 9 Q1, and should match
`oke-kubernetes-resources`.

## Unresolved forks carried, not decided

| Question | Default here | Why it is not settled |
|---|---|---|
| TLS termination: LB (`lb`) or Envoy (`nlb` + SDS)? | `lb` | AWS and GCP disagree with each other. `lb` keeps certificate lifecycle in one place. Check sheet section 9 Q2. |
| `externalTrafficPolicy` | unset | Neither existing module sets it, so neither is a precedent. `Local` buys pod-level health checks and source-IP preservation; `Cluster` is simpler. Section 9 Q3. |
| OKE Istio cluster add-on instead of Helm? | Helm | The add-on restricts values to Oracle-"approved" keys and auto-upgrades istiod on Oracle's schedule. Section 8 item 4. |

## Health checks coarsen

A CCM-provisioned LB targets worker-node **NodePorts**, not pod IPs, and its
default health check verifies a node can proxy for the Service (kube-proxy on
10256) rather than that a gateway pod is ready. AWS's ALB checks
`/healthz/ready` on 15021 against the pods directly. Coarser, still safe, and
`externalTrafficPolicy: Local` narrows it if pod-level precision matters. PARTIAL.

## LB subnet placement moved out

`lb_subnet_ids` is dropped. The OCI equivalent,
`oci_containerengine_cluster.options.service_lb_subnet_ids`, is a **cluster-level**
field shared by every Service-type LoadBalancer in the cluster, and there is no
per-Service subnet annotation. Placement is now `oke`'s responsibility - a real
narrowing of this module's authority, harmless while the stack has one LB-subnet
tier per environment.
