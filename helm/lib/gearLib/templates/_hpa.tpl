{{- define "app.hpa" -}}
  {{- range $componentName, $component := .Values.components }}
    {{- $enabled := $component.enabled | default true }}
    {{- if and $enabled $component.autoscaling $component.autoscaling.enabled }}
      {{- $deployKind := required "ERROR: `deployKind` must be set for component!" $component.deployKind }}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: {{ $deployKind }}
    name: {{ include "app.fullname" $ }}-{{ $componentName }}
  minReplicas: {{ $component.autoscaling.minReplicas | default 1 }}
  maxReplicas: {{ $component.autoscaling.maxReplicas | default 1 }}
  metrics:
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ $component.autoscaling.MemoryUtilization | default 80 }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $component.autoscaling.CPUUtilization | default 80 }}
    {{- end }}
  {{- end }}
{{- end }}
