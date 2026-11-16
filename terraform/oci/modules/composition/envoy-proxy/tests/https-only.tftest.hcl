mock_provider "oci" {
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [{ name = "test:AD-1", id = "ocid1.availabilitydomain.oc1.phx.ad1" }]
    }
  }

  mock_data "oci_objectstorage_namespace" {
    defaults = { namespace = "mock_namespace" }
  }
}

mock_provider "oci" {
  alias = "home"

  mock_data "oci_objectstorage_namespace" {
    defaults = { namespace = "mock_namespace" }
  }
}

mock_provider "tls" {}

variables {
  environment          = "sandbox"
  project_name         = "hyperswitch"
  region               = "us-phoenix-1"
  compartment_id       = "ocid1.compartment.oc1..mock"
  tenancy_ocid         = "ocid1.tenancy.oc1..mock"
  image_id             = "ocid1.image.oc1.phx.mock"
  vcn_id               = "ocid1.vcn.oc1.phx.mock"
  subnet_id            = "ocid1.subnet.oc1.phx.mock"
  create_lb            = true
  create_nsg           = false
  create_config_bucket = false
  create_logs_bucket   = false
  generate_ssh_key     = false
  enable_autoscaling   = false
  lb_subnet_id         = "ocid1.subnet.oc1.phx.mock-lb"
  lb_is_private        = false
  ssl_certificate_ids  = ["ocid1.certificate.oc1.phx.mock"]
}

run "https_only_mode_has_no_plaintext_listener_or_redirect" {
  command = plan

  variables {
    enable_http_listener = false
  }

  assert {
    condition     = length(oci_load_balancer_listener.http) == 0
    error_message = "HTTPS-only mode must not create an HTTP forwarding listener."
  }

  assert {
    condition     = length(oci_load_balancer_rule_set.https_redirect) == 0
    error_message = "HTTPS-only mode must still provide no listener on the HTTP port, including a redirect."
  }

  assert {
    condition     = length(oci_load_balancer_listener.https) == 1 && oci_load_balancer_listener.https[0].port == 443
    error_message = "HTTPS-only mode must retain the intended TLS listener."
  }

  assert {
    condition     = oci_load_balancer_listener.https[0].ssl_configuration[0].certificate_ids == var.ssl_certificate_ids
    error_message = "HTTPS-only mode must attach the caller-supplied certificate unchanged."
  }
}

run "legacy_mode_retains_http_to_https_redirect" {
  command = plan

  assert {
    condition     = length(oci_load_balancer_listener.http) == 1 && length(oci_load_balancer_listener.https) == 1
    error_message = "Existing callers must retain the original HTTP and HTTPS listeners when HTTPS-only mode is not requested."
  }

  assert {
    condition     = length(oci_load_balancer_rule_set.https_redirect) == 1
    error_message = "The legacy HTTP listener must keep its HTTPS redirect."
  }
}
