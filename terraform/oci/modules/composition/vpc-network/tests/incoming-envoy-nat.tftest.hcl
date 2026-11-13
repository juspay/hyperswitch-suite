mock_provider "oci" {
  mock_data "oci_core_services" {
    defaults = {
      services = [{
        id         = "ocid1.service.oc1.mock"
        name       = "All BOM Services In Oracle Services Network"
        cidr_block = "all-bom-services-in-oracle-services-network"
      }]
    }
  }
}

variables {
  compartment_id               = "ocid1.compartment.oc1.mock"
  region                       = "ap-mumbai-1"
  environment                  = "test"
  vcn_display_name             = "test-vcn"
  vcn_cidr_blocks              = ["10.64.0.0/16"]
  management_subnet_cidr       = "10.64.1.0/24"
  database_subnet_cidr         = "10.64.2.0/24"
  oke_api_endpoint_subnet_cidr = "10.64.10.0/24"
  incoming_envoy_subnet_cidr   = "10.64.7.0/24"
  outgoing_proxy_subnet_cidr   = "10.64.8.0/24"
  utils_subnet_cidr            = "10.64.9.0/24"
}

run "default_nat_enabled" {
  command = apply
  assert {
    condition     = oci_core_subnet.this["incoming-envoy"].route_table_id == oci_core_route_table.this["common-local-nat-osn"].id
    error_message = "The default must retain incoming-envoy NAT routing."
  }
}

run "explicit_nat_enabled" {
  command = plan
  variables {
    incoming_envoy_nat_enabled = true
  }
  assert {
    condition     = oci_core_subnet.this["incoming-envoy"].route_table_id == oci_core_route_table.this["common-local-nat-osn"].id
    error_message = "True must retain incoming-envoy NAT routing."
  }
}

run "nat_disabled" {
  command = plan
  variables {
    incoming_envoy_nat_enabled = false
  }
  assert {
    condition     = oci_core_subnet.this["incoming-envoy"].route_table_id == oci_core_route_table.this["common-local-osn"].id
    error_message = "False must select the OSN-only route table."
  }
  assert {
    condition     = oci_core_subnet.this["utils"].route_table_id == oci_core_route_table.this["common-local-nat-osn"].id && oci_core_subnet.this["outgoing-proxy"].route_table_id == oci_core_route_table.this["proxy-peering-nat"].id
    error_message = "Utils and Squid associations must not change."
  }
  assert {
    condition     = alltrue([for route in oci_core_route_table.this["common-local-osn"].route_rules : route.destination != "0.0.0.0/0"]) && anytrue([for route in oci_core_route_table.this["common-local-osn"].route_rules : route.destination_type == "SERVICE_CIDR_BLOCK"])
    error_message = "The selected table must retain OSN access without a default route."
  }
}
