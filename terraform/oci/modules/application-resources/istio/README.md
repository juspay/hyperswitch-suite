# istio (OCI)

Istio gateway on OKE using the OCI Cloud Controller Manager for load-balancer
provisioning. The only module in this batch with **no cloud identity** — it
emits an empty `policy_statements` list for uniformity with its siblings.

## `alb-controller` disappears as a concept

On AWS the gateway Service is a `ClusterIP` behind a `kubernetes_ingress_v1`
with `ingress_class_name = "alb"`, resolved only because a separate module runs
the AWS Load Balancer Controller in the same cluster — this module is that
controller's only consumer.

Every OKE cluster already runs the OCI Cloud Controller Manager (CCM). A
Service of `type = LoadBalancer` becomes a real OCI Load Balancer with no Helm
chart, no IAM role and no ServiceAccount. So there is **no `Ingress` object, no
`ingress_annotations` variable, and no `alb-controller` port**. A plan that
creates an Ingress means someone reintroduced the AWS shape.

## The NSG is created empty

This module creates the NSG object, exports its OCID, and writes **no rules**,
matching the `composition/database` and `oci-cache-valkey` contract. The reason
is two asymmetrical rule groups:

- **Frontend** — 80 / 443 / 15021 inbound from the internet to this NSG.
- **Backend** — this NSG (or the LB subnet) to the **worker-node NSG** on
  NodePorts 30000-32767 and kube-proxy's health port 10256. On AWS the ALB
  controller manages this for free; on OCI nothing does.

Only `composition/security-rules` can see both this NSG and `oke`'s worker NSG,
so both groups go there. There are no `nsg_ingress_rules` variables here; do not
add them.

## The annotation you must not forget

`service.beta.kubernetes.io/oci-load-balancer-security-list-management-mode` is
set to `"None"`, unconditionally. At its CCM default of `"All"` the controller
auto-manages **VCN security list** rules to wire the LB to the NodePort range —
convenient, and exactly what the NSG-only decision forbids, because
security-list and NSG rules combine with union semantics and the widening would
appear nowhere in Terraform.

Omit the annotation and the CCM silently widens the posture; omit the
`security-rules` addition and the LB cannot reach any node (fails closed).

## No provider blocks in this module

There is no inline `provider "kubernetes"` / `provider "helm"` here. The default
providers are inherited from the live root rather than passed in as
`cluster_endpoint` / `cluster_ca_certificate`. **This is a real prerequisite**:
the root must emit `provider "helm"` and `provider "kubernetes"` against the OKE
cluster before this unit can plan.

## Unresolved forks carried, not decided

| Question | Default here | Why it is not settled |
|---|---|---|
| TLS termination: LB (`lb`) or Envoy (`nlb` + SDS)? | `lb` | Keeps certificate lifecycle in one place. |
| `externalTrafficPolicy` | unset | No precedent in either existing module. `Local` buys pod-level health checks and source-IP preservation. |
| OKE Istio cluster add-on instead of Helm? | Helm | The add-on restricts values to Oracle-approved keys and auto-upgrades istiod on Oracle's schedule. |

## Health checks coarsen

A CCM-provisioned LB targets worker-node **NodePorts**, not pod IPs, and its
default health check verifies a node can proxy for the Service (kube-proxy on
10256) rather than that a gateway pod is ready. `externalTrafficPolicy: Local`
narrows it if pod-level precision matters.

## LB subnet placement moved out

`lb_subnet_ids` is dropped. The OCI equivalent,
`oci_containerengine_cluster.options.service_lb_subnet_ids`, is a
**cluster-level** field shared by every Service-type LoadBalancer in the
cluster, and there is no per-Service subnet annotation. Placement is now
`oke`'s responsibility — harmless while the stack has one LB-subnet tier per
environment.