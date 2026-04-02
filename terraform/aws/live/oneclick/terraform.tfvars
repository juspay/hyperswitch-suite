aws_region   = "us-east-1"
project_name = "hyperswitch"
environment  = "dev"

vpc_cidr = "10.0.0.0/16"

cluster_version = "1.35"

node_group = {
  capacity_type              = "ON_DEMAND"
  instance_types             = ["t3.medium"]
  desired_size               = 4
  min_size                   = 2
  max_size                   = 10
  max_unavailable_percentage = 33
  labels                     = {}
}

tags = {
  Team = "platform"
}
