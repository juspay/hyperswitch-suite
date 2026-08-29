# Superposition values — shares the Aurora cluster provisioned by the
# database unit ($tfstate.rds).
db:
  host: $<rds.endpoint>$
  port: 5432
  name: superposition
  user: hyperswitch
  # Password from a pre-created secret (see SELF_HOST.md, secrets step)
  existingSecret: hyperswitch-db-credentials
  existingSecretKey: password

replicas: 1
