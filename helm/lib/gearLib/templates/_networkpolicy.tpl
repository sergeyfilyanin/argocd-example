{{/*
NetworkPolicy template for network isolation
Implements zero-trust networking principles
*/}}
{{- define "app.networkpolicy" -}}
  {{- range $componentName, $component := .Values.components }}
    {{- $enabled := $component.enabled | default true }}
    {{- if and $enabled (hasKey $component "networkPolicy") $component.networkPolicy.enabled }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "app.fullname" $ }}-{{ $componentName }}
  labels:
    {{- include "app.fullLabels" $ | nindent 4 }}
    app.kubernetes.io/component: {{ $componentName }}
    app.kubernetes.io/environment: {{ $.Values.environment }}
spec:
  podSelector:
    matchLabels:
      {{- include "app.selectorLabels" $ | nindent 6 }}
      app.kubernetes.io/component: {{ $componentName }}
      app.kubernetes.io/environment: {{ $.Values.environment }}
  policyTypes:
    - Ingress
    - Egress
  
  ingress:
    {{- if $component.service }}
    # Allow ingress traffic from nginx-ingress controller
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        {{- range $serviceName, $service := $component.service }}
        - protocol: {{ $service.protocol | default "TCP" }}
          port: {{ $service.port }}
        {{- end }}
    {{- end }}
    
    {{- if $component.networkPolicy.allowFromSameNamespace }}
    # Allow traffic from same namespace
    - from:
        - podSelector: {}
      {{- if $component.service }}
      ports:
        {{- range $serviceName, $service := $component.service }}
        - protocol: {{ $service.protocol | default "TCP" }}
          port: {{ $service.port }}
        {{- end }}
      {{- end }}
    {{- end }}
    
    {{- if $component.networkPolicy.additionalIngress }}
    {{- toYaml $component.networkPolicy.additionalIngress | nindent 4 }}
    {{- end }}
  
  egress:
    # Allow DNS resolution
    - to:
        - namespaceSelector: {}
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    
    {{- if $component.networkPolicy.allowExternalHTTPS }}
    # Allow outbound HTTPS (for external APIs)
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 10.0.0.0/8
              - 172.16.0.0/12
              - 192.168.0.0/16
      ports:
        - protocol: TCP
          port: 443
    {{- end }}
    
    {{- if $component.networkPolicy.allowToSameNamespace }}
    # Allow traffic to same namespace
    - to:
        - podSelector: {}
    {{- end }}
    
    {{- if $component.networkPolicy.additionalEgress }}
    {{- toYaml $component.networkPolicy.additionalEgress | nindent 4 }}
    {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

