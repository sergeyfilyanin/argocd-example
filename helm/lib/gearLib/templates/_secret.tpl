{{- define "app.secret" -}}
  {{- range $componentName, $component := .Values.components }}
    {{- $enabled := $component.enabled | default true }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}-imagepullsecret
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: >-
    {{ $component.imagePullSecrets | default $.Values.global.imagePullSecrets }}

{{- if and $enabled $component.secrets }}
  {{- range $secretName, $secret := $component.secrets }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}-{{ $secretName }}
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
type: Opaque
data:
  {{ $secretName }}: |
    {{- $filePath := required "ERROR: `source` must be set for secret!" $secret.source | printf "%s" }}
    {{- $fileContent := $.Files.Get $filePath }}
    {{- if $fileContent }}
    {{- tpl $fileContent $ | b64enc | nindent 4 }}
    {{- else }}
    {{ fail (printf "ERROR: File %s not found!" $filePath) }}
    {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
