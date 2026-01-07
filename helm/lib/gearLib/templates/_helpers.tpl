{{- define "app.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "app.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "app.fullLabels" -}}
{{ include "app.selectorLabels" . }}
{{- end }}

{{- define "app.dependencyCheckerImage" -}}
ghcr.io/groundnuty/k8s-wait-for:no-root-v2.0
{{- end }}
