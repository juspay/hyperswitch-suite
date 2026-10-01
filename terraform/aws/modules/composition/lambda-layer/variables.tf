# ============================================================================
# Lambda Layer Module - Variables
# ============================================================================

variable "layer_name" {
  description = "Name of the Lambda layer"
  type        = string
}

variable "description" {
  description = "Description of the Lambda layer"
  type        = string
  default     = ""
}

variable "zip_path" {
  description = "Path to the layer zip file"
  type        = string
}

variable "source_hash" {
  description = "Base64-encoded SHA256 hash of the zip file"
  type        = string
  default     = ""
}

variable "compatible_runtimes" {
  description = "List of compatible Lambda runtimes"
  type        = list(string)
  default     = ["python3.11"]
}

variable "license_info" {
  description = "License information for the layer"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to the layer"
  type        = map(string)
  default     = {}
}
