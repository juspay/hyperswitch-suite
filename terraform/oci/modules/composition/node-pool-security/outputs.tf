output "profiles" {
  description = "Profile name to worker and pod NSG OCIDs, for node-pool attachment and separately owned security rules."
  value = {
    for profile in var.profiles : profile => {
      worker_nsg_id = oci_core_network_security_group.workers[profile].id
      pod_nsg_id    = oci_core_network_security_group.pods[profile].id
    }
  }
}
