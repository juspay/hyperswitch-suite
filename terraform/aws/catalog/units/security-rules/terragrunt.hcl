include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  # Core components — always present in any stack that uses this unit
  # (eks, database, elasticache are not flagged; their deps stay unconditional)
  has_efs         = try(values.enable_efs, true)
  has_squid       = try(values.enable_squid_proxy, true)
  has_jump_host   = try(values.enable_jump_host, true)
  has_locker      = try(values.enable_locker, true)
  has_istio       = try(values.enable_istio, true)
  has_envoy       = try(values.enable_envoy_proxy, true)
  has_kafka       = try(values.enable_kafka, true)
  has_grafana     = try(values.enable_grafana, true)
  has_utils_lb    = try(values.enable_utils_load_balancer, true)
  has_loki        = try(values.enable_loki, true)
  has_ratelimiter = try(values.enable_ratelimiter, true)
  has_vpc_network = try(values.vpc_id, null) == null
  # Internal-only components — default OFF (not present in the public catalog)
  has_encryption_service = try(values.enable_encryption_service, false)
  has_auth_proxy         = try(values.enable_auth_proxy, false)
  has_wazuh              = try(values.enable_wazuh_endpoints, false)
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/security-rules?ref=security-rules-v0.2.1"
}

dependency "eks" {
  config_path = "../application-stack/eks-01"
  mock_outputs = {
    cluster_security_group_id = "sg-eks-cluster"
    node_security_group_id    = "sg-eks-node"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "squid" {
  config_path = "../squid-proxy"
  enabled     = local.has_squid
  mock_outputs = {
    asg_security_group_id = "sg-squid-asg"
    nlb_security_group_id = "sg-squid-nlb"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# dependency "utils_squid" {
#   config_path = "../utils-squid-proxy"

#   mock_outputs = {
#     asg_security_group_id = "sg-utils-squid-mock"
#     nlb_security_group_id = "sg-utils-squid-nlb-mock"
#   }
#   mock_outputs_allowed_terraform_commands = ["validate", "plan"]
#   mock_outputs_merge_with_state = true
# }

dependency "jump_host" {
  config_path = "../jump-host"
  enabled     = local.has_jump_host
  mock_outputs = {
    jump_security_group_id = "sg-jump-host"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "database" {
  config_path = "../database"
  mock_outputs = {
    security_group_id = "sg-database"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "elasticache" {
  config_path = "../elasticache"
  mock_outputs = {
    security_group_id = "sg-elasticache"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "locker" {
  config_path = "../locker"
  enabled     = local.has_locker
  mock_outputs = {
    security_group_id     = "sg-locker"
    alb_security_group_id = "sg-locker-alb"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# dependency "cassandra" {
#   config_path = "../cassandra"
# }

dependency "vpc-network" {
  config_path = "../vpc-network"
  enabled     = local.has_vpc_network
  mock_outputs = {
    vpc_endpoint_security_group_id = "sg-vpc-endpoint"
    vpc_cidr_block                 = "10.0.0.0/16"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# dependency "lambda_common" {
#   config_path = "../lambda-resource/lambda-common"

#   mock_outputs = {
#     security_group_id = "sg-lambda-common"
#   }
#   mock_outputs_allowed_terraform_commands = ["validate", "plan"]
#   mock_outputs_merge_with_state = true
# }

dependency "istio" {
  config_path = "../application-stack/apps/istio"
  enabled     = local.has_istio
  mock_outputs = {
    lb_security_group_id = ["sg-istio-lb"]
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "envoy" {
  config_path = "../envoy-proxy"
  enabled     = local.has_envoy
  mock_outputs = {
    asg_security_group_id = "sg-envoy-asg"
    lb_security_group_id  = "sg-envoy-lb"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "encryption_service" {
  config_path = "../application-stack/apps/encryption-service"
  enabled     = local.has_encryption_service
  mock_outputs = {
    db_security_group_id = "sg-encryption-service-db"
    lb_security_group_id = "sg-encryption-service-lb"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "kafka" {
  config_path = "../kafka"
  enabled     = local.has_kafka

  mock_outputs = {
    broker_security_group_id     = "sg-kafka-broker"
    controller_security_group_id = "sg-kafka-controller"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# dependency "clickhouse" {
#   config_path = "../clickhouse"
# }

dependency "grafana" {
  config_path = "../application-stack/apps/grafana"
  enabled     = local.has_grafana
  mock_outputs = {
    database_security_group_id = "sg-grafana-db"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "utils_load_balancer" {
  config_path = "../application-stack/utils-load-balancer"
  enabled     = local.has_utils_lb
  mock_outputs = {
    security_group_id = "sg-utils-lb"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "hyperswitch_auth_proxy" {
  config_path = "../application-stack/apps/hyperswitch-auth-proxy"
  enabled     = local.has_auth_proxy
  mock_outputs = {
    lb_security_group_id = "sg-hyperswitch-auth-proxy-lb"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# dependency "opensearch" {
#   config_path = "../opensearch"

#   mock_outputs = {
#     security_group_id = "sg-opensearch"
#   }
#   mock_outputs_allowed_terraform_commands = ["validate", "plan"]
#   mock_outputs_merge_with_state = true
# }

dependency "loki" {
  config_path = "../application-stack/apps/loki"
  enabled     = local.has_loki

  mock_outputs = {
    security_group_id = "sg-loki"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "ratelimiter" {
  config_path = "../application-stack/apps/ratelimiter"
  enabled     = local.has_ratelimiter

  mock_outputs = {
    elasticache_security_group_id = "sg-ratelimiter-elasticache"
    lb_security_group_id          = "sg-ratelimiter-lb"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "efs" {
  config_path = "../efs"
  enabled     = local.has_efs

  mock_outputs = {
    security_group_ids = { "superposition-backup" = "sg-efs-mock" }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# dependency "hypersage" {
#   config_path = "../application-stack/apps/hypersage"

#   mock_outputs = {
#     db_security_group_id = "sg-hypersage-db-mock"
#   }
# }

inputs = {
  region = include.root.locals.region

  ingress_rules = merge(
    {
      eks_cluster_ingress = {
        sg_id = dependency.eks.outputs.cluster_security_group_id
        rules = concat(
          [
            {
              description = "HTTPS access from cluster security group itself"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.eks.outputs.cluster_security_group_id]
            }
          ],
          local.has_squid ? [
            {
              description = "Ingress from Squid"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.squid.outputs.asg_security_group_id]
            }
          ] : []
        )
      },
      eks_node_ingress = {
        sg_id = dependency.eks.outputs.node_security_group_id
        rules = concat(
          [
            {
              description = "Allow all traffic from EKS cluster security group"
              from_port   = 0
              to_port     = 65535
              protocol    = "-1"
              sg_id       = [dependency.eks.outputs.cluster_security_group_id]
            }
          ],
          local.has_istio ? [
            {
              description = "HTTP from Istio ingress LB"
              from_port   = 80
              to_port     = 80
              protocol    = "tcp"
              sg_id       = [dependency.istio.outputs.lb_security_group_id[0]]
            },
            {
              description = "HTTPS from Istio ingress LB"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.istio.outputs.lb_security_group_id[0]]
            },
            {
              description = "Istio healthcheck from Istio ingress LB"
              from_port   = 15021
              to_port     = 15021
              protocol    = "tcp"
              sg_id       = [dependency.istio.outputs.lb_security_group_id[0]]
            }
          ] : [],
          local.has_utils_lb ? [
            {
              description = "HTTPS from Utils Load Balancer"
              from_port   = 0
              to_port     = 65535
              protocol    = "-1"
              sg_id       = [dependency.utils_load_balancer.outputs.security_group_id]
            }
          ] : [],
          local.has_ratelimiter ? [
            {
              description = "Ingress from ratelimiter Load Balancer"
              from_port   = 0
              to_port     = 65535
              protocol    = "-1"
              sg_id       = [dependency.ratelimiter.outputs.lb_security_group_id]
            }
          ] : []
        )
      },
      database_ingress = {
        sg_id = dependency.database.outputs.security_group_id
        rules = concat(
          local.has_jump_host ? [
            {
              description = "PostgreSQL access from internal jump host"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
            }
          ] : [],
          [
            {
              description = "PostgreSQL access from EKS nodes"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.eks.outputs.node_security_group_id]
            },
            # {
            #   description = "PostgreSQL access from Lambda (via RDS Proxy)"
            #   from_port   = 5432
            #   to_port     = 5432
            #   protocol    = "tcp"
            #   sg_id       = [dependency.lambda_common.outputs.security_group_id]
            # }
          ]
        )
      },
      elasticache_ingress = {
        sg_id = dependency.elasticache.outputs.security_group_id
        rules = concat(
          local.has_jump_host ? [
            {
              description = "Redis access from internal jump host"
              from_port   = 6379
              to_port     = 6379
              protocol    = "tcp"
              sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
            }
          ] : [],
          [
            {
              description = "Redis/Valkey access from EKS nodes"
              from_port   = 6379
              to_port     = 6379
              protocol    = "tcp"
              sg_id       = [dependency.eks.outputs.node_security_group_id]
            }
          ]
        )
      }
    },
    { for k, v in {
      squid_ingress = {
        sg_id = dependency.squid.outputs.asg_security_group_id
        rules = local.has_jump_host ? [
          {
            description = "SSH access from external jump host"
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
          }
        ] : []
      },
      squid_nlb_ingress = {
        sg_id = dependency.squid.outputs.nlb_security_group_id
        rules = [
          {
            description = "Ingress from EKS nodes"
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            sg_id       = [dependency.eks.outputs.node_security_group_id]
          }
        ]
      }
    } : k => v if local.has_squid },
    # utils_squid_ingress = {
    #   sg_id = dependency.utils_squid.outputs.asg_security_group_id
    #   rules = [
    #     {
    #       description = "SSH access from external jump host"
    #       from_port   = 22
    #       to_port     = 22
    #       protocol    = "tcp"
    #       sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
    #     }
    #   ]
    # },
    # utils_squid_nlb_ingress = {
    #   sg_id = dependency.utils_squid.outputs.nlb_security_group_id
    #   rules = [
    #     {
    #       description = "Ingress from EKS nodes"
    #       from_port   = 80
    #       to_port     = 80
    #       protocol    = "tcp"
    #       sg_id       = [dependency.eks.outputs.node_security_group_id]
    #     }
    #   ]
    # },
    { for k, v in {
      encryption_service_db_ingress = {
        sg_id = dependency.encryption_service.outputs.db_security_group_id
        rules = concat(
          local.has_jump_host ? [
            {
              description = "PostgreSQL access from internal jump host"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
            }
          ] : [],
          [
            {
              description = "PostgreSQL access from EKS nodes"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.eks.outputs.node_security_group_id]
            }
          ]
        )
      }
    } : k => v if local.has_encryption_service },
    { for k, v in {
      ratelimiter_elasticache_ingress = {
        sg_id = dependency.ratelimiter.outputs.elasticache_security_group_id
        rules = [
          {
            description = "Redis/Valkey access from EKS nodes for ratelimiter"
            from_port   = 6379
            to_port     = 6379
            protocol    = "tcp"
            sg_id       = [dependency.eks.outputs.node_security_group_id]
          }
        ]
      },
      ratelimiter_lb_ingress = {
        sg_id = dependency.ratelimiter.outputs.lb_security_group_id
        rules = local.has_envoy ? [
          {
            description = "gRPC access from Envoy ASG to ratelimiter LB"
            from_port   = 8091
            to_port     = 8091
            protocol    = "tcp"
            sg_id       = [dependency.envoy.outputs.asg_security_group_id]
          }
        ] : []
      }
    } : k => v if local.has_ratelimiter },
    # clickhouse_lb_ingress = {
    #   sg_id = dependency.clickhouse.outputs.alb_security_group_id
    #   rules = [
    #     {
    #       description = "Clickhouse HTTP access from EKS nodes"
    #       from_port   = 80
    #       to_port     = 80
    #       protocol    = "tcp"
    #       sg_id       = [dependency.eks.outputs.node_security_group_id]
    #     }
    #   ]
    # },
    { for k, v in {
      locker_ingress = {
        sg_id = dependency.locker.outputs.security_group_id
        rules = local.has_jump_host ? [
          {
            description = "SSH access from internal jump host"
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
          }
        ] : []
      },
      locker_alb_ingress = {
        sg_id = dependency.locker.outputs.alb_security_group_id
        rules = [
          {
            description = "Locker ingress from sandbox worker nodes"
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            sg_id       = [dependency.eks.outputs.node_security_group_id]
          }
        ]
      }
    } : k => v if local.has_locker },
    # cassandra_ingress = {
    #   sg_id = dependency.cassandra.outputs.cassandra_security_group_id
    #   rules = [
    #     {
    #       description = "SSH access from external jump host"
    #       from_port   = 22
    #       to_port     = 22
    #       protocol    = "tcp"
    #       sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
    #     },
    #     {
    #       description = "Cassandra access from EKS nodes"
    #       from_port   = 9042
    #       to_port     = 9042
    #       protocol    = "tcp"
    #       sg_id       = [dependency.eks.outputs.node_security_group_id]
    #     }
    #   ]
    # },
    { for k, v in {
      vpc_endpoint_ingress = {
        sg_id = dependency.vpc-network.outputs.vpc_endpoint_security_group_id
        rules = concat(
          [
            {
              description = "HTTPS from Application Cluster"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.eks.outputs.node_security_group_id]
            },
            # {
            #   description = "HTTPS access from Cassandra"
            #   from_port   = 443
            #   to_port     = 443
            #   protocol    = "tcp"
            #   sg_id       = [dependency.cassandra.outputs.cassandra_security_group_id]
            # },
          ],
          local.has_locker ? [
            {
              description = "HTTPS access from Locker"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.locker.outputs.security_group_id]
            }
          ] : [],
          local.has_envoy ? [
            {
              description = "HTTPS access from Envoy ASG"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.envoy.outputs.asg_security_group_id]
            }
          ] : [],
          local.has_jump_host ? [
            {
              description = "HTTPS access from internal jump host"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
            }
          ] : []
          # {
          #   description = "HTTPS access from Lambda functions"
          #   from_port   = 443
          #   to_port     = 443
          #   protocol    = "tcp"
          #   sg_id       = [dependency.lambda_common.outputs.security_group_id]
          # }
        )
      }
    } : k => v if local.has_vpc_network },
    { for k, v in {
      envoy_asg_ingress = {
        sg_id = dependency.envoy.outputs.asg_security_group_id
        rules = local.has_jump_host ? [
          {
            description = "SSH access from external jump host"
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
          }
        ] : []
      },
      envoy_alb_ingress = {
        sg_id = dependency.envoy.outputs.lb_security_group_id
        rules = [
          {
            description = "HTTPS traffic from internet"
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr        = ["0.0.0.0/0"]
          },
          {
            description = "HTTP traffic from internet (redirect to HTTPS)"
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            cidr        = ["0.0.0.0/0"]
          },
        ]
      }
    } : k => v if local.has_envoy },
    { for k, v in {
      kafka_broker_ingress = {
        sg_id = dependency.kafka.outputs.broker_security_group_id
        rules = concat(
          [
            {
              description = "Allow Ingress from EKS nodes for Kafka access"
              from_port   = 9092
              to_port     = 9092
              protocol    = "tcp"
              sg_id       = [dependency.eks.outputs.node_security_group_id]
            }
          ],
          local.has_jump_host ? [
            {
              description = "Kafka client access from internal jump host"
              from_port   = 9092
              to_port     = 9092
              protocol    = "tcp"
              sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
            },
            {
              description = "SSH access from external jump host"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
            }
          ] : []
        )
      },
      kafka_controller_ingress = {
        sg_id = dependency.kafka.outputs.controller_security_group_id
        rules = concat(
          [
            {
              description = "Prometheus scrape access to Kafka controller security group"
              from_port   = 9091
              to_port     = 9091
              protocol    = "tcp"
              sg_id       = [dependency.eks.outputs.node_security_group_id]
            }
          ],
          local.has_jump_host ? [
            {
              description = "SSH access from external jump host"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
            }
          ] : []
        )
      }
    } : k => v if local.has_kafka },
    # clickhouse_server_ingress = {
    #   sg_id = dependency.clickhouse.outputs.server_security_group_id
    #   rules = [
    #     {
    #       description = "HTTP access from EKS nodes"
    #       from_port   = 80
    #       to_port     = 80
    #       protocol    = "tcp"
    #       sg_id       = [dependency.eks.outputs.node_security_group_id]
    #     },
    #     {
    #       description = "Prometheus scrape access from EKS nodes"
    #       from_port   = 9091
    #       to_port     = 9091
    #       protocol    = "tcp"
    #       sg_id       = [dependency.eks.outputs.node_security_group_id]
    #     },
    #     {
    #       description = "SSH access from external jump host"
    #       from_port   = 22
    #       to_port     = 22
    #       protocol    = "tcp"
    #       sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
    #     },
    #     {
    #       description = "Allow access from Clickhouse-server in eu-central-1"
    #       from_port   = 22
    #       to_port     = 22
    #       protocol    = "tcp"
    #       cidr       = ["10.41.32.0/26"]
    #     },
    #     {
    #       description = "Allow access for clickhouse-client pipe in eu-central-1"
    #       from_port   = 9000
    #       to_port     = 9000
    #       protocol    = "tcp"
    #       cidr       = ["10.41.32.0/26"]
    #     }
    #   ]
    # },
    { for k, v in {
      grafana_db_ingress = {
        sg_id = dependency.grafana.outputs.database_security_group_id
        rules = concat(
          [
            {
              description = "PostgreSQL access from EKS nodes for Grafana"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.eks.outputs.node_security_group_id]
            }
          ],
          local.has_jump_host ? [
            {
              description = "PostgreSQL access from internal jump host"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
            },
          ] : []
        )
      }
    } : k => v if local.has_grafana },
    { for k, v in {
      istio_ingress_lb = {
        sg_id = dependency.istio.outputs.lb_security_group_id[0]
        rules = concat(
          [
            {
              description = "HTTPS traffic from internet"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              cidr        = ["0.0.0.0/0"]
            }
          ],
          local.has_envoy ? [
            {
              description = "HTTP from Envoy ASG"
              from_port   = 80
              to_port     = 80
              protocol    = "tcp"
              sg_id       = [dependency.envoy.outputs.asg_security_group_id]
            },
            {
              description = "HTTPS from Envoy ASG"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.envoy.outputs.asg_security_group_id]
            },
            {
              description = "Istio healthcheck from Envoy ASG"
              from_port   = 15021
              to_port     = 15021
              protocol    = "tcp"
              sg_id       = [dependency.envoy.outputs.asg_security_group_id]
            }
          ] : [],
          [
            {
              description = "ICMP Destination Unreachable"
              from_port   = 3
              to_port     = 4
              protocol    = "icmp"
              cidr        = ["0.0.0.0/0"]
            },
            {
              description = "Healthcheck port from internet"
              from_port   = 15021
              to_port     = 15021
              protocol    = "tcp"
              cidr        = ["0.0.0.0/0"]
            }
          ]
        )
      }
    } : k => v if local.has_istio },
    { for k, v in {
      utils_lb_ingress = {
        sg_id = dependency.utils_load_balancer.outputs.security_group_id
        rules = concat(
          try(values.ip_list, null) != null ? [
            {
              description = "Ingress from VPN IPs"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              cidr        = values.ip_list.vpn_cidr_blocks
            },
            {
              description = "Ingress from Office IPs"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              cidr        = values.ip_list.office_ips
            }
          ] : [],
          [
            {
              description = "Ingress from Xyne NAT IPs"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              cidr        = ["34.100.135.155/32", "34.93.145.167/32"]
            }
            # {
            #   description = "Ingress from Phantom IPs"
            #   from_port   = 443
            #   to_port     = 443
            #   protocol    = "tcp"
            #   cidr        = values.ip_list.phantom_ips
            # }
          ]
        )
      }
    } : k => v if local.has_utils_lb },
    { for k, v in {
      hyperswitch_auth_proxy_lb_ingress = {
        sg_id = dependency.hyperswitch_auth_proxy.outputs.lb_security_group_id
        rules = local.has_envoy ? [
          {
            description = "HTTP from Envoy ASG"
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            sg_id       = [dependency.envoy.outputs.asg_security_group_id]
          },
          {
            description = "HTTPS from Envoy ASG"
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            sg_id       = [dependency.envoy.outputs.asg_security_group_id]
          }
        ] : []
      }
    } : k => v if local.has_auth_proxy },
    { for k, v in {
      encryption_service_lb_ingress = {
        sg_id = dependency.encryption_service.outputs.lb_security_group_id
        rules = local.has_locker ? [
          {
            description = "HTTPS from Locker instance"
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            sg_id       = [dependency.locker.outputs.security_group_id]
          }
        ] : []
      }
    } : k => v if local.has_encryption_service },
    # lambda_common_ingress = {
    #   sg_id = dependency.lambda_common.outputs.security_group_id
    #   rules = [
    #     {
    #       description = "All traffic from Lambda security group itself (step_1 to step_2 invocation)"
    #       from_port   = 0
    #       to_port     = 65535
    #       protocol    = "tcp"
    #       sg_id       = [dependency.lambda_common.outputs.security_group_id]
    #     }
    #   ]
    # },
    { for k, v in {
      efs_ingress = {
        sg_id = dependency.efs.outputs.security_group_ids["superposition-backup"]
        rules = [
          {
            description = "NFS from EKS generic_compute nodes"
            from_port   = 2049
            to_port     = 2049
            protocol    = "tcp"
            sg_id       = [dependency.eks.outputs.node_security_group_id]
          }
        ]
      }
    } : k => v if local.has_efs },
    { for k, v in {
      wazuh_custom_endpoint_ingress = {
        sg_id = dependency.vpc-network.outputs.vpc_endpoint_security_group_id
        rules = [
          {
            description = "Allow Wazuh Syslog from VPC"
            from_port   = 1514
            to_port     = 1514
            protocol    = "tcp"
            cidr        = [dependency.vpc-network.outputs.vpc_cidr_block]
          },
          {
            description = "Allow Wazuh Agent from VPC"
            from_port   = 1515
            to_port     = 1515
            protocol    = "tcp"
            cidr        = [dependency.vpc-network.outputs.vpc_cidr_block]
          }
        ]
      }
    } : k => v if local.has_vpc_network && local.has_wazuh }
    # opensearch_ingress = {
    #   sg_id = dependency.opensearch.outputs.security_group_id
    #   rules = [
    #     {
    #       description = "HTTPS access from EKS nodes"
    #       from_port   = 443
    #       to_port     = 443
    #       protocol    = "tcp"
    #       sg_id       = [dependency.eks.outputs.node_security_group_id]
    #     },
    #     {
    #       description = "HTTPS access from VPN IPs"
    #       from_port   = 443
    #       to_port     = 443
    #       protocol    = "tcp"
    #       cidr        = values.ip_list.vpn_cidr_blocks
    #     },
    #     {
    #       description = "HTTPS access from data subnet in eu-central-1"
    #       from_port   = 443
    #       to_port     = 443
    #       protocol    = "tcp"
    #       cidr        = ["10.41.32.0/20"]
    #     }
    #   ]
    # },
    # hypersage_db_ingress = {
    #   sg_id = dependency.hypersage.outputs.db_security_group_id
    #   rules = [
    #     {
    #       description = "Ingress from EKS nodes for hypersage application access"
    #       from_port   = 5432
    #       to_port     = 5432
    #       protocol    = "tcp"
    #       sg_id       = [dependency.eks.outputs.node_security_group_id]
    #     },
    #     {
    #       description = "Ingress from internal jump host for hypersage database admin access"
    #       from_port   = 5432
    #       to_port     = 5432
    #       protocol    = "tcp"
    #       sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
    #     }
    #   ]
    # },
  )

  egress_rules = merge(
    {
      eks_cluster_egress = {
        sg_id = dependency.eks.outputs.cluster_security_group_id
        rules = [
          {
            description = "Allow all traffic to EKS nodes"
            from_port   = 0
            to_port     = 65535
            protocol    = "-1"
            sg_id       = [dependency.eks.outputs.node_security_group_id]
          }
        ]
      },
      eks_node_egress = {
        sg_id = dependency.eks.outputs.node_security_group_id
        rules = concat(
          local.has_squid ? [
            {
              description = "Allow HTTP to internet via squid proxy"
              from_port   = 80
              to_port     = 80
              protocol    = "tcp"
              sg_id       = [dependency.squid.outputs.nlb_security_group_id]
            }
          ] : [],
          # {
          #   description = "Allow HTTP to internet via utils squid proxy"
          #   from_port   = 80
          #   to_port     = 80
          #   protocol    = "tcp"
          #   sg_id       = [dependency.utils_squid.outputs.nlb_security_group_id]
          # },
          try(values.s3_prefix_list_id, null) != null ? [
            {
              description     = "S3 VPC endpoint access"
              from_port       = 443
              to_port         = 443
              protocol        = "tcp"
              prefix_list_ids = [values.s3_prefix_list_id]
            }
          ] : [],
          local.has_vpc_network ? [
            {
              description = "HTTPS to VPC endpoint security group"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            }
          ] : [],
          local.has_locker ? [
            {
              description = "Egress to Locker"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.locker.outputs.security_group_id]
            }
          ] : [],
          local.has_encryption_service ? [
            {
              description = "PostgreSQL access to encryption service database"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.encryption_service.outputs.db_security_group_id]
            }
          ] : [],
          local.has_kafka ? [
            {
              description = "Kafka access to broker security group"
              from_port   = 9092
              to_port     = 9092
              protocol    = "tcp"
              sg_id       = [dependency.kafka.outputs.broker_security_group_id]
            },
            {
              description = "Prometheus scrape access to Kafka broker security group"
              from_port   = 9091
              to_port     = 9091
              protocol    = "tcp"
              sg_id       = [dependency.kafka.outputs.broker_security_group_id]
            },
            {
              description = "Prometheus scrape access to Kafka controller security group"
              from_port   = 9091
              to_port     = 9091
              protocol    = "tcp"
              sg_id       = [dependency.kafka.outputs.controller_security_group_id]
            }
          ] : [],
          # {
          #   description = "HTTP access to ClickHouse ALB security group"
          #   from_port   = 80
          #   to_port     = 80
          #   protocol    = "tcp"
          #   sg_id       = [dependency.clickhouse.outputs.alb_security_group_id]
          # },
          # {
          #   description = "Prometheus scrape access to ClickHouse server security group"
          #   from_port   = 9091
          #   to_port     = 9091
          #   protocol    = "tcp"
          #   sg_id       = [dependency.clickhouse.outputs.server_security_group_id]
          # },
          [
            {
              description = "PostgreSQL access to RDS database"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.database.outputs.security_group_id]
            },
            {
              description = "Redis access to ElastiCache"
              from_port   = 6379
              to_port     = 6379
              protocol    = "tcp"
              sg_id       = [dependency.elasticache.outputs.security_group_id]
            }
          ],
          local.has_ratelimiter ? [
            {
              description = "Redis access to ratelimiter ElastiCache"
              from_port   = 6379
              to_port     = 6379
              protocol    = "tcp"
              sg_id       = [dependency.ratelimiter.outputs.elasticache_security_group_id]
            }
          ] : [],
          local.has_grafana ? [
            {
              description = "PostgreSQL access to Grafana database"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.grafana.outputs.database_security_group_id]
            }
          ] : [],
          # {
          #   description = "HTTPS access to OpenSearch"
          #   from_port   = 443
          #   to_port     = 443
          #   protocol    = "tcp"
          #   sg_id       = [dependency.opensearch.outputs.security_group_id]
          # },
          # {
          #   description = "Cassandra access to Cassandra security group"
          #   from_port   = 9042
          #   to_port     = 9042
          #   protocol    = "tcp"
          #   sg_id       = [dependency.cassandra.outputs.cassandra_security_group_id]
          # },
          local.has_efs ? [
            {
              description = "NFS to EFS security group"
              from_port   = 2049
              to_port     = 2049
              protocol    = "tcp"
              sg_id       = [dependency.efs.outputs.security_group_ids["superposition-backup"]]
            }
          ] : [],
          # {
          #   description = "Egress to hypersage RDS database"
          #   from_port   = 5432
          #   to_port     = 5432
          #   protocol    = "tcp"
          #   sg_id       = [dependency.hypersage.outputs.db_security_group_id]
          # }
          try(values.enable_open_node_egress, false) ? [
            {
              description = "Allow all outbound (standalone default)"
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr        = ["0.0.0.0/0"]
            }
          ] : []
        )
      }
    },
    # cassandra_egress = {
    #   sg_id = dependency.cassandra.outputs.cassandra_security_group_id
    #   rules = [
    #     {
    #       description = "HTTPS access to VPC endpoints"
    #       from_port   = 443
    #       to_port     = 443
    #       protocol    = "tcp"
    #       sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
    #     }
    #   ]
    # },
    { for k, v in {
      squid_egress = {
        sg_id = dependency.squid.outputs.asg_security_group_id
        rules = concat(
          [
            {
              description = "Egress to Application EKS Control Pane"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.eks.outputs.cluster_security_group_id]
            },
            {
              description = "Allow HTTPS to internet"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              cidr        = ["0.0.0.0/0"]
            },
            # {
            #   description = "ClamAV antivirus"
            #   from_port   = 80
            #   to_port     = 80
            #   protocol    = "tcp"
            #   cidr        = ["10.41.16.0/20"]
            # },
            # {
            #   description = "Wazuh master - syslog"
            #   from_port   = 1515
            #   to_port     = 1515
            #   protocol    = "tcp"
            #   cidr        = ["10.41.16.0/20"]
            # },
            # {
            #   description = "Wazuh worker - events"
            #   from_port   = 1514
            #   to_port     = 1514
            #   protocol    = "tcp"
            #   cidr        = ["10.41.16.0/20"]
            # },
            # {
            #   description = "Wazuh master - registration"
            #   from_port   = 55000
            #   to_port     = 55000
            #   protocol    = "tcp"
            #   cidr        = ["10.41.16.0/20"]
            # },
          ],
          local.has_vpc_network && local.has_wazuh ? [
            {
              description = "Wazuh syslog to VPC endpoint"
              from_port   = 1514
              to_port     = 1514
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            },
            {
              description = "Wazuh agent registration to VPC endpoint"
              from_port   = 1515
              to_port     = 1515
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            }
          ] : [],
          [
            {
              description = "Redsys payment gateway"
              from_port   = 25443
              to_port     = 25443
              protocol    = "tcp"
              cidr        = ["0.0.0.0/0"]
            },
            {
              description = "Archipel connector"
              from_port   = 19585
              to_port     = 19585
              protocol    = "tcp"
              cidr        = ["0.0.0.0/0"]
            },
            {
              description = "Internet"
              from_port   = 8443
              to_port     = 8443
              protocol    = "tcp"
              cidr        = ["0.0.0.0/0"]
            },
            # {
            #   description = "Allow Vectors based logs to Loki Load Balancer"
            #   from_port   = 80
            #   to_port     = 80
            #   protocol    = "tcp"
            #   cidr        = ["10.41.0.0/16"]
            # }
          ]
        )
      }
    } : k => v if local.has_squid },
    # utils_squid_egress = {
    #   sg_id = dependency.utils_squid.outputs.asg_security_group_id
    #   rules = [
    #     {
    #       description = "Egress to Application EKS Control Pane"
    #       from_port   = 443
    #       to_port     = 443
    #       protocol    = "tcp"
    #       sg_id       = [dependency.eks.outputs.cluster_security_group_id]
    #     },
    #     {
    #       description = "Allow HTTPS to internet"
    #       from_port   = 443
    #       to_port     = 443
    #       protocol    = "tcp"
    #       cidr        = ["0.0.0.0/0"]
    #     },
    #     {
    #       description = "Redsys payment gateway"
    #       from_port   = 25443
    #       to_port     = 25443
    #       protocol    = "tcp"
    #       cidr        = ["0.0.0.0/0"]
    #     },
    #     {
    #       description = "Archipel connector"
    #       from_port   = 19585
    #       to_port     = 19585
    #       protocol    = "tcp"
    #       cidr        = ["0.0.0.0/0"]
    #     },
    #     {
    #       description = "Internet"
    #       from_port   = 8443
    #       to_port     = 8443
    #       protocol    = "tcp"
    #       cidr        = ["0.0.0.0/0"]
    #     }
    #   ]
    # },
    { for k, v in {
      ext_jump_host_egress = {
        sg_id = dependency.jump_host.outputs.jump_security_group_id
        rules = concat(
          local.has_envoy ? [
            {
              description = "SSH to envoy-proxy servers"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              sg_id       = [dependency.envoy.outputs.asg_security_group_id]
            }
          ] : [],
          local.has_squid ? [
            {
              description = "SSH to squid-proxy servers"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              sg_id       = [dependency.squid.outputs.asg_security_group_id]
            }
          ] : [],
          # {
          #   description = "SSH to utils-squid-proxy servers"
          #   from_port   = 22
          #   to_port     = 22
          #   protocol    = "tcp"
          #   sg_id       = [dependency.utils_squid.outputs.asg_security_group_id]
          # },
          # {
          #   description = "SSH to cassandra servers"
          #   from_port   = 22
          #   to_port     = 22
          #   protocol    = "tcp"
          #   sg_id       = [dependency.cassandra.outputs.cassandra_security_group_id]
          # },
          local.has_kafka ? [
            {
              description = "SSH to Kafka broker instances"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              sg_id       = [dependency.kafka.outputs.broker_security_group_id]
            },
            {
              description = "SSH to Kafka controller instances"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              sg_id       = [dependency.kafka.outputs.controller_security_group_id]
            }
          ] : []
          # {
          #   description = "SSH to ClickHouse server instances"
          #   from_port   = 22
          #   to_port     = 22
          #   protocol    = "tcp"
          #   sg_id       = [dependency.clickhouse.outputs.server_security_group_id]
          # },
        )
      },
      int_jump_host_egress = {
        sg_id = dependency.jump_host.outputs.jump_security_group_id
        rules = concat(
          [
            {
              description = "PostgreSQL access to database"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.database.outputs.security_group_id]
            },
            {
              description = "Redis access to elasticache"
              from_port   = 6379
              to_port     = 6379
              protocol    = "tcp"
              sg_id       = [dependency.elasticache.outputs.security_group_id]
            }
          ],
          local.has_locker ? [
            {
              description = "SSH access to locker"
              from_port   = 22
              to_port     = 22
              protocol    = "tcp"
              sg_id       = [dependency.locker.outputs.security_group_id]
            }
          ] : [],
          local.has_encryption_service ? [
            {
              description = "PostgreSQL access to encryption service database"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.encryption_service.outputs.db_security_group_id]
            }
          ] : [],
          local.has_grafana ? [
            {
              description = "PostgreSQL access to Grafana database"
              from_port   = 5432
              to_port     = 5432
              protocol    = "tcp"
              sg_id       = [dependency.grafana.outputs.database_security_group_id]
            }
          ] : [],
          try(values.s3_prefix_list_id, null) != null ? [
            {
              description     = "S3 VPC endpoint access"
              from_port       = 443
              to_port         = 443
              protocol        = "tcp"
              prefix_list_ids = [values.s3_prefix_list_id]
            }
          ] : [],
          local.has_vpc_network ? [
            {
              description = "HTTPS to VPC endpoint security group"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            }
          ] : [],
          local.has_vpc_network && local.has_wazuh ? [
            {
              description = "Wazuh syslog to VPC endpoint"
              from_port   = 1514
              to_port     = 1514
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            },
            {
              description = "Wazuh agent registration to VPC endpoint"
              from_port   = 1515
              to_port     = 1515
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            }
          ] : [],
          local.has_kafka ? [
            {
              description = "Kafka client access to broker security group"
              from_port   = 9092
              to_port     = 9092
              protocol    = "tcp"
              sg_id       = [dependency.kafka.outputs.broker_security_group_id]
            }
          ] : []
          # {
          #   description = "Egress to hypersage RDS database"
          #   from_port   = 5432
          #   to_port     = 5432
          #   protocol    = "tcp"
          #   sg_id       = [dependency.hypersage.outputs.db_security_group_id]
          # },
        )
      }
    } : k => v if local.has_jump_host },
    { for k, v in {
      envoy_asg_egress = {
        sg_id = dependency.envoy.outputs.asg_security_group_id
        rules = concat(
          local.has_istio ? [
            {
              description = "HTTP to Istio ingress LB"
              from_port   = 80
              to_port     = 80
              protocol    = "tcp"
              sg_id       = [dependency.istio.outputs.lb_security_group_id[0]]
            },
            {
              description = "HTTPS to Istio ingress LB"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.istio.outputs.lb_security_group_id[0]]
            },
            {
              description = "Istio healthcheck to Istio ingress LB"
              from_port   = 15021
              to_port     = 15021
              protocol    = "tcp"
              sg_id       = [dependency.istio.outputs.lb_security_group_id[0]]
            }
          ] : [],
          try(values.s3_prefix_list_id, null) != null ? [
            {
              description     = "S3 VPC endpoint access"
              from_port       = 443
              to_port         = 443
              protocol        = "tcp"
              prefix_list_ids = [values.s3_prefix_list_id]
            }
          ] : [],
          local.has_vpc_network ? [
            {
              description = "HTTPS access to VPC endpoint security group"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            }
          ] : [],
          local.has_auth_proxy ? [
            {
              description = "HTTPS to hyperswitch-auth-proxy LB"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.hyperswitch_auth_proxy.outputs.lb_security_group_id]
            },
            {
              description = "HTTP to hyperswitch-auth-proxy LB"
              from_port   = 80
              to_port     = 80
              protocol    = "tcp"
              sg_id       = [dependency.hyperswitch_auth_proxy.outputs.lb_security_group_id]
            }
          ] : [],
          local.has_loki ? [
            {
              description = "HTTP to Loki LB"
              from_port   = 80
              to_port     = 80
              protocol    = "tcp"
              sg_id       = [dependency.loki.outputs.security_group_id]
            }
          ] : [],
          local.has_ratelimiter ? [
            {
              description = "gRPC to ratelimiter LB"
              from_port   = 8091
              to_port     = 8091
              protocol    = "tcp"
              sg_id       = [dependency.ratelimiter.outputs.lb_security_group_id]
            }
          ] : [],
          local.has_vpc_network && local.has_wazuh ? [
            {
              description = "Wazuh syslog to VPC endpoint"
              from_port   = 1514
              to_port     = 1514
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            },
            {
              description = "Wazuh agent registration to VPC endpoint"
              from_port   = 1515
              to_port     = 1515
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            },
          ] : []
        )
      }
    } : k => v if local.has_envoy },
    { for k, v in {
      istio_ingress_lb_egress = {
        sg_id = dependency.istio.outputs.lb_security_group_id[0]
        rules = [
          {
            description = "HTTP to EKS worker nodes"
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            sg_id       = [dependency.eks.outputs.node_security_group_id]
          },
          {
            description = "HTTPS to EKS worker nodes"
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            sg_id       = [dependency.eks.outputs.node_security_group_id]
          },
          {
            description = "Istio healthcheck"
            from_port   = 15021
            to_port     = 15021
            protocol    = "tcp"
            sg_id       = [dependency.eks.outputs.node_security_group_id]
          }
        ]
      }
    } : k => v if local.has_istio },
    { for k, v in {
      locker_egress = {
        sg_id = dependency.locker.outputs.security_group_id
        rules = concat(
          local.has_vpc_network ? [
            {
              description = "Access to VPC endpoints security group"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            }
          ] : [],
          try(values.s3_prefix_list_id, null) != null ? [
            {
              description     = "Access to S3"
              from_port       = 443
              to_port         = 443
              protocol        = "tcp"
              prefix_list_ids = [values.s3_prefix_list_id]
            }
          ] : [],
          local.has_encryption_service ? [
            {
              description = "HTTPS to encryption service LB"
              from_port   = 443
              to_port     = 443
              protocol    = "tcp"
              sg_id       = [dependency.encryption_service.outputs.lb_security_group_id]
            }
          ] : [],
          local.has_vpc_network && local.has_wazuh ? [
            {
              description = "Wazuh syslog to VPC endpoint"
              from_port   = 1514
              to_port     = 1514
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            },
            {
              description = "Wazuh agent registration to VPC endpoint"
              from_port   = 1515
              to_port     = 1515
              protocol    = "tcp"
              sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
            }
          ] : []
        )
      }
    } : k => v if local.has_locker },
    { for k, v in {
      utils_lb_egress = {
        sg_id = dependency.utils_load_balancer.outputs.security_group_id
        rules = [
          {
            description = "All egress to EKS nodes"
            from_port   = 0
            to_port     = 65535
            protocol    = "-1"
            sg_id       = [dependency.eks.outputs.node_security_group_id]
          }
        ]
      }
    } : k => v if local.has_utils_lb },
    # lambda_common_egress = {
    #   sg_id = dependency.lambda_common.outputs.security_group_id
    #   rules = [
    #     {
    #       description     = "S3 VPC endpoint access"
    #       from_port       = 443
    #       to_port         = 443
    #       protocol        = "tcp"
    #       prefix_list_ids = [values.s3_prefix_list_id]
    #     },
    #     {
    #       description = "PostgreSQL to RDS database"
    #       from_port   = 5432
    #       to_port     = 5432
    #       protocol    = "tcp"
    #       sg_id       = [dependency.database.outputs.security_group_id]
    #     },
    #     {
    #       description = "All TCP to VPC endpoint security group"
    #       from_port   = 0
    #       to_port     = 65535
    #       protocol    = "tcp"
    #       sg_id       = [dependency.vpc-network.outputs.vpc_endpoint_security_group_id]
    #     },
    #     # {
    #     #   description = "All traffic to Lambda security group itself (step_1 to step_2 invocation)"
    #     #   from_port   = 0
    #     #   to_port     = 65535
    #     #   protocol    = "tcp"
    #     #   sg_id       = [dependency.lambda_common.outputs.security_group_id]
    #     # }
    #   ]
    # },
    # clickhouse_server_egress = {
    #   sg_id = dependency.clickhouse.outputs.server_security_group_id
    #   rules = [
    #     {
    #       description = "Kafka access to broker security group from ClickHouse"
    #       from_port   = 9092
    #       to_port     = 9092
    #       protocol    = "tcp"
    #       sg_id       = [dependency.kafka.outputs.broker_security_group_id]
    #     }
    #   ]
    # },
    { for k, v in {
      ratelimiter_lb_egress = {
        sg_id = dependency.ratelimiter.outputs.lb_security_group_id
        rules = [
          {
            description = "All egress from ratelimiter LB to EKS nodes"
            from_port   = 0
            to_port     = 65535
            protocol    = "-1"
            sg_id       = [dependency.eks.outputs.node_security_group_id]
          }
        ]
      }
    } : k => v if local.has_ratelimiter }
  )
}
