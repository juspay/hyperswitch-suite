# =============================================================================
# nsg-baseline - ownership of the four core OKE NSGs and their essential rules
# =============================================================================
# WHY THIS FILE EXISTS
#
# The vendored registry module (oracle-terraform-modules/oke) writes a
# permissive baseline into every NSG it creates: protocol "all" between pods,
# workers and the control plane, untyped ICMP to/from 0.0.0.0/0, and
# TCP/all-ports to the entire Oracle Services Network. That is the AWS
# equivalent of shipping protocol = "-1" to 0.0.0.0/0 on the node group -
# exactly what composition/eks refuses to do (node_security_group_allow_all_egress
# = false in every live root).
#
# WHAT THIS FILE DOES
#
# Takes over the four core roles (cp, workers, pods, int_lb) the way
# composition/eks does: the NSGs are ours, and the rule set is the ESSENTIAL
# set only - one protocol, one port (range), one named peer per rule, every
# rule justified against one of:
#
#   [OKE]  Oracle's own required rows for managed OKE with VCN-native pods
#          (docs.oracle.com/.../contengnetworkconfig.htm, "Security Rules for
#          the Kubernetes API Endpoint / Worker Nodes / Pod Subnets")
#   [AWS]  terraform/aws/modules/base/eks node_security_group_rules, which
#          follow docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
#   [APP]  a port our own workloads demonstrably use (deployment-configs/oci)
#
# The registry module still wires the NSGs to node pools / the cluster
# endpoint / service-LB backends, because module.network.*_nsg_id returns the
# PROVIDED id when a role is passed with create = "never" - and writes ZERO
# rules for it. That seam (var.nsg_ids) is the contract; this file is the
# caller-side realisation of it, internalised so every consumer of this module
# gets the restricted set without extra wiring.
#
# MIGRATION (applied environments)
#
# The NSGs are ADOPTED, not recreated: `moved` blocks re-home the registry's
# oci_core_network_security_group.*[0] objects into oci_core_network_security_group.baseline
# so the OCIDs never change. That matters because the OCIDs are referenced
# outside this state: the router-internal-lb Service manifest annotates its LB
# with the int_lb NSG OCID, and security-rules addresses its rules at the
# oke outputs. A recreate would orphan both.
#
# What the first apply does instead: destroys the registry's baseline RULE
# instances (module.oke.module.network.oci_core_network_security_group_security_rule.oke
# shrinks to the untouched pub_lb role) and creates the essential set below.
# Rule replacement is delete-then-create - expect a seconds-long gap on the
# paths that churn (API 6443, OKE channel 12250, kubelet 10250, DNS 53,
# NodePort 30000-32767). The data-tier rules (5432/6379/3128) are NOT here;
# they live in the security-rules unit and are untouched.
#
# SCOPE NOTE: pub_lb stays registry-managed for now (edge tier; its rules were
# not part of the pods/worker finding). Its "all to pods" egress is a known
# Phase-2 item. Add-back convention: any workload needing a port outside
# tcp/1025-65535, a non-DNS UDP port, or a webhook port outside 8443/9443 gets
# one described rule added here (or in security-rules for cross-module flows).
# =============================================================================

data "oci_core_vcn" "this" {
  vcn_id = var.vcn_id
}

# Region service CIDRs. Same idiom as the registry module's
# modules/network/datasources.tf: the "All <region> Services In Oracle
# Services Network" label is the service-gateway route target.
data "oci_core_services" "osn" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

