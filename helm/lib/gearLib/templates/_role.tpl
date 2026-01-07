{{- define "app.role" -}}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "app.fullname" $ }}-k8s-wait-for
  labels:
    {{- include "app.selectorLabels" $ | nindent 4 }}
    app.kubernetes.io/component: k8s-wait-for
    app.kubernetes.io/environment: {{ $.Values.environment }}
rules:
  - apiGroups: [""]
    resources: ["pods", "services"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs"]
    verbs: ["get", "list", "watch"]
{{- end }}
