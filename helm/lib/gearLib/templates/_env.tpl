{{- define "app.env" -}}
  {{- range $componentName, $component := .Values.components }}
    {{- $enabled := $component.enabled | default true }}
    {{- if $enabled }}
      {{- $env := $component.env | default dict }}
      {{- if $env }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}-env
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
type: Opaque
data:
  {{- range $key, $value := $env }}
  {{ $key }}: {{ toString $value | b64enc | quote }}
  {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
