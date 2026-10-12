terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    # -------------------------------------------------------------------------
    # DECLARED, BUT DELIBERATELY NOT CONFIGURED IN THIS MODULE.
    #
    # There is no `provider "kubernetes"` or `provider "helm"` block anywhere in
    # this module, and that is a correction of a known defect rather than an
    # omission. identity-model.md section 2.2 records what happened on GCP:
    # `argocd` and `external-secrets-operator` on `main` each declare their own
    # inline `provider "kubernetes"` block requiring `cluster_endpoint` and
    # `cluster_ca_certificate`, and their catalog units pass neither - "those
    # units cannot plan as committed". The GCP `istio` module has the same inline
    # blocks.
    #
    # Instead the default (unaliased) `helm` and `kubernetes` providers are
    # inherited from the calling root, which on this platform means the live
    # root's hand-written `root.hcl` `generate "provider"` block. That keeps the
    # cluster-auth mechanism in ONE place per environment rather than duplicated
    # into every app module, and it means changing how the token is obtained is a
    # root.hcl edit rather than a module release.
    #
    # PREREQUISITE, and it is a real one: the OCI live root's `root.hcl` must
    # emit `provider "helm"` and `provider "kubernetes"` blocks pointing at the
    # OKE cluster. Check sheet section 9 Q1 asks whether that should use
    # `data.oci_containerengine_cluster_kube_config` or an `exec` plugin calling
    # `oci ce cluster generate-token`; whichever `oke-kubernetes-resources`
    # settles on, this module inherits it for free.
    # -------------------------------------------------------------------------
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
  }
}
