# =============================================================================
# nsg-baseline - ownership of the four core OKE NSGs and their essential rules
# =============================================================================
# WHY THIS FILE EXISTS
#
# The vendored registry module (oracle-terraform-modules/oke) writes a
# permissive baseline into every NSG it creates: protocol "all" between pods,
# workers and the control plane, untyped ICMP to/from 0.0.0.0/0, and
# TCP/all-ports to the entire Oracle Services Network. This file replaces that
# with the essential set only - one protocol, one port (range), one named peer
# per rule, and every rule tied to a concrete function stated in its
# description: Oracle's own required rows for managed OKE with VCN-native pods
# (docs.oracle.com/.../contengnetworkconfig.htm, "Security Rules for the
# Kubernetes API Endpoint / Worker Nodes / Pod Subnets"), Kubernetes
# control-plane plumbing actually in use on this cluster (kubelet API, cluster
# DNS, admission webhooks served by deployed components, LoadBalancer/NodePort
# plumbing), and ports our own workloads use (deployment-configs/oci).
#
# WHAT THIS FILE DOES
#
# Takes over the four core roles (cp, workers, pods, int_lb): the NSGs are
# ours and the rule set is the essential set above. The registry module still
# wires the NSGs to node pools / the cluster endpoint / service-LB backends,
# because module.network.*_nsg_id returns the PROVIDED id when a role is
# passed with create = "never" - and writes ZERO rules for it. That seam
# (var.nsg_ids) is the contract; this file is the caller-side realisation of
# it, internalised so every consumer of this module gets the restricted set
# without extra wiring.
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
# tcp/1025-65535, a non-DNS UDP port, or a webhook port outside 9443/10250/
# 15017 gets one described rule added here (or in security-rules for
# cross-module flows).
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

  # Primary VCN CIDR. PMTU scoping: the registry module's untyped ICMP to
  # 0.0.0.0/0 is broader than even Oracle's own ICMP 3,4 row; scope to the VCN
  # instead.
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
        desc     = "Kubernetes API (6443) from worker nodes - kubelet registration and status."
      },
      {
        key      = "api-in-pods"
        nsg      = "cp"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 6443
        port_max = 6443
        peer     = { nsg = "pods" }
        desc     = "Kubernetes API (6443) from pods - in-cluster clients (service accounts, controllers)."
      },
      {
        key      = "oke-channel-in-workers"
        nsg      = "cp"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "workers" }
        desc     = "OKE control-plane channel (12250) from worker nodes - node registration and health."
      },
      {
        key      = "oke-channel-in-pods"
        nsg      = "cp"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "pods" }
        desc     = "OKE control-plane channel (12250) from pods - workload-identity token exchange (proxymux)."
      },
      {
        key       = "pmtu-in-vcn"
        nsg       = "cp"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "Path-MTU discovery (ICMP 3/4) from VCN peers."
      },
      {
        key       = "pmtu-in-osn"
        nsg       = "cp"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { service = "osn" }
        desc      = "Path-MTU discovery (ICMP 3/4) from the Oracle Services Network."
      },
      {
        key      = "osn-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 443
        port_max = 443
        peer     = { service = "osn" }
        desc     = "OKE control-plane services (443 to the Oracle Services Network)."
      },
      {
        key      = "kubelet-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 10250
        port_max = 10250
        peer     = { nsg = "workers" }
        desc     = "kubelet API (10250) on worker nodes - kubectl exec/logs, node status."
      },
      {
        key      = "oke-channel-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "workers" }
        desc     = "OKE control-plane channel (12250) to worker nodes - health and registration."
      },
      {
        key      = "webhook-9443-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 9443
        port_max = 9443
        peer     = { nsg = "pods" }
        desc     = "Admission webhook to victoria-metrics-operator pods (9443)."
      },
      {
        key      = "webhook-10250-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 10250
        port_max = 10250
        peer     = { nsg = "pods" }
        desc     = "Admission webhook to external-secrets-operator pods (its webhook listener is on 10250)."
      },
      {
        key      = "webhook-15017-out"
        nsg      = "cp"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 15017
        port_max = 15017
        peer     = { nsg = "pods" }
        desc     = "Admission webhook to istiod (15017) - istio sidecar injection and validation."
      },
      {
        key       = "pmtu-out-vcn"
        nsg       = "cp"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "Path-MTU discovery (ICMP 3/4) to VCN peers."
      },
    ],
    # Control-plane admin access: one rule per allowlisted CIDR (VPN/office/
    # ArgoCD egress). The security-rules unit also carries its own 6443 admin
    # rows; union semantics make the overlap safe, but the in-VCN admin CIDRs
    # live only here.
    [
      for i, cidr in var.control_plane_allowed_cidrs : {
        key      = "api-in-admin-${i}"
        nsg      = "cp"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 6443
        port_max = 6443
        peer     = { cidr = cidr }
        desc     = "Kubernetes API (6443) admin access from approved source ${cidr}."
      }
    ],

    # ---- worker nodes ------------------------------------------------------
    [
      {
        key      = "kubelet-in"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 10250
        port_max = 10250
        peer     = { nsg = "cp" }
        desc     = "kubelet API (10250) from the OKE control plane - kubectl exec/logs, node status."
      },
      {
        key      = "oke-channel-in"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "cp" }
        desc     = "OKE control-plane channel (12250) - node registration and health."
      },
      {
        key      = "ephemeral-in-pods"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "pods" }
        desc     = "From pods: kubelet metrics and node-exporter scrapes (10250/9100)."
      },
      {
        key      = "nodeport-tcp-in-int-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "int_lb" }
        desc     = "NodePort services (30000-32767, TCP) from the internal load balancers (router, istio gateway)."
      },
      {
        key      = "nodeport-udp-in-int-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "17"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "int_lb" }
        desc     = "NodePort services (30000-32767, UDP) from the internal load balancers."
      },
      {
        key      = "kube-proxy-health-in-int-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 10256
        port_max = 10256
        peer     = { nsg = "int_lb" }
        desc     = "kube-proxy health check (10256) from the internal load balancers."
      },
      {
        key      = "nodeport-tcp-in-pub-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "pub_lb" }
        desc     = "NodePort services (30000-32767, TCP) from the public load balancer."
      },
      {
        key      = "nodeport-udp-in-pub-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "17"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "pub_lb" }
        desc     = "NodePort services (30000-32767, UDP) from the public load balancer."
      },
      {
        key      = "kube-proxy-health-in-pub-lb"
        nsg      = "workers"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 10256
        port_max = 10256
        peer     = { nsg = "pub_lb" }
        desc     = "kube-proxy health check (10256) from the public load balancer."
      },
      {
        key       = "pmtu-in-vcn"
        nsg       = "workers"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "Path-MTU discovery (ICMP 3/4) from VCN peers."
      },
      {
        key       = "pmtu-in-osn"
        nsg       = "workers"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { service = "osn" }
        desc      = "Path-MTU discovery (ICMP 3/4) from the Oracle Services Network."
      },
      {
        key      = "api-out"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 6443
        port_max = 6443
        peer     = { nsg = "cp" }
        desc     = "Kubernetes API (6443) - kubelet registration, status, controllers."
      },
      {
        key      = "oke-channel-out"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "cp" }
        desc     = "OKE control-plane channel (12250) - node registration and health."
      },
      {
        key      = "ephemeral-out-pods"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "pods" }
        desc     = "To pods: kubelet health probes on container ports (router 8080, encryption-service 6128, smtp-relay 2525) and NodePort DNAT to pod IPs."
      },
      {
        key      = "coredns-tcp-out-pods"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 53
        port_max = 53
        peer     = { nsg = "pods" }
        desc     = "Cluster DNS (53, TCP) to CoreDNS pods - node-side resolution."
      },
      {
        key      = "coredns-udp-out-pods"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "17"
        port_min = 53
        port_max = 53
        peer     = { nsg = "pods" }
        desc     = "Cluster DNS (53, UDP) to CoreDNS pods."
      },
      {
        key      = "osn-out"
        nsg      = "workers"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 443
        port_max = 443
        peer     = { service = "osn" }
        desc     = "OCIR image pulls and OCI APIs (443 to the Oracle Services Network)."
      },
      {
        key       = "pmtu-out-vcn"
        nsg       = "workers"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "Path-MTU discovery (ICMP 3/4) to VCN peers."
      },
      {
        key       = "pmtu-out-osn"
        nsg       = "workers"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { service = "osn" }
        desc      = "Path-MTU discovery (ICMP 3/4) to the Oracle Services Network."
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
        desc     = "Cluster DNS (53, TCP) from pods - CoreDNS queries."
      },
      {
        key      = "coredns-udp-in-self"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "17"
        port_min = 53
        port_max = 53
        peer     = { nsg = "pods" }
        desc     = "Cluster DNS (53, UDP) from pods."
      },
      {
        key      = "ephemeral-in-self"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "pods" }
        desc     = "Pod-to-pod service calls on application ports (router, superposition, encryption-service)."
      },
      {
        key      = "ephemeral-in-workers"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "workers" }
        desc     = "From worker nodes: kubelet health probes on container ports and NodePort DNAT to pod IPs."
      },
      {
        key      = "coredns-tcp-in-workers"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 53
        port_max = 53
        peer     = { nsg = "workers" }
        desc     = "Cluster DNS (53, TCP) from worker nodes - node-side resolution."
      },
      {
        key      = "coredns-udp-in-workers"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "17"
        port_min = 53
        port_max = 53
        peer     = { nsg = "workers" }
        desc     = "Cluster DNS (53, UDP) from worker nodes."
      },
      {
        key      = "webhook-9443-in"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 9443
        port_max = 9443
        peer     = { nsg = "cp" }
        desc     = "Admission webhook (9443) from the Kubernetes API server - victoria-metrics-operator."
      },
      {
        key      = "webhook-10250-in"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 10250
        port_max = 10250
        peer     = { nsg = "cp" }
        desc     = "Admission webhook (10250) from the Kubernetes API server - external-secrets-operator."
      },
      {
        key      = "webhook-15017-in"
        nsg      = "pods"
        dir      = "INGRESS"
        proto    = "6"
        port_min = 15017
        port_max = 15017
        peer     = { nsg = "cp" }
        desc     = "Admission webhook (15017) from the Kubernetes API server - istiod sidecar injection."
      },
      {
        key       = "pmtu-in-vcn"
        nsg       = "pods"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "Path-MTU discovery (ICMP 3/4) from VCN peers."
      },
      {
        key       = "pmtu-in-osn"
        nsg       = "pods"
        dir       = "INGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { service = "osn" }
        desc      = "Path-MTU discovery (ICMP 3/4) from the Oracle Services Network."
      },
      {
        key      = "coredns-tcp-out-self"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 53
        port_max = 53
        peer     = { nsg = "pods" }
        desc     = "Cluster DNS (53, TCP) to CoreDNS pods."
      },
      {
        key      = "coredns-udp-out-self"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "17"
        port_min = 53
        port_max = 53
        peer     = { nsg = "pods" }
        desc     = "Cluster DNS (53, UDP) to CoreDNS pods."
      },
      {
        key      = "ephemeral-out-self"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "pods" }
        desc     = "Pod-to-pod service calls on application ports."
      },
      {
        key      = "ephemeral-out-workers"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 1025
        port_max = 65535
        peer     = { nsg = "workers" }
        desc     = "To worker nodes: kubelet metrics and node-exporter scrapes."
      },
      {
        key      = "api-out"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 6443
        port_max = 6443
        peer     = { nsg = "cp" }
        desc     = "Kubernetes API (6443) - in-cluster clients."
      },
      {
        key      = "oke-channel-out"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 12250
        port_max = 12250
        peer     = { nsg = "cp" }
        desc     = "OKE control-plane channel (12250) - workload-identity token exchange (proxymux)."
      },
      {
        key      = "osn-out"
        nsg      = "pods"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 443
        port_max = 443
        peer     = { service = "osn" }
        desc     = "Oracle Services Network (443): KMS vault reads (external-secrets-operator), Object Storage, Email Delivery."
      },
      {
        key       = "pmtu-out-vcn"
        nsg       = "pods"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "Path-MTU discovery (ICMP 3/4) to VCN peers."
      },
      {
        key       = "pmtu-out-osn"
        nsg       = "pods"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { service = "osn" }
        desc      = "Path-MTU discovery (ICMP 3/4) to the Oracle Services Network."
      },
    ],

    # ---- internal LB (service LoadBalancer plumbing; ingress to the LB
    # comes from the security-rules unit's cross-module edge rows) -----------
    [
      {
        key      = "nodeport-tcp-out"
        nsg      = "int_lb"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "workers" }
        desc     = "To NodePort services (30000-32767, TCP) on worker nodes."
      },
      {
        key      = "nodeport-udp-out"
        nsg      = "int_lb"
        dir      = "EGRESS"
        proto    = "17"
        port_min = 30000
        port_max = 32767
        peer     = { nsg = "workers" }
        desc     = "To NodePort services (30000-32767, UDP) on worker nodes."
      },
      {
        key      = "kube-proxy-health-out"
        nsg      = "int_lb"
        dir      = "EGRESS"
        proto    = "6"
        port_min = 10256
        port_max = 10256
        peer     = { nsg = "workers" }
        desc     = "kube-proxy health check (10256) on worker nodes."
      },
      {
        key       = "pmtu-out-vcn"
        nsg       = "int_lb"
        dir       = "EGRESS"
        proto     = "1"
        icmp_type = 3
        icmp_code = 4
        peer      = { cidr = "vcn" }
        desc      = "Path-MTU discovery (ICMP 3/4) to VCN peers."
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
