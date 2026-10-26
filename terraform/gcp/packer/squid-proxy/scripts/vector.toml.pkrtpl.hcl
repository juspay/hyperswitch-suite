[sources.squid_logs]
  type = "file"
  include = [ "/var/log/squid/access.log" ]
  read_from = "end"

[api]
  enabled = true

[sinks.sink_loki]
type = "loki"
inputs = ["squid_logs"]
endpoint = "${loki_endpoint}"
encoding.codec = "json"
labels.job = "vector/squid-${environment}"
labels.service = "squid"
# Without this, Vector's startup healthcheck for this sink is fatal to the
# whole process if the endpoint is unreachable ("vector validate" exits
# 78/CONFIG, systemd never starts the service at all - confirmed via a
# live failure on 2026-08-20 while loki_endpoint pointed at the
# not-yet-reachable AWS Loki). Disabling it lets Vector start and tail the
# log locally regardless of sink reachability, retrying delivery in the
# background instead of blocking startup - the right default even once a
# real, usually-reachable endpoint is wired in (transient sink downtime
# elsewhere shouldn't stop local log collection).
healthcheck.enabled = false
