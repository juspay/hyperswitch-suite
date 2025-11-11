variable "name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to attach"
  type        = string
  default     = null
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "tenancy" {
  description = "Tenancy of the instance. Valid values: default, dedicated, host"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated", "host"], var.tenancy)
    error_message = "Tenancy must be one of: default, dedicated, host"
  }
}

variable "user_data" {
  description = "User data script (will be base64 encoded)"
  type        = string
  default     = ""
}

variable "user_data_base64" {
  description = "Base64-encoded user data script"
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "Replace instance when user data changes"
  type        = bool
  default     = false
}

variable "source_dest_check" {
  description = "Enable source/destination checking"
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address with the instance"
  type        = bool
  default     = false
}

variable "private_ip" {
  description = "Private IP address to assign to the instance"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Size of the root volume in GiB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the root volume. Valid values: gp2, gp3, io1, io2, standard"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "standard"], var.root_volume_type)
    error_message = "Root volume type must be one of: gp2, gp3, io1, io2, standard"
  }
}

variable "root_volume_iops" {
  description = "IOPS for the root volume (only for io1, io2, gp3)"
  type        = number
  default     = null
}

variable "root_volume_throughput" {
  description = "Throughput for the root volume in MiB/s (only for gp3)"
  type        = number
  default     = null
}

variable "root_volume_encrypted" {
  description = "Enable encryption for the root volume"
  type        = bool
  default     = true
}

variable "root_volume_kms_key_id" {
  description = "KMS key ID for root volume encryption"
  type        = string
  default     = null
}

variable "root_volume_delete_on_termination" {
  description = "Delete root volume on instance termination"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
