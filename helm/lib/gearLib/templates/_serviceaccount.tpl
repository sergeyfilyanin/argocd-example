{{- define "app.serviceaccount" -}}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "app.fullname" $ }}-k8s-wait-for
  labels:
    {{- include "app.selectorLabels" $ | nindent 4 }}
    app.kubernetes.io/component: k8s-wait-for
    app.kubernetes.io/environment: {{ $.Values.environment }}
{{- end }}
