# loki (OCI)

The narrowest module in the observability trio: a chunk bucket, the identity
that reads and writes it, and an ingress boundary for the query path.

## Three things to know

1. **No `role_arn`, no policy object.** This module emits `policy_statements` —
   exactly **one** statement per cluster, `manage objects` scoped to the chunk
   bucket — which the caller concatenates into the ONE shared,
   environment-scoped policy owned by `oke-workload-identity`. `manage`, not
   `use`: `PutObject` needs `OBJECT_CREATE` and only `manage` grants it.

2. **The NSG is created empty, and that is the design.** On AWS the module
   builds four security objects, one a rule written onto the *externally-owned*
   EKS node security group. On OCI this module owns the NSG object and nothing
   else; `composition/security-rules`, in the security-last phase, writes the
   frontend rules **and** the LB-to-node-pool rule AWS's `alb-controller`
   managed automatically. `eks_node_security_group_id` and any
   `nsg_ingress_rules` variable are deliberately absent — splitting the rule set
   across two modules reintroduces the dependency cycle the split exists to
   break.

3. **The bucket-notification hook is not ported.** AWS's
   `s3.event_notifications` is `[]` in the one live unit — the hook exists in
   the variable surface and nothing turns it on. Its OCI translation is not
   free: `oci_events_rule` cannot target the Queue service, so the nearest path
   runs through Streaming's Kafka endpoint, which authenticates with a static
   user-bound OCI auth token. Porting a dead knob would import an
   identity-model exception into a module that today has none. If a consumer
   ever needs it, the pattern is built and commented in
   `application-resources/vector/notification.tf`.

## `force_destroy` does not exist

`oci_objectstorage_bucket` has no such argument and a non-empty bucket cannot be
deleted by the resource (409). Teardown is two steps:

```
oci os object bulk-delete --bucket-name <name> --namespace <namespace>
terraform destroy
```

## Open question

Does an OCI Load Balancer front Loki's query path, or does ingress arrive
through the Istio mesh? The AWS module's `-alb-sg` naming and its 8080
LB-to-pod rule assume a dedicated load balancer. If OCI routes through the mesh,
`create_nsg` should be false and the boundary folds into the gateway's NSG.