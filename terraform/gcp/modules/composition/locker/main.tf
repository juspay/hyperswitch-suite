# Card vault locker - data tier and identity only. The locker application
# itself runs as a GKE workload deployed through GitOps, so this module owns
# only what Kubernetes cannot create for itself:
#
#   1. a dedicated, CMEK-encrypted AlloyDB cluster, kept separate from the
#      platform's shared cluster so card data stays in its own PCI-DSS scope;
#   2. a Google service account bound by Workload Identity to the locker's
#      Kubernetes service account, holding the IAM roles that let the pod
#      connect to that cluster and read its password;
#   3. the CMEK key both of the above are encrypted with.
#
# The pod reaches the database via this module's outputs (database_host,
# master_username, master_password_secret_name).
#
# Known gap, inherited from ../alloydb: the google provider has no resource for
# an individual AlloyDB database. This module creates the cluster and its
# primary instance; creating the `locker` database inside it is a SQL-level
# step (`CREATE DATABASE` over psql).

# The workload-identity module below creates a real kubernetes_service_account_v1;
# without a configured provider it falls back to the zero-config default and
# apply fails with `dial tcp [::1]:80: connect: connection refused`.
provider "kubernetes" {
  host                   = "https://${var.cluster_endpoint}"
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

# Dedicated AlloyDB cluster for the vault. project_name is suffixed with
# "-locker" so ../alloydb derives its cluster/keyring/secret names in the
# locker's own namespace rather than colliding with the shared cluster.
module "database" {

  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/alloydb?ref=gcp-alloydb-v0.1.0"

  count = var.create_database ? 1 : 0

  project_id   = var.project_id
  environment  = var.environment
  project_name = "${var.project_name}-locker"
  region       = var.region

  network_id         = var.database_config.network_id
  allocated_ip_range = var.database_config.allocated_ip_range

  cluster_id          = var.database_config.cluster_id
  database_version    = coalesce(var.database_config.database_version, "POSTGRES_15")
  deletion_protection = coalesce(var.database_config.deletion_protection, true)

  master_username = coalesce(var.database_config.master_username, "locker_admin")
  master_password = var.database_config.master_password

  primary_instance = {
    availability_type = coalesce(var.database_config.availability_type, "REGIONAL")
    cpu_count         = coalesce(var.database_config.cpu_count, 2)
    machine_type      = var.database_config.machine_type
    database_flags    = var.database_config.database_flags
  }

  encryption_key_name = local.kms_key_name

  # Defaults to creating the secret, unlike ../alloydb: the pod has no other
  # way to receive a module-generated password.
  secret_manager = local.secret_manager_config

  labels = local.common_labels
}

# Workload Identity binding for the locker pod
module "workload_identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "44.3.0"

  project_id = var.project_id
  name       = local.gcp_sa_name

  cluster_name = var.cluster_name
  location     = var.cluster_location
  namespace    = var.k8s_namespace
  k8s_sa_name  = var.k8s_service_account_name

  use_existing_k8s_sa = var.use_existing_k8s_sa
  annotate_k8s_sa     = var.annotate_k8s_sa

  roles = local.project_roles
}

# Read access to the generated database password, scoped to that one secret -
# deliberately not a project-level secretAccessor grant, which would hand the
# vault's identity every other application's secrets too.
resource "google_secret_manager_secret_iam_member" "master_password" {
  count = local.grant_master_password_access ? 1 : 0

  project   = var.project_id
  secret_id = module.database[0].secret_manager_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}

# Optional: let the vault use the same CMEK key for application-level card
# encryption. Off by default - the key exists to encrypt the AlloyDB cluster.
resource "google_kms_crypto_key_iam_member" "locker" {
  count = var.grant_kms_access && local.kms_key_name != null ? 1 : 0

  crypto_key_id = local.kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}
