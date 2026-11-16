mock_provider "oci" {
  override_during = plan
}

mock_provider "helm" {}
mock_provider "kubernetes" {}

variables {
  compartment_id     = "ocid1.compartment.oc1..mock"
  environment        = "prd"
  region             = "us-phoenix-1"
  cluster_id         = "ocid1.cluster.oc1.phx.mock"
  create_gateway_nsg = false
}

run "public_default" {
  command = plan

  assert {
    condition     = length(oci_core_public_ip.gateway) == 1 && length(oci_core_private_ip.gateway) == 0
    error_message = "Default mode must create only the public reservation."
  }

  assert {
    condition     = output.gateway_internal_ip == null && contains(keys(output.gateway_service_annotations), "oci.oraclecloud.com/reserved-ips") && !contains(keys(output.gateway_service_annotations), "oci.oraclecloud.com/reserved-private-ips")
    error_message = "Public annotation/output contract changed."
  }
}

run "public_without_reservation" {
  command = plan

  variables {
    create_gateway_reserved_ip = false
  }

  assert {
    condition     = length(oci_core_public_ip.gateway) == 0 && length(oci_core_private_ip.gateway) == 0 && !contains(keys(output.gateway_service_annotations), "oci.oraclecloud.com/reserved-ips")
    error_message = "Public reservation switch must still disable reservation."
  }
}

run "internal_gateway_helm_values" {
  command = plan

  variables {
    gateway_internal_ip  = "10.91.9.130"
    gateway_lb_subnet_id = "ocid1.subnet.oc1.phx.mocklb"
    create_helm_releases = true
  }

  assert {
    condition     = length(oci_core_public_ip.gateway) == 0 && length(oci_core_private_ip.gateway) == 1 && oci_core_private_ip.gateway[0].lifetime == "RESERVED" && oci_core_private_ip.gateway[0].vnic_id == null && oci_core_private_ip.gateway[0].subnet_id == var.gateway_lb_subnet_id
    error_message = "Internal mode must reserve an unassigned private IP on the LB subnet only."
  }

  assert {
    condition     = output.gateway_internal_ip == "10.91.9.130" && output.gateway_reserved_ip == null && !contains(keys(output.gateway_service_annotations), "oci.oraclecloud.com/reserved-ips")
    error_message = "Internal output or public/private exclusivity is incorrect."
  }

  assert {
    condition = alltrue([
      yamldecode(helm_release.istio_gateway[0].values[0]).service.type == "LoadBalancer",
      yamldecode(helm_release.istio_gateway[0].values[0]).service.annotations["service.beta.kubernetes.io/oci-load-balancer-internal"] == "true",
      yamldecode(helm_release.istio_gateway[0].values[0]).service.annotations["oci.oraclecloud.com/reserved-private-ips"] == "10.91.9.130",
      yamldecode(helm_release.istio_gateway[0].values[0]).service.annotations["oci.oraclecloud.com/load-balancer-type"] == "lb",
      yamldecode(helm_release.istio_gateway[0].values[0]).service.annotations["service.beta.kubernetes.io/oci-load-balancer-security-list-management-mode"] == "None",
    ])
    error_message = "Rendered gateway Helm Service values do not match the private-IP contract."
  }
}

run "internal_reservation_independent_of_public_switch" {
  command = plan

  variables {
    gateway_internal_ip        = "10.91.9.130"
    gateway_lb_subnet_id       = "ocid1.subnet.oc1.phx.mocklb"
    create_gateway_reserved_ip = false
    external_traffic_policy    = "Local"
    gateway_service_annotations = {
      "example.com/custom" = "retained"
    }
  }

  assert {
    condition     = length(oci_core_private_ip.gateway) == 1 && output.gateway_service_annotations["example.com/custom"] == "retained" && yamldecode(local.gateway_service_values).service.externalTrafficPolicy == "Local"
    error_message = "Internal reservation, caller annotations, or traffic-policy passthrough failed."
  }
}

run "missing_internal_subnet" {
  command = plan

  variables {
    gateway_internal_ip = "10.91.9.130"
  }

  expect_failures = [oci_core_private_ip.gateway]
}

run "internal_nlb_rejected" {
  command = plan

  variables {
    gateway_internal_ip  = "10.91.9.130"
    gateway_lb_subnet_id = "ocid1.subnet.oc1.phx.mocklb"
    load_balancer_type   = "nlb"
  }

  expect_failures = [oci_core_private_ip.gateway]
}

run "public_annotation_on_internal_rejected" {
  command = plan

  variables {
    gateway_internal_ip  = "10.91.9.130"
    gateway_lb_subnet_id = "ocid1.subnet.oc1.phx.mocklb"
    gateway_service_annotations = {
      "oci.oraclecloud.com/reserved-ips" = "ocid1.publicip.oc1.phx.mock"
    }
  }

  expect_failures = [oci_core_private_ip.gateway]
}

run "security_list_override_rejected" {
  command = plan

  variables {
    gateway_service_annotations = {
      "service.beta.kubernetes.io/oci-load-balancer-security-list-management-mode" = "All"
    }
  }

  expect_failures = [var.gateway_service_annotations]
}

run "invalid_internal_ip_rejected" {
  command = plan

  variables {
    gateway_internal_ip  = "not-an-ip"
    gateway_lb_subnet_id = "ocid1.subnet.oc1.phx.mocklb"
  }

  expect_failures = [var.gateway_internal_ip]
}
