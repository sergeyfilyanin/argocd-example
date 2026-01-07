{{- define "app.pvc" -}}
  {{- range $componentName, $component := .Values.components }}
    {{- $enabled := $component.enabled | default true }}
    {{- if and $enabled $component.persistentVolumes }}
      {{- range $pvName, $pv := $component.persistentVolumes }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}-{{ $pvName }}
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
spec:
  accessModes:
    - {{ $pv.accessMode | default "ReadWriteOnce" }}
  resources:
    requests:
      storage: {{ required "ERROR: `size` must be set for persistentVolume!" $pv.size }}
  storageClassName: {{ required "ERROR: `storageClass` must be set for persistentVolume!" $pv.storageClass }}
  volumeMode: {{ $pv.volumeMode | default "Filesystem" }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
