{{- define "app.rolebinding" -}}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "app.fullname" $ }}-k8s-wait-for
  labels:
    {{- include "app.selectorLabels" $ | nindent 4 }}
    app.kubernetes.io/component: k8s-wait-for
    app.kubernetes.io/environment: {{ $.Values.environment }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "app.fullname" $ }}-k8s-wait-for
subjects:
  - kind: ServiceAccount
    name: {{ include "app.fullname" $ }}-k8s-wait-for
{{- end }}
