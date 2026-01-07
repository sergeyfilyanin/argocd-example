{{- define "app.servicemonitor" -}}
  {{- range $componentName, $component := .Values.components }}
    {{- $enabled := $component.enabled | default true }}
    {{- if and $enabled $component.service }}
      {{- range $serviceName, $service := $component.service }}
        {{- if and $service.monitoring $service.monitoring.enabled }}
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}-{{ $serviceName }}
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
spec:
  endpoints:
    - port: {{ $serviceName }}
      scheme: {{ $service.monitoring.scheme | default "http" }}
      path: {{ $service.monitoring.path | default "/metrics" }}
      honorLabels: {{ $service.monitoring.honorLabels | default true }}
      interval: {{ $service.monitoring.interval | default "5s" }}
      scrapeTimeout: {{ $service.monitoring.scrapeTimeout | default "5s" }}
  selector:
    matchLabels:
      {{- include "app.selectorLabels" $ | nindent 6 }}
      app.kubernetes.io/component: {{ $componentName }}
      app.kubernetes.io/environment: {{ $.Values.environment }}
  targetLabels:
    - env
    - role
    - appkey
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
