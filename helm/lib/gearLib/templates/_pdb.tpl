{{/*
PodDisruptionBudget template for high availability
Ensures minimum availability during voluntary disruptions (upgrades, drains)
*/}}
{{- define "app.pdb" -}}
  {{- range $componentName, $component := .Values.components }}
    {{- $enabled := $component.enabled | default true }}
    {{- if and $enabled (hasKey $component "pdb") $component.pdb.enabled }}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
spec:
  {{- if $component.pdb.minAvailable }}
  minAvailable: {{ $component.pdb.minAvailable }}
  {{- else if $component.pdb.maxUnavailable }}
  maxUnavailable: {{ $component.pdb.maxUnavailable }}
  {{- else }}
  # Default: ensure at least 1 pod is always available
  minAvailable: 1
  {{- end }}
  selector:
    matchLabels:
      {{- include "app.selectorLabels" $ | nindent 6 }}
      app.kubernetes.io/component: {{ $componentName }}
      app.kubernetes.io/environment: {{ $.Values.environment }}
  {{- if $component.pdb.unhealthyPodEvictionPolicy }}
  unhealthyPodEvictionPolicy: {{ $component.pdb.unhealthyPodEvictionPolicy }}
  {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