locals {
  # The roles this file owns. pub_lb is deliberately absent - see SCOPE NOTE.
  # Static (not local.nsg_roles) so the `moved` blocks below always address a
  # declared instance; an unused role is an inert, unattached NSG.
  baseline_nsg_roles = toset(["cp", "workers", "pods", "int_lb"])

  # Peer NSG ids used as rule sources/destinations. The four baseline roles
  # come from the adopted NSGs; pub_lb is still registry-managed and is
  # referenced through the registry seam output, which returns its stable
  # OCID regardless of who created it.
  peer_nsg_ids = merge(
    { for role, nsg in oci_core_network_security_group.baseline : role => nsg.id },
    { pub_lb = module.oke.pub_lb_nsg_id },
  )

  osn_cidr = one(data.oci_core_services.osn.services[*].cidr_block)

  # Primary VCN CIDR. PMTU scoping ([AWS]: base/eks scopes Path-MTU to the
  # VCN; the registry module's untyped ICMP to 0.0.0.0/0 is broader than even
  # Oracle's own "ICMP 3,4" row).
  vcn_cidr = data.oci_core_vcn.this.cidr_block

  # -------------------------------------------------------------------------
  # The essential rule set. One protocol + one port + one peer per rule.
  # protocol: "6" tcp, "17" udp, "1" icmp. peer: { nsg = <role> } |
  # { cidr = <cidr> } | { service = "osn" }.
  # -------------------------------------------------------------------------
  baseline_rule_defs = concat(
    # ---- control plane -----------------------------------------------------
    [
      {
        key      = "api-in-workers"
        nsg      = "cp"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 6443
        port_max = 6443
        peer     = { nsg = "workers" }
        desc     = "[OKE] Kubernetes API from worker nodes (required row: worker to API endpoint). [AWS] base/eks ingress_nodes_443 pair."
      },
      {
        key      = "api-in-pods"
        nsg      = "cp"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 6443
        port_max = 6443
        peer     = { nsg = "pods" }
        desc     = "[OKE] Kubernetes API from pods (required row, VCN-native pod networking)."
      },
      {
        key      = "oke-channel-in-workers"
        nsg      = "cp"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "workers" }
        desc     = "[OKE] OKE registration/health channel from workers (required row, oke_port)."
      },
      {
        key      = "oke-channel-in-pods"
        nsg      = "cp"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "pods" }
        desc     = "[OKE] OKE channel + Workload Identity proxymux from pods (required row; resourcePrincipalSessionTokens, live-diagnosed 2026-09-10)."
      },
      {
        key       = "pmtu-in-vcn"
        nsg       = "cp"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "[OKE] Path-MTU discovery from VCN peers (required row: ICMP 3,4). Narrowed from the registry module's untyped ICMP."
      },
      {
        key       = "pmtu-in-osn"
        nsg       = "cp"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { service = "osn" }
        desc      = "[OKE] Path-MTU discovery on the Oracle Services Network path (required row: ICMP 3,4)."
      },
      {
        key      = "osn-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 443
        port_max = 443
        peer     = { service = "osn" }
        desc     = "[OKE] API endpoint to OKE control-plane services (required row: TCP/443 to OSN). Replaces TCP/all-ports to the whole OSN."
      },
      {
        key      = "cluster-443-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 443
        port_max = 443
        peer     = { nsg = "workers" }
        desc     = "[AWS] Cluster API to node groups (base/eks ingress_cluster_443, EKS sec-group-reqs doc)."
      },
      {
        key      = "kubelet-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 10250
        port_max = 10250
        peer     = { nsg = "workers" }
        desc     = "[OKE] kubelet channel for kubectl logs/exec (required npn row: TCP 10250). [AWS] base/eks ingress_cluster_kubelet."
      },
      {
        key      = "oke-channel-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "workers" }
        desc     = "[OKE] OKE health channel to workers (paired with oke-channel-in-workers; replaces TCP/all-ports to workers)."
      },
      {
        key      = "webhook-8443-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 8443
        port_max = 8443
        peer     = { nsg = "pods" }
        desc     = "[AWS] Admission webhooks served by pods (base/eks ingress_cluster_8443_webhook). Replaces TCP/all-ports to pods; custom webhook ports are add-backs."
      },
      {
        key      = "webhook-9443-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 9443
        port_max = 9443
        peer     = { nsg = "pods" }
        desc     = "[AWS] Admission webhooks served by pods (base/eks ingress_cluster_9443_webhook, controller-runtime standard)."
      },
      {
        key       = "pmtu-out-vcn"
        nsg       = "cp"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "[OKE] Path-MTU discovery to VCN peers (required row: ICMP 3,4)."
      },
    ],
    # Control-plane admin access: one rule per allowlisted CIDR (VPN/office/
    # VCN admin). [AWS] cluster_endpoint_public_access_cidrs +
    # security_group_additional_rules.vpn_access. The security-rules unit also
    # carries its own 6443 admin rows; union semantics make the overlap safe,
    # but the in-VCN admin CIDRs live only here.
    [
      for i, cidr in var.control_plane_allowed_cidrs : {
        key      = "api-in-admin-${i}"
        nsg      = "cp"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 6443
        port_max = 6443
        peer     = { cidr = cidr }
        desc     = "[AWS] Kubernetes API admin access from allowlisted CIDR ${cidr} (cluster_endpoint_public_access_cidrs pattern; replaces the registry module's per-CIDR rows)."
      }
    ],

    # ---- worker nodes ------------------------------------------------------
    [
      {
        key      = "cluster-443-in"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 443
        port_max = 443
        peer     = { nsg = "cp" }
        desc     = "[AWS] Cluster API to node groups (base/eks ingress_cluster_443)."
      },
      {
        key      = "kubelet-in"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 10250
        port_max = 10250
        peer     = { nsg = "cp" }
        desc     = "[OKE] kubelet channel from the API endpoint (required npn row: TCP 10250). [AWS] base/eks ingress_cluster_kubelet."
      },
      {
        key      = "oke-channel-in"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "cp" }
        desc     = "[OKE] OKE health channel from the control plane (registry oke_port pair; replaces the TCP/all-ports 'webhooks' ingress)."
      },
      {
        key      = "coredns-tcp-in-self"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 53
        port_max = 53
        peer     = { nsg = "workers" }
        desc     = "[AWS] CoreDNS node-to-node (base/eks ingress_self_coredns_tcp). Replaces ALL/ALL worker self."
      },
      {
        key      = "coredns-udp-in-self"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "17"
        port_min = 53
        port_max = 53
        peer     = { nsg = "workers" }
        desc     = "[AWS] CoreDNS node-to-node (base/eks ingress_self_coredns_udp)."
      },
      {
        key      = "ephemeral-in-self"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "workers" }
        desc     = "[AWS] Node-to-node service traffic on app/ephemeral ports (base/eks ingress_nodes_ephemeral). Replaces ALL/ALL worker self."
      },
      {
        key      = "ephemeral-in-pods"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "pods" }
        desc     = "[AWS] Pod-to-node flows: kubelet metrics 10250, node-exporter 9100 scrapes (ingress_nodes_ephemeral cross-tier). Replaces ALL/ALL from pods."
      },
      {
        key      = "nodeport-tcp-in-int-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "int_lb" }
        desc     = "[OKE] Service LoadBalancer NodePort traffic from the internal LB (required LB section; module node_port_min/max)."
      },
      {
        key      = "nodeport-udp-in-int-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "17"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "int_lb" }
        desc     = "[OKE] NodePort UDP from the internal LB (required LB section)."
      },
      {
        key      = "kube-proxy-health-in-int-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 10256
        port_max = 10256
        peer     = { nsg = "int_lb" }
        desc     = "[OKE] kube-proxy health checks from the internal LB (required LB section; module health_check_port=10256)."
      },
      {
        key      = "nodeport-tcp-in-pub-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "pub_lb" }
        desc     = "[OKE] NodePort traffic from the public LB (required LB section)."
      },
      {
        key      = "nodeport-udp-in-pub-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "17"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "pub_lb" }
        desc     = "[OKE] NodePort UDP from the public LB (required LB section)."
      },
      {
        key      = "kube-proxy-health-in-pub-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 10256
        port_max = 10256
        peer     = { nsg = "pub_lb" }
        desc     = "[OKE] kube-proxy health checks from the public LB (required LB section)."
      },
      {
        key       = "pmtu-in-vcn"
        nsg       = "workers"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "[OKE] Path-MTU discovery from VCN peers (required row: ICMP 3,4). Replaces untyped ICMP from 0.0.0.0/0."
      },
      {
        key       = "pmtu-in-osn"
        nsg       = "workers"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { service = "osn" }
        desc      = "[OKE] Path-MTU discovery on the OSN path (required row: ICMP 3,4)."
      },
      {
        key      = "api-out"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 6443
        port_max = 6443
        peer     = { nsg = "cp" }
        desc     = "[OKE] Kubernetes API (required row: worker to API endpoint)."
      },
      {
        key      = "oke-channel-out"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "cp" }
        desc     = "[OKE] OKE registration/health channel (required row)."
      },
      {
        key      = "coredns-tcp-out-self"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 53
        port_max = 53
        peer     = { nsg = "workers" }
        desc     = "[AWS] CoreDNS queries node-to-node (base/eks ingress_self_coredns_tcp pair)."
      },
      {
        key      = "coredns-udp-out-self"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "17"
        port_min = 53
        port_max = 53
        peer     = { nsg = "workers" }
        desc     = "[AWS] CoreDNS queries node-to-node (base/eks ingress_self_coredns_udp pair)."
      },
      {
        key      = "ephemeral-out-self"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "workers" }
        desc     = "[AWS] Node-to-node service traffic (base/eks ingress_nodes_ephemeral pair)."
      },
      {
        key      = "ephemeral-out-pods"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "pods" }
        desc     = "[AWS] Kubelet liveness/readiness probes to pod containerPorts (8080 router/superposition, 6128 encryption-service, 2525 smtp-relay) and NodePort DNAT to pod IPs (VCN-native, un-SNAT'd). Replaces ALL/ALL to pods."
      },
      {
        key      = "coredns-tcp-out-pods"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 53
        port_max = 53
        peer     = { nsg = "pods" }
        desc     = "[AWS] Node resolver to CoreDNS pods (VCN-native: a real VNIC hop, coredns pattern)."
      },
      {
        key      = "coredns-udp-out-pods"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "17"
        port_min = 53
        port_max = 53
        peer     = { nsg = "pods" }
        desc     = "[AWS] Node resolver to CoreDNS pods (coredns pattern)."
      },
      {
        key      = "osn-out"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 443
        port_max = 443
        peer     = { service = "osn" }
        desc     = "[OKE] OCIR image pulls, OKE telemetry, IAM instance-principal federation (TCP/443 to OSN; replaces TCP/all-ports - the 2026-09-10 envoy diagnosis proved identity federation is 443 on the OSN)."
      },
      {
        key       = "pmtu-out-vcn"
        nsg       = "workers"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "[OKE] Path-MTU discovery to VCN peers (required row: ICMP 3,4)."
      },
      {
        key       = "pmtu-out-osn"
        nsg       = "workers"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { service = "osn" }
        desc      = "[OKE] Path-MTU discovery on the OSN path (required row: ICMP 3,4)."
      },
    ],

    # ---- pods (VCN-native; every hop is a real VNIC hop) -------------------
    [
      {
        key      = "coredns-tcp-in-self"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 53
        port_max = 53
        peer     = { nsg = "pods" }
        desc     = "[AWS] CoreDNS pod-to-pod (base/eks ingress_self_coredns_tcp). Replaces ALL/ALL pod self."
      },
      {
        key      = "coredns-udp-in-self"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "17"
        port_min = 53
        port_max = 53
        peer     = { nsg = "pods" }
        desc     = "[AWS] CoreDNS pod-to-pod (base/eks ingress_self_coredns_udp)."
      },
      {
        key      = "ephemeral-in-self"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "pods" }
        desc     = "[AWS] Pod-to-pod service calls on app ports (router->superposition 8080, router->encryption-service 6128; base/eks ingress_nodes_ephemeral). Replaces ALL/ALL pod self."
      },
      {
        key      = "ephemeral-in-workers"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "workers" }
        desc     = "[AWS] Kubelet probes on containerPorts, NodePort DNAT, metrics scrapes (ingress_nodes_ephemeral cross-tier). Replaces ALL/ALL from workers."
      },
      {
        key      = "coredns-tcp-in-workers"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 53
        port_max = 53
        peer     = { nsg = "workers" }
        desc     = "[AWS] Node-side resolution to CoreDNS pods (coredns pattern; VCN-native hop)."
      },
      {
        key      = "coredns-udp-in-workers"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "17"
        port_min = 53
        port_max = 53
        peer     = { nsg = "workers" }
        desc     = "[AWS] Node-side resolution to CoreDNS pods (coredns pattern)."
      },
      {
        key      = "webhook-8443-in"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 8443
        port_max = 8443
        peer     = { nsg = "cp" }
        desc     = "[AWS] Admission webhooks served by pods (base/eks ingress_cluster_8443_webhook). Replaces ALL/ALL from the API endpoint; other webhook ports (e.g. istio 15017) are add-backs."
      },
      {
        key      = "webhook-9443-in"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 9443
        port_max = 9443
        peer     = { nsg = "cp" }
        desc     = "[AWS] Admission webhooks served by pods (controller-runtime standard; base/eks ingress_cluster_9443_webhook)."
      },
      {
        key      = "app-8080-in-int-lb"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 8080
        port_max = 8080
        peer     = { nsg = "int_lb" }
        desc     = "[APP] router-internal-lb Service (:80 -> targetPort 8080, deployment-configs/oci/prod/router-internal-lb). Replaces ALL/ALL from internal_lb; 6128/2525 are add-backs."
      },
      {
        key       = "pmtu-in-vcn"
        nsg       = "pods"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "[OKE] Path-MTU discovery from VCN peers (required row: ICMP 3,4). Replaces untyped ICMP from 0.0.0.0/0."
      },
      {
        key       = "pmtu-in-osn"
        nsg       = "pods"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { service = "osn" }
        desc      = "[OKE] Path-MTU discovery on the OSN path (required row: ICMP 3,4)."
      },
      {
        key      = "coredns-tcp-out-self"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 53
        port_max = 53
        peer     = { nsg = "pods" }
        desc     = "[AWS] CoreDNS queries (base/eks coredns pair)."
      },
      {
        key      = "coredns-udp-out-self"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "17"
        port_min = 53
        port_max = 53
        peer     = { nsg = "pods" }
        desc     = "[AWS] CoreDNS queries (base/eks coredns pair)."
      },
      {
        key      = "ephemeral-out-self"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "pods" }
        desc     = "[AWS] Pod-to-pod service calls on app ports (base/eks ingress_nodes_ephemeral pair)."
      },
      {
        key      = "ephemeral-out-workers"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "workers" }
        desc     = "[AWS] Node-local flows from pods: kubelet metrics 10250, node-exporter 9100 (ingress_nodes_ephemeral cross-tier). Replaces ALL/ALL to workers."
      },
      {
        key      = "api-out"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 6443
        port_max = 6443
        peer     = { nsg = "cp" }
        desc     = "[OKE] Kubernetes API (required row: pod to API endpoint)."
      },
      {
        key      = "oke-channel-out"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "cp" }
        desc     = "[OKE] OKE channel + Workload Identity proxymux (required row; the IRSA-equivalent every identity-bearing workload uses)."
      },
      {
        key       = "pmtu-out-vcn"
        nsg       = "pods"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "[OKE] Path-MTU discovery to VCN peers (required row: ICMP 3,4)."
      },
      {
        key       = "pmtu-out-osn"
        nsg       = "pods"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { service = "osn" }
        desc      = "[OKE] Path-MTU discovery on the OSN path (required row: ICMP 3,4)."
      },
    ],

    # ---- internal LB (service LoadBalancer plumbing) -----------------------
    [
      {
        key      = "nodeport-tcp-out"
        nsg      = "int_lb"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "workers" }
        desc     = "[OKE] Service LoadBalancer to worker NodePorts (required LB section). Replaces TCP/all-ports to workers."
      },
      {
        key      = "nodeport-udp-out"
        nsg      = "int_lb"
        dir      = "EGRESS"
        proto    = "17"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "workers" }
        desc     = "[OKE] Service LoadBalancer to worker NodePorts, UDP (required LB section)."
      },
      {
        key      = "kube-proxy-health-out"
        nsg      = "int_lb"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 10256
        port_max = 10256
        peer     = { nsg = "workers" }
        desc     = "[OKE] kube-proxy health checks to workers (required LB section; health_check_port=10256)."
      },
      {
        key      = "app-8080-out-pods"
        nsg      = "int_lb"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 8080
        port_max = 8080
        peer     = { nsg = "pods" }
        desc     = "[APP] router-internal-lb backends on pod IPs (VCN-native; :80 -> targetPort 8080). Replaces ALL/ALL to pods; other app ports are add-backs."
      },
      {
        key       = "pmtu-out-vcn"
        nsg       = "int_lb"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "[OKE] Path-MTU discovery to VCN peers (required row: ICMP 3,4). Replaces untyped ICMP."
      },
    ],
  )

  # Normalise: every peer object gets all three selector keys (null when
  # unused) so the rule resource can read them unconditionally, and the "vcn"
  # peer selector resolves to the real CIDR. Uniform field set also keeps the
  # optional icmp_type/icmp_code/port_min/port_max attributes readable.
  baseline_rules = {
    for r in local.baseline_rule_defs : "${r.nsg}/${r.key}" => merge(r, {
      peer = merge({ nsg = null, cidr = null, service = null }, {
        for k, v in r.peer : k => (k == "cidr" && v == "vcn") ? local.vcn_cidr : v
      })
      icmp_type = try(r.icmp_type, null)
      icmp_code = try(r.icmp_code, null)
      port_min  = try(r.port_min, null)
      port_max  = try(r.port_max, null)
    })
  }
}

