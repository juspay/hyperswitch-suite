# SNS Module

Terraform module for creating AWS SNS topics, subscriptions, and policies.

## Usage

### Basic Topic with Subscriptions

```hcl
module "sns" {
  source = "./terraform/aws/modules/composition/sns"

  environment  = "dev"
  project_name = "hyperswitch"

  topics = {
    alerts = {
      name         = "hyperswitch-alerts"
      display_name = "Hyperswitch Alerts"

      subscriptions = {
        email = {
          protocol = "email"
          endpoint = "alerts@example.com"
        }
        slack = {
          protocol = "https"
          endpoint = "https://hooks.slack.com/services/xxx"
        }
      }
    }
  }
}
```

### FIFO Topic

```hcl
module "sns" {
  source = "./terraform/aws/modules/composition/sns"

  environment  = "dev"
  project_name = "hyperswitch"

  topics = {
    orders = {
      name                        = "hyperswitch-orders.fifo"
      fifo_topic                  = true
      content_based_deduplication = true

      subscriptions = {
        sqs = {
          protocol = "sqs"
          endpoint = aws_sqs_queue.orders.arn
        }
      }
    }
  }
}
```

### Topic with KMS Encryption

```hcl
module "sns" {
  source = "./terraform/aws/modules/composition/sns"

  environment  = "dev"
  project_name = "hyperswitch"

  topics = {
    secure = {
      name              = "hyperswitch-secure"
      kms_master_key_id = aws_kms_key.sns.arn
    }
  }
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| environment | Environment name | `string` | n/a |
| project_name | Project name for resource naming | `string` | `"hyperswitch"` |
| region | AWS region | `string` | `null` |
| tags | Common tags for all resources | `map(string)` | `{}` |
| topics | Map of SNS topic configurations | `map(object)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| topic_arns | Map of topic keys to ARNs |
| topic_names | Map of topic keys to names |
| topic_ids | Map of topic keys to topic IDs |
| subscriptions | Map of subscription keys to details |
| subscription_arns | Map of subscription keys to ARNs |
| topic_policies | Map of topic keys to their policies |
| region | AWS region |

## Subscription Protocols

| Protocol | Endpoint Format |
|----------|-----------------|
| `email` | `user@example.com` |
| `email-json` | `user@example.com` |
| `http` | `http://example.com/webhook` |
| `https` | `https://example.com/webhook` |
| `sqs` | SQS queue ARN |
| `lambda` | Lambda function ARN |
| `sms` | Phone number (E.164 format) |
| `application` | Mobile app endpoint ARN |
