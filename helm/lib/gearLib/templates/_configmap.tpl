{{- define "app.configmap" -}}
  {{- range $componentName, $component := .Values.components }}
    {{- $enabled := $component.enabled | default true }}
    {{- if and $enabled $component.configMaps }}
      {{- range $configMapName, $configMap := $component.configMaps }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}-{{ $configMapName }}
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
data:
  {{ $configMapName }}: |
    {{- $filePath := required "ERROR: `source` must be set for configMap!" $configMap.source | printf "%s" }}
    {{- $fileContent := $.Files.Get $filePath }}
    {{- if $fileContent }}
    {{- tpl $fileContent $ | nindent 4 }}
    {{- else }}
    {{ fail (printf "ERROR: File %s not found!" $filePath) }}
    {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
