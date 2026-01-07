{{- define "app.ingress" -}}
  {{- range $componentName, $component := .Values.components }}
    {{- $enabled := $component.enabled | default true }}
    {{- if and $enabled $component.ingress }}
      {{- range $ingressName, $ingress := $component.ingress }}
        {{- $host := required "ERROR: `host` must be set for ingress!" $ingress.host }}
        {{- $annotations := $ingress.annotations | default dict }}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}-{{ $ingressName }}
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
  annotations:
    {{- toYaml $annotations | nindent 4 }}
spec:
  rules:
    - host: {{ $host }}
      http:
        paths:
          {{- range $path := $ingress.paths }}
          - path: {{ required "ERROR: `path` must be set for ingress!" $path.path }}
            pathType: {{ $path.pathType | default "Prefix" }}
            backend:
              service:
                name: {{ include "app.fullname" $ }}-{{ $componentName }}-{{ $path.port }}
                port:
                  name: {{ required "ERROR: `port` must be set for ingress!" $path.port }}
          {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
