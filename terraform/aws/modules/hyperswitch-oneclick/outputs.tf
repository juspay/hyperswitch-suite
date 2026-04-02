output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT gateway"
  value       = aws_eip.nat.public_ip
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.main.status
}

output "hyperswitch_namespace" {
  description = "Kubernetes namespace for Hyperswitch"
  value       = kubernetes_namespace_v1.hyperswitch.metadata[0].name
}

output "hyperswitch_helm_release_status" {
  description = "Status of the Hyperswitch Helm release"
  value       = helm_release.hyperswitch.status
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${data.aws_region.current.name}"
}

output "port_forward_commands" {
  description = "Commands to port-forward Hyperswitch services"
  value = {
    server         = "kubectl port-forward service/hyperswitch-server 8080:80 -n ${kubernetes_namespace_v1.hyperswitch.metadata[0].name}"
    control_center = "kubectl port-forward service/hyperswitch-control-center 9000:80 -n ${kubernetes_namespace_v1.hyperswitch.metadata[0].name}"
    web            = "kubectl port-forward service/hyperswitch-web 9050:9050 -n ${kubernetes_namespace_v1.hyperswitch.metadata[0].name}"
    grafana        = "kubectl port-forward service/${var.hyperswitch_release_name}-grafana 3000:80 -n ${kubernetes_namespace_v1.hyperswitch.metadata[0].name}"
  }
}