# -----------------------------------------------------------------------------
# Adoption: preserve the OCIDs the registry module's NSGs already have.
# from-addresses are the live state addresses inside the vendored module
# (module "oke" -> module "network"); the `to` instances are always declared
# (static for_each), so these blocks are valid in every environment. In a
# greenfield state the from-address does not exist and the move is ignored.
# -----------------------------------------------------------------------------
moved {
  from = module.oke.module.network.oci_core_network_security_group.cp[0]
  to   = oci_core_network_security_group.baseline["cp"]
}

moved {
  from = module.oke.module.network.oci_core_network_security_group.workers[0]
  to   = oci_core_network_security_group.baseline["workers"]
}

moved {
  from = module.oke.module.network.oci_core_network_security_group.pods[0]
  to   = oci_core_network_security_group.baseline["pods"]
}

moved {
  from = module.oke.module.network.oci_core_network_security_group.int_lb[0]
  to   = oci_core_network_security_group.baseline["int_lb"]
}

resource "oci_core_network_security_group" "baseline" {
  for_each = local.baseline_nsg_roles

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.cluster_name}-${each.key}-nsg"
  freeform_tags  = local.common_freeform_tags
}

resource "oci_core_network_security_group_security_rule" "baseline" {
  for_each = local.baseline_rules

  network_security_group_id = oci_core_network_security_group.baseline[each.value.nsg].id
  direction                 = each.value.dir
  protocol                  = each.value.proto
  description               = each.value.desc
  stateless                 = false

  source_type = each.value.dir == "INGRESS" ? (
    each.value.peer.nsg != null ? "NETWORK_SECURITY_GROUP" :
    each.value.peer.service != null ? "SERVICE_CIDR_BLOCK" : "CIDR_BLOCK"
  ) : null
  source = each.value.dir == "INGRESS" ? (
    each.value.peer.nsg != null ? local.peer_nsg_ids[each.value.peer.nsg] :
    each.value.peer.service != null ? local.osn_cidr : each.value.peer.cidr
  ) : null

  destination_type = each.value.dir == "EGRESS" ? (
    each.value.peer.nsg != null ? "NETWORK_SECURITY_GROUP" :
    each.value.peer.service != null ? "SERVICE_CIDR_BLOCK" : "CIDR_BLOCK"
  ) : null
  destination = each.value.dir == "EGRESS" ? (
    each.value.peer.nsg != null ? local.peer_nsg_ids[each.value.peer.nsg] :
    each.value.peer.service != null ? local.osn_cidr : each.value.peer.cidr
  ) : null

  dynamic "tcp_options" {
    for_each = each.value.proto == "6" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }

  dynamic "udp_options" {
    for_each = each.value.proto == "17" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }

  dynamic "icmp_options" {
    for_each = each.value.proto == "1" ? [1] : []
    content {
      type = each.value.icmp_type
      code = each.value.icmp_code
    }
  }
}
