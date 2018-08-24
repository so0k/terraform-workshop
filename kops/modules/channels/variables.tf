variable "aws_region" {
  default = "ap-southeast-1"
}

variable "bucket_name" {
  type = "string"
}

variable "bucket_key_prefix" {
  type = "string"
}

variable "bootstrap_namespaces" {
  description = "The namespaces provisioned by bootstrap" # tiller per namespace / pull secrets / ...
  type        = "list"
  default     = ["services"]
}

variable "tiller_version" {
  description = "tiller version"
  default     = "v2.10.0"
}

variable "tiller_history_max" {
  description = "max count for previous release history"
  default     = "5"
}

variable "skipper_version" {
  description = "skipper version"
  default     = "v0.9.202"
}

variable "kube_ingress_aws_controller_version" {
  description = "kube-ingress-aws-controller version"
  default     = "v0.7.3"
}

variable "kube_state_metrics_version" {
  description = "kube-state-metrics version"
  default     = "v1.3.1"
}
