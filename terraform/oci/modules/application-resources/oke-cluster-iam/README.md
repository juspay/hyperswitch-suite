# oke-cluster-iam (OCI)

The OKE control-plane (cluster-service-principal) IAM policy, one object per
environment.

## Why this module exists separately from `oke-workload-identity`

OKE runs one Cloud Controller Manager (CCM) on the cluster control plane. When
a Kubernetes Service of type `LoadBalancer` is reconciled, the CCM calls the
OCI VirtualNetwork / LoadBalancer APIs as the **cluster service principal**
(`request.principal.type = 'cluster'`), not as a workload and not as an
instance principal.

Oracle's built-in CCM therefore requires explicit, compartment-scoped grants to
create/place a load balancer in a specific subnet and attach it to a specific
NSG. The two canonical statements:

```
allow any-user to manage network-security-groups in compartment id <oci>
  where request.principal.type = 'cluster'
allow any-user to manage vcns in compartment id <oci>
  where request.principal.type = 'cluster'
```

(`manage virtual-network-family ... where request.principal.type='cluster'` is
an equivalent alternative to `manage vcns`.)

These grants cannot live in `oke-workload-identity` (or `shared-policy`): that
module's plan-time fail-open guard rejects any statement that names `any-user`
without the `request.principal.type='workload'` condition, and
`request.principal.type='cluster'` is deliberately not that. Mixing the two
principal types into one object weakens the guard and muddies the audit
surface. So the cluster-principal grants get their own `oci_identity_policy`
object, one per environment.

## Why a separate object at all

`oci_identity_policy.name` is unique across the entire tenancy and is not
updatable, so one object per environment is the only tenancy-limit-safe layout.
Callers contribute raw statements via `statements`; the module normalises,
sorts (`sort` + `distinct` for a stable plan), and guards them.

On OKE every k8s Service of type `LoadBalancer` will fail with
`VirtualNetwork 404 NotAuthorizedOrNotFound` until this policy exists.