{{- define "app.deployment" -}}
  {{- range $componentName, $component := .Values.components }}
    {{- $enabled := $component.enabled | default true }}
    {{- if and $enabled (eq $component.deployKind "Deployment") }}
      {{- $image := required (printf "ERROR: `image` must be set for component '%s'!" $componentName) $component.image }}
      {{- $tag := required (printf "ERROR: `tag` must be set for component '%s'!" $componentName) $component.tag }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
spec:
  paused: {{ $component.paused | default false }}
  progressDeadlineSeconds: {{ $component.progressDeadlineSeconds | default 900 }}
  {{- if not (and (hasKey $component "autoscaling") ($component.autoscaling.enabled | default false)) }}
  replicas: {{ $component.replicas | default 1 }}
  {{- end }}
  revisionHistoryLimit: {{ $component.revisionHistoryLimit | default 1 }}
  selector:
    matchLabels:
      {{- include "app.selectorLabels" $ | nindent 6 }}
      app.kubernetes.io/component: {{ $componentName }}
      app.kubernetes.io/environment: {{ $.Values.environment }}
  template:
    metadata:
      annotations:
        reloader.stakater.com/auto: "true"
        {{- if $component.deployAnnotations }}
        {{- toYaml $component.deployAnnotations | nindent 8 }}
        {{- end }}
      labels:
        {{- include "app.selectorLabels" $ | nindent 8 }}
        app.kubernetes.io/component: {{ $componentName }}
        app.kubernetes.io/environment: {{ $.Values.environment }}
    spec:
      serviceAccount: {{ include "app.fullname" $ }}-k8s-wait-for
      serviceAccountName: {{ include "app.fullname" $ }}-k8s-wait-for
      automountServiceAccountToken: {{ $component.automountServiceAccountToken | default true }}
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app.kubernetes.io/component: {{ $componentName }}
                    app.kubernetes.io/environment: {{ $.Values.environment }}
                topologyKey: "node.kubernetes.io/hostname"
              weight: 100
      volumes:
        {{- if $component.configMaps }}
          {{- range $configMapName, $configMap := $component.configMaps }}
        - name: {{ $configMapName }}
          configMap:
            name: {{ include "app.fullname" $ }}-{{ $componentName }}-{{ $configMapName }}
          {{- end }}
        {{- end }}
        {{- if $component.secrets }}
          {{- range $secretName, $secret := $component.secrets }}
        - name: {{ $secretName }}
          secret:
            secretName: {{ include "app.fullname" $ }}-{{ $componentName }}-{{ $secretName }}
          {{- end }}
        {{- end }}
        {{- if $component.persistentVolumes }}
          {{- range $pvName, $pv := $component.persistentVolumes }}
        - name: {{ $pvName }}
          persistentVolumeClaim:
            claimName: {{ include "app.fullname" $ }}-{{ $componentName }}-{{ $pvName }}
            readOnly: {{ $pv.readOnly | default false }}
          {{- end }}
        {{- end }}
      {{- if $component.dependencies }}
      initContainers:
        {{- range $dependencyName, $dependency := $component.dependencies }}
        - name: {{ include "app.fullname" $ }}-{{ $componentName }}-wait-for-{{ $dependencyName }}
          image: {{ include "app.dependencyCheckerImage" $ }}
          imagePullPolicy: IfNotPresent
          args:
            - {{ $dependency.type }}
            - '-lapp.kubernetes.io/component={{ $dependencyName }}'
          env:
            - name: DEBUG
              value: '0'
            - name: KUBECTL_ARGS
              value: '-n {{ $.Release.Namespace }}'
          securityContext:
            capabilities:
              drop:
                - ALL
            runAsUser: 1100
            runAsGroup: 1100
            runAsNonRoot: true
            readOnlyRootFilesystem: false
            allowPrivilegeEscalation: false
            seccompProfile:
              type: RuntimeDefault
        {{- end }}
      {{- end }}
      containers:
      - name: {{ $componentName }}
        image: "{{ $image }}:{{ $tag }}"
        imagePullPolicy: {{ $component.imagePullPolicy | default "IfNotPresent" }}
        {{- if $component.workingDir }}
        workingDir: {{ $component.workingDir }}
        {{- end }}
        {{- if $component.command }}
        command:
          {{- toYaml $component.command | nindent 10 }}
        {{- end }}
        {{- if $component.args }}
        args:
          {{- toYaml $component.args | nindent 10 }}
        {{- end }}
        {{- if $component.service }}
        ports:
          {{- range $serviceName, $service := $component.service }}
          - name: {{ $serviceName }}
            containerPort: {{ required "ERROR: `port` must be set for service!" $service.port }}
            protocol: {{ $service.protocol | default "TCP" }}
          {{- end }}
        {{- end }}
        env:
          - name: POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
        envFrom:
          {{- if $component.env }}
          - secretRef:
              name: {{ include "app.fullname" $ }}-{{ $componentName }}-env
          {{- end }}
        volumeMounts:
          {{- if $component.configMaps }}
            {{- range $configMapName, $configMap := $component.configMaps }}
          - name: {{ $configMapName }}
            mountPath: {{ required "ERROR: `mountPath` must be set for configMap!" $configMap.mountPath }}
            subPath: {{ $configMapName }}
            readOnly: {{ $configMap.readOnly | default true }}
            {{- end }}
          {{- end }}
          {{- if $component.secrets }}
            {{- range $secretName, $secret := $component.secrets }}
          - name: {{ $secretName }}
            mountPath: {{ required "ERROR: `mountPath` must be set for secrets!" $secret.mountPath }}
            subPath: {{ $secretName }}
            readOnly: {{ $secret.readOnly | default true }}
            {{- end }}
          {{- end }}
          {{- if $component.persistentVolumes }}
            {{- range $pvName, $pv := $component.persistentVolumes }}
          - name: {{ $pvName }}
            mountPath: {{ required "ERROR: `mountPath` must be set for persistentVolumes!" $pv.mountPath }}
            subPath: {{ $pvName }}
            readOnly: {{ $pv.readOnly | default false }}
            {{- end }}
          {{- end }}
        {{- if $component.resources }}
        resources:
          {{- toYaml $component.resources | nindent 10 }}
        {{- end }}
        {{- if $component.startupProbe }}
        startupProbe:
          {{- toYaml $component.startupProbe | nindent 10 }}
        {{- else if $component.service }}
        startupProbe:
          tcpSocket:
            port: {{ required "ERROR: `port` must be set for service!" (index $component.service "http").port }}
          initialDelaySeconds: 10
          failureThreshold: 12
          periodSeconds: 5
          timeoutSeconds: 3
        {{- end }}
        {{- if $component.readinessProbe }}
        readinessProbe:
          {{- toYaml $component.readinessProbe | nindent 10 }}
        {{- else if $component.service }}
        readinessProbe:
          tcpSocket:
            port: {{ required "ERROR: `port` must be set for service!" (index $component.service "http").port }}
          initialDelaySeconds: 10
          failureThreshold: 3
          periodSeconds: 5
          timeoutSeconds: 3
        {{- end }}
        {{- if $component.livenessProbe }}
        livenessProbe:
          {{- toYaml $component.livenessProbe | nindent 10 }}
        {{- else if $component.service }}
        livenessProbe:
          tcpSocket:
            port: {{ required "ERROR: `port` must be set for service!" (index $component.service "http").port }}
          failureThreshold: 6
          periodSeconds: 10
          timeoutSeconds: 3
        {{- end }}
        securityContext:
          capabilities:
            drop:
              - ALL
          runAsUser: {{ ( $component.securityContext | default dict ).runAsUser | default 1001 }}
          runAsGroup: {{ ( $component.securityContext | default dict ).runAsGroup | default 1001 }}
          runAsNonRoot: {{ ( $component.securityContext | default dict ).runAsNonRoot | default true }}
          readOnlyRootFilesystem: {{ ( $component.securityContext | default dict ).readOnlyRootFilesystem | default false }}
          allowPrivilegeEscalation: {{ ( $component.securityContext | default dict ).allowPrivilegeEscalation | default false }}
          seccompProfile:
            type: {{ ( $component.securityContext | default dict ).seccompProfileType | default "RuntimeDefault" }}
      imagePullSecrets:
        - name: {{ include "app.fullname" $ }}-{{ $componentName }}-imagepullsecret
      nodeSelector:
        node.kubernetes.io/nodegroup: {{ $.Values.environment }}
      restartPolicy: {{ $component.restartPolicy | default "Always" }}
      terminationGracePeriodSeconds: {{ $component.terminationGracePeriodSeconds | default 60 }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0
    {{- end }}
  {{- end }}
{{- end }}
