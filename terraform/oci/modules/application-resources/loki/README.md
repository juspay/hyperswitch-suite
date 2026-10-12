# loki (OCI)

The OCI port of `terraform/aws/modules/application-resources/loki`.

Check sheet: `docs/multi-cloud-parity/oci/modules/loki.md`.

The narrowest module in the observability trio: a chunk bucket, the identity
that reads and writes it, and an ingress boundary for the query path.

## Three things to know

1. **No `role_arn`, no policy object.** This module emits `policy_statements` -
   exactly **one** statement per cluster, `manage objects` scoped to the chunk
   bucket - which the caller concatenates into the ONE shared,
   environment-scoped policy owned by `oke-workload-identity`. `manage`, not
   `use`: `PutObject` needs `OBJECT_CREATE` and only `manage` grants it.

2. **The NSG is created empty, and that is the design.** AWS builds four
   security objects here, one of which is a rule written onto the
   *externally-owned* EKS node security group. On OCI this module owns the NSG
   object and nothing else; `composition/security-rules`, in the security-last
   phase, writes the frontend rules **and** the LB-to-node-pool rule that AWS's
   `alb-controller` managed automatically. `eks_node_security_group_id` and any
   `nsg_ingress_rules` variable are deliberately absent - splitting the rule set
   across two modules reintroduces the dependency cycle the split exists to
   break. Feature 6 stays FULL: this is a strategy difference, not a capability
   loss.

3. **The bucket-notification hook is not ported.** AWS's
   `s3.event_notifications` is `[]` in the one live unit - the hook exists in
   the variable surface and nothing turns it on. Its OCI translation is not
   free: `oci_events_rule` cannot target the Queue service, so the nearest path
   runs through Streaming's Kafka endpoint, which authenticates with a static
   user-bound OCI auth token. Porting a dead knob would import an
   identity-model exception into a module that today has none. If a consumer
   ever needs it, the pattern is built and commented in
   `application-resources/vector/notification.tf`. Check sheet section 4.3;
   oracle gate item, **not yet consulted**.

## `force_destroy` does not exist

`oci_objectstorage_bucket` has no such argument and a non-empty bucket cannot be
deleted by the resource (409). Teardown is two steps:

```
oci os object bulk-delete --bucket-name <name> --namespace <namespace>
terraform destroy
```

## Open question that could delete a resource from this module

Does an OCI Load Balancer actually front Loki's query path, or does ingress
arrive through the Istio mesh? The AWS module's `-alb-sg` naming and its 8080
LB-to-pod rule assume a dedicated load balancer. If OCI routes through the mesh,
`create_nsg` should be false and the boundary folds into the gateway's NSG.
Check sheet section 9 Q2.
