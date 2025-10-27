# Envoy Proxy Module - Complete Setup Guide

## ✅ What's Been Updated

The envoy-proxy composition module has been fully updated with all modern features matching squid-proxy + additional envoy-specific capabilities.

### Features Added:
1. **SSH Key Generation** - Auto-generates key pairs (no local private key storage)
2. **S3 Config Upload** - Automatic upload of envoy.yaml and other configs
3. **Userdata Templating** - Dynamic variable substitution in userdata
4. **Envoy Config Templating** - Template variables in envoy.yaml
5. **Existing LB Support** - Can attach to existing ALB/NLB
6. **IAM Enhancements** - SSM parameters policy + DeleteObject permission
7. **Instance Refresh** - Automatic rolling updates when config changes
8. **Config Version Tracking** - Hash-based change detection

---

## 📁 Current File Structure

```
live/dev/eu-central-1/envoy-proxy/
├── config/
│   ├── envoy.yaml          # Your envoy configuration (with templates)
│   └── README.md            # (to be created)
├── templates/
│   └── userdata.sh          # Bootstrap script
├── main.tf                  # (needs update)
├── variables.tf             # (needs update)
├── terraform.tfvars         # (needs update)
├── outputs.tf
├── backend.tf
└── versions.tf
```

---

## 🔧 Required Updates to live/dev/envoy-proxy

### 1. Update `variables.tf`

Add these variables:

```hcl
variable "generate_ssh_key" {
  type    = bool
  default = true
}

variable "upload_config_to_s3" {
  type    = bool
  default = false
}

variable "hyperswitch_cloudfront_dns" {
  type    = string
  default = ""
}

variable "internal_loadbalancer_dns" {
  type    = string
  default = ""
}

variable "create_lb" {
  type    = bool
  default = true
}

variable "existing_tg_arn" {
  type    = string
  default = null
}

variable "enable_instance_refresh" {
  type    = bool
  default = true
}
```

### 2. Update `main.tf`

Replace the module call with:

```hcl
module "envoy_proxy" {
  source = "../../../../modules/composition/envoy-proxy"

  environment  = var.environment
  project_name = var.project_name

  # Network
  vpc_id               = var.vpc_id
  proxy_subnet_ids     = var.proxy_subnet_ids
  lb_subnet_ids        = var.lb_subnet_ids
  eks_security_group_id = var.eks_security_group_id

  # Envoy Ports
  envoy_listener_port = var.envoy_listener_port
  envoy_admin_port    = var.envoy_admin_port

  # Instance Config
  ami_id        = var.ami_id
  instance_type = var.instance_type

  # SSH
  generate_ssh_key = var.generate_ssh_key
  key_name         = var.key_name

  # Userdata & Config Templates
  custom_userdata        = file("${path.module}/templates/userdata.sh")
  envoy_config_template  = file("${path.module}/config/envoy.yaml")

  # Template Variables for envoy.yaml
  hyperswitch_cloudfront_dns = var.hyperswitch_cloudfront_dns
  internal_loadbalancer_dns  = var.internal_loadbalancer_dns

  # S3 Config Upload
  upload_config_to_s3      = var.upload_config_to_s3
  config_files_source_path = "${path.module}/config"
  config_bucket_name       = var.config_bucket_name
  config_bucket_arn        = var.config_bucket_arn

  # ASG
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Load Balancer
  create_lb           = var.create_lb
  create_target_group = var.create_target_group
  existing_tg_arn     = var.existing_tg_arn

  # Instance Refresh
  enable_instance_refresh = var.enable_instance_refresh

  # Monitoring
  enable_detailed_monitoring = var.enable_detailed_monitoring
  root_volume_size           = var.root_volume_size
  root_volume_type           = var.root_volume_type

  tags = var.common_tags
}
```

### 3. Update `terraform.tfvars`

Add configuration:

