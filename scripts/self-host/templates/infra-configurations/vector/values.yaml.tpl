# Vector values — agent (daemonset) shipping pod logs to Loki.
role: Agent

customConfig:
  data_dir: /vector-data-dir
  sources:
    kubernetes_logs:
      type: kubernetes_logs
  sinks:
    loki:
      type: loki
      inputs: [kubernetes_logs]
      endpoint: http://loki-gateway.loki.svc.cluster.local
      encoding:
        codec: json
      labels:
        namespace: "{{ kubernetes.pod_namespace }}"
        pod: "{{ kubernetes.pod_name }}"
        container: "{{ kubernetes.container_name }}"
