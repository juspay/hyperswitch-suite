MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex

# Fetch cluster details from AWS at runtime
CLUSTER_NAME="${cluster_name}"

# Fetch cluster endpoint and CA from AWS CLI
CLUSTER_ENDPOINT=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region $(ec2-metadata --availability-zone | cut -d' ' -f2 | sed 's/[a-z]$//') --query 'cluster.endpoint' --output text)
CLUSTER_CA_DATA=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region $(ec2-metadata --availability-zone | cut -d' ' -f2 | sed 's/[a-z]$//') --query 'cluster.certificateAuthority.data' --output text)

# Fetch cluster service CIDR from AWS CLI
CLUSTER_CIDR=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region $(ec2-metadata --availability-zone | cut -d' ' -f2 | sed 's/[a-z]$//') --query 'cluster.kubernetesNetworkConfig.serviceIpv4Cidr' --output text)

# Create NodeConfig for AL2023 nodeadm
cat > /etc/eks/bootstrap.yaml <<EOF
---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: $CLUSTER_NAME
    apiServerEndpoint: $CLUSTER_ENDPOINT
    certificateAuthority: $CLUSTER_CA_DATA
    cidr: $CLUSTER_CIDR
EOF

# Bootstrap node to cluster
/usr/bin/nodeadm init --config-source file:///etc/eks/bootstrap.yaml

--==MYBOUNDARY==--
