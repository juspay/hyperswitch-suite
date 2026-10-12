# oke - identity. This file intentionally declares NO resources; the identity
# decisions live in the phase-0 compartment/IAM bootstrap, not here.
#
# VERIFIED BLOCKER: the tenancy OKE service policy is missing. The data source
# `oci_containerengine_node_pool_option` reads "successfully" but returns an
# EMPTY image set, so node pools fail far from the cause as
#   setintersection(...): argument must not be null
# during the registry module's image lookup. Workaround: set
# `image_type = "custom"` with an explicit `image_id` on every node pool until
# `Allow service OKE to manage all-resources in tenancy` is added to the
# bootstrap.