```hcl
#=======================================================================
# SSH KEY CONFIGURATION
#=======================================================================
generate_ssh_key = true  # Auto-generate key, use SSM to connect

#=======================================================================
# S3 CONFIG UPLOAD
#=======================================================================
upload_config_to_s3 = true  # Auto-upload envoy.yaml to S3

#=======================================================================
# ENVOY CONFIGURATION TEMPLATING
#=======================================================================
# These values replace {{placeholders}} in config/envoy.yaml
hyperswitch_cloudfront_dns = "d1234567890.cloudfront.net"
internal_loadbalancer_dns  = "internal-alb-123456789.eu-central-1.elb.amazonaws.com"

#=======================================================================
# INSTANCE REFRESH (Auto-update instances when config changes)
#=======================================================================
enable_instance_refresh = true

#=======================================================================
# LOAD BALANCER - Use existing or create new
#=======================================================================
# MODE 1: Create new LB
create_lb = true

# MODE 2: Use existing target group
# create_lb = false
# existing_tg_arn = "arn:aws:elasticloadbalancing:..."
```

---

## 📝 Envoy Config Templating

Your `config/envoy.yaml` can use these placeholders:

```yaml
# config/envoy.yaml
static_resources:
  listeners:
  - name: listener_https
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 8443
  clusters:
  - name: hyperswitch_cloudfront
    connect_timeout: 30s
    type: LOGICAL_DNS
    dns_lookup_family: V4_ONLY
    load_assignment:
      cluster_name: hyperswitch_cloudfront
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: {{hyperswitch_cloudfront_dns}}  # ← Replaced by terraform
                port_value: 443

  - name: internal_alb
    connect_timeout: 30s
    type: LOGICAL_DNS
    load_assignment:
      cluster_name: internal_alb
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: {{internal_loadbalancer_dns}}  # ← Replaced by terraform
                port_value: 80
```

---

## 🔄 Instance Refresh - How It Works

When you update `config/envoy.yaml`:

1. **Terraform detects change** - Config hash changes
2. **New launch template created** - With updated config
3. **Instance refresh triggered** - ASG starts rolling replacement
4. **Zero downtime** - Keeps 50% instances healthy during update

```bash
# Update envoy.yaml
vim config/envoy.yaml

# Apply changes
terraform apply

# Terraform will:
# ✅ Upload new envoy.yaml to S3
# ✅ Update launch template
# ✅ Trigger instance refresh automatically
# ✅ Instances replaced one-by-one (zero downtime)
```

---

## 🚀 Quick Start

```bash
cd terraform/aws/live/dev/eu-central-1/envoy-proxy

# 1. Update variables.tf (add new variables)
# 2. Update main.tf (new module call)
# 3. Update terraform.tfvars (set your values)

# 4. Initialize
terraform init

# 5. Plan
terraform plan

# 6. Apply
terraform apply
```

---

## ✅ Verification Checklist

After `terraform apply`:

```bash
# Check outputs
terraform output

# Verify config uploaded to S3
aws s3 ls s3://your-config-bucket/envoy/

# Check ASG
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names dev-hyperswitch-envoy-asg

# Check instance refresh status
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name dev-hyperswitch-envoy-asg

# Connect to instance via SSM
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names dev-hyperswitch-envoy-asg \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

aws ssm start-session --target $INSTANCE_ID
```

---

## 🎯 Next Steps

1. Update `live/dev/envoy-proxy/variables.tf`
2. Update `live/dev/envoy-proxy/main.tf`
3. Update `live/dev/envoy-proxy/terraform.tfvars`
4. Create `live/dev/envoy-proxy/config/README.md`
5. Run `terraform init && terraform plan`
6. Review changes carefully
7. Run `terraform apply`

---

## 🐛 Troubleshooting

**Issue: Config not updating on instances**
- Check S3 upload: `aws s3 ls s3://bucket/envoy/`
- Verify instance refresh triggered: Check ASG console
- Check userdata logs: `sudo tail -f /var/log/cloud-init-output.log`

**Issue: Instances not healthy**
- Check envoy admin: `curl localhost:9901/ready`
- Check envoy logs: `sudo journalctl -u envoy.service`
- Verify security groups allow health check on port 9901

**Issue: Instance refresh stuck**
- Check ASG events in console
- Verify min_healthy_percentage allows replacement
- Check if new instances are passing health checks

All done! 🎉
