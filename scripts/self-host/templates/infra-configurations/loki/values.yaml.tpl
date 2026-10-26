# Loki values — single-binary mode with filesystem/PVC storage.
# Upgrade path: switch to S3 object storage + an IRSA role once log volume
# grows (see Loki docs: storage_config.aws).
deploymentMode: SingleBinary

loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  storage:
    type: filesystem
  schemaConfig:
    configs:
      - from: "2024-01-01"
        store: tsdb
        object_store: filesystem
        schema: v13
        index:
          prefix: index_
          period: 24h

singleBinary:
  replicas: 1
  persistence:
    enabled: true
    size: 50Gi
    storageClass: ebs-gp3

# Not needed in single-binary mode
read:
  replicas: 0
write:
  replicas: 0
backend:
  replicas: 0

gateway:
  enabled: true

chunksCache:
  enabled: false
resultsCache:
  enabled: false
lokiCanary:
  enabled: false
test:
  enabled: false
