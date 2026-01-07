# ArgoCD GitOps Repository

**⚠️ NEVER commit real secrets to this repository!**


## 📁 Repository Structure

```
.
├── applications.yaml          # Central app enablement config (dev/stg/prod)
├── apps/                      # Generated ArgoCD Application manifests
├── environments/              # Environment-specific values
│   ├── dev.yaml
│   ├── stg.yaml
│   └── prod.yaml
├── etc/                       # ArgoCD configuration & utilities
│   ├── app-of-apps.yaml       # Root Application (bootstrap)
│   ├── cm.yml                 # ArgoCD ConfigMap
│   ├── rbac.yml               # ArgoCD RBAC policies
│   └── generate_applications.py
├── helm/
│   ├── global-values.yaml     # Shared values across all charts
│   ├── charts/                # Application Helm charts
│   │   ├── <app-name>/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml    # Default values
│   │   │   ├── dev-values.yaml
│   │   │   ├── stg-values.yaml
│   │   │   ├── prod-values.yaml
│   │   │   └── templates/
│   │   │       └── main.yaml  # Includes library templates
│   └── lib/
│       └── gearLib/           # Shared Helm library chart
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── _deployment.tpl
│               ├── _statefulset.tpl
│               ├── _service.tpl
│               ├── _ingress.tpl
│               ├── _hpa.tpl
│               ├── _pdb.tpl
│               ├── _networkpolicy.tpl
│               └── ...
└── .github/
    └── workflows/
        └── validate.yaml      # CI validation workflow
```

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (1.25+)
- ArgoCD installed ([installation guide](https://argo-cd.readthedocs.io/en/stable/getting_started/))
- Helm 3.x
- Python 3.10+ (for application generator)

### Bootstrap ArgoCD

```bash
# Apply the App of Apps pattern
kubectl apply -f etc/app-of-apps.yaml -n argocd

# ArgoCD will automatically sync all enabled applications
```

### Enable/Disable Applications

Edit `applications.yaml` to control which apps are deployed:

```yaml
vara-landing:
  dev: false    # Disabled in dev
  stg: true     # Enabled in staging
  prod: true    # Enabled in production
```

Then regenerate Application manifests:

```bash
python etc/generate_applications.py
```

## 🔧 Helm Library (gearLib)

The shared library provides consistent, production-ready templates:

### Features

| Template | Description |
|----------|-------------|
| `_deployment.tpl` | Deployment with anti-affinity, probes, security context |
| `_statefulset.tpl` | StatefulSet for stateful workloads |
| `_service.tpl` | ClusterIP services |
| `_ingress.tpl` | Ingress with annotations support |
| `_hpa.tpl` | HorizontalPodAutoscaler (CPU/Memory) |
| `_pdb.tpl` | PodDisruptionBudget for HA |
| `_networkpolicy.tpl` | Network isolation policies |
| `_servicemonitor.tpl` | Prometheus ServiceMonitor |
| `_secret.tpl` | Secrets and imagePullSecrets |
| `_configmap.tpl` | ConfigMaps from files |

```

## 🔐 Secrets Management

**⚠️ NEVER commit real secrets to this repository!**

### Recommended Approaches

1. **External Secrets Operator** (Recommended)
   ```yaml
   # ExternalSecret syncs from AWS Secrets Manager, Vault, etc.
   apiVersion: external-secrets.io/v1beta1
   kind: ExternalSecret
   spec:
     secretStoreRef:
       name: aws-secrets-manager
     target:
       name: app-secrets
   ```

2. **Sealed Secrets**
   ```bash
   kubeseal --format yaml < secret.yaml > sealed-secret.yaml
   ```

3. **SOPS + ArgoCD**
   ```bash
   sops --encrypt values-secrets.yaml > values-secrets.enc.yaml
   ```

4. **ArgoCD Vault Plugin**
   ```yaml
   # Inline secret references
   password: <path:secret/data/app#password>
   ```

## 🏷️ Values Hierarchy

ArgoCD merges values in this order (later overrides earlier):

```
1. helm/charts/<app>/values.yaml        # Defaults
2. helm/charts/<app>/<env>-values.yaml  # Environment overrides
3. environments/<env>.yaml               # Global env config
4. helm/global-values.yaml               # Shared globals
```

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
