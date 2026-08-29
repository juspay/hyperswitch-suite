# AWS Load Balancer Controller values.
# $<eks.*>$ tokens resolve from the eks-01 terraform state via the tfstate plugin.
clusterName: $<eks.cluster_name>$
region: __AWS_REGION__
vpcId: __VPC_ID__

serviceAccount:
  create: true
  name: aws-load-balancer-controller
  # IRSA role for the controller. Create it once (see SELF_HOST.md):
  #   eksctl create iamserviceaccount --cluster $<eks.cluster_name>$ \
  #     --namespace kube-system --name aws-load-balancer-controller \
  #     --attach-policy-arn <AWSLoadBalancerControllerIAMPolicy arn> --approve
  # then put the created role ARN here:
  annotations: {}
  #  eks.amazonaws.com/role-arn: arn:aws:iam::__AWS_ACCOUNT_ID__:role/<alb-controller-irsa-role>

replicaCount: 1
