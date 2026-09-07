# Ships the Dante access log to Loki. Mirrors the squid-proxy image's
# vector.toml; healthcheck is disabled so Vector still starts and tails the
# file even when the Loki endpoint is unreachable.

[sources.socks5_logs]
type    = "file"
include = ["/var/log/danted.log"]

[transforms.socks5_parsed]
type   = "remap"
inputs = ["socks5_logs"]
source = '''
.environment = "${environment}"
.component = "socks5-proxy"
'''

[sinks.loki]
type     = "loki"
inputs   = ["socks5_parsed"]
endpoint = "${loki_endpoint}"
encoding.codec = "text"

[sinks.loki.labels]
job         = "socks5-proxy"
environment = "${environment}"

[sinks.loki.healthcheck]
enabled = false
