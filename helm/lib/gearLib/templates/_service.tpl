{{- define "app.service" -}}
  {{- range $componentName, $component := .Values.components }}
    {{- $enabled := $component.enabled | default true }}
    {{- if and $enabled $component.service }}
      {{- range $serviceName, $service := $component.service }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}-{{ $serviceName }}
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
spec:
  type: {{ $service.type | default "ClusterIP" }}
  ports:
    - name: {{ $serviceName }}
      port: 80
      targetPort: {{ required "ERROR: `port` must be set for service!" $service.port }}
      protocol: {{ $service.protocol | default "TCP" }}
  selector:
    {{- include "app.selectorLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
