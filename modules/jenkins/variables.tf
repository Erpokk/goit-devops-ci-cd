# variable "kubeconfig" {
#   description = "Path to kubeconfig file"
#   type        = string
# }

variable "cluster_name" {
  description = "Name of Kubernetes cluster"
  type        = string
}


variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}
