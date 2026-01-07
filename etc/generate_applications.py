#!/usr/bin/env python3
"""
ArgoCD Application Generator

Generates ArgoCD Application manifests from a centralized applications.yaml config.
Supports multi-environment deployments with Helm values overlay strategy.

Usage:
    python generate_applications.py

Configuration:
    - applications.yaml: Defines which apps are enabled per environment
    - environments/*.yaml: Environment-specific values
    - helm/global-values.yaml: Shared values across all applications
"""

from ruyaml import YAML
from pathlib import Path
from typing import Any

# Configuration - Replace with your repository URL
REPO_URL = "git@github.com:example-org/argocd.git"
APPLICATIONS_FILE = Path("applications.yaml")
APPLICATIONS_DIR = Path("apps")
CHARTS_DIR = "charts"
ENVIRONMENTS = ["dev", "stg", "prod"]
NAMESPACE_PREFIX = "{}-{}"

yaml = YAML()
yaml.default_flow_style = False
yaml.indent(mapping=2, sequence=4, offset=2)


def load_yaml(file_path: Path) -> dict[str, Any]:
    """Load and parse a YAML file."""
    with open(file_path) as f:
        return yaml.load(f)


def write_yaml(data: dict[str, Any], path: Path) -> None:
    """Write data to a YAML file."""
    with open(path, "w") as f:
        yaml.dump(data, f)


def get_chart_sources(app_name: str) -> list[str]:
    """Extract source URLs from Chart.yaml for GitHub links in ArgoCD UI."""
    chart_path = Path(f"helm/{CHARTS_DIR}/{app_name}/Chart.yaml")
    if chart_path.exists():
        chart = load_yaml(chart_path)
        return chart.get("sources", [])
    return []


def generate_application_manifest(
    app_name: str, 
    env: str, 
    app_sources: list[str]
) -> dict[str, Any]:
    """Generate a single ArgoCD Application manifest."""
    full_name = f"{env}-{app_name}"
    
    # Build info links for ArgoCD UI
    info = []
    if app_sources and "github.com" in app_sources[0]:
        app_source_url = app_sources[0].rstrip("/")
        info.append({"name": "GitHub Source", "value": app_source_url})
        info.append({"name": "GitHub Actions", "value": f"{app_source_url}/actions"})

    return {
        "apiVersion": "argoproj.io/v1alpha1",
        "kind": "Application",
        "metadata": {
            "name": full_name,
            "namespace": "argocd",
            "finalizers": ["resources-finalizer.argocd.argoproj.io"]
        },
        "spec": {
            "project": "default",
            "source": {
                "repoURL": REPO_URL,
                "targetRevision": "HEAD",
                "path": f"helm/{CHARTS_DIR}/{app_name}",
                "helm": {
                    "valueFiles": [
                        f"../../../helm/{CHARTS_DIR}/{app_name}/{env}-values.yaml",
                        f"../../../environments/{env}.yaml",
                        "../../../helm/global-values.yaml"
                    ]
                }
            },
            "destination": {
                "server": "https://kubernetes.default.svc",
                "namespace": NAMESPACE_PREFIX.format(env, app_name)
            },
            "syncPolicy": {
                "automated": {
                    "prune": True,
                    "selfHeal": True
                },
                "syncOptions": [
                    "CreateNamespace=true",
                    "PruneLast=true",
                    "ApplyOutOfSyncOnly=true",
                    "ServerSideApply=true",
                    "PrunePropagationPolicy=foreground"
                ]
            },
            **({"info": info} if info else {})
        }
    }


def generate_yaml() -> None:
    """Main function to generate all ArgoCD Application manifests."""
    APPLICATIONS_DIR.mkdir(exist_ok=True)
    applications = load_yaml(APPLICATIONS_FILE)

    needed_apps: list[str] = []

    for app, envs in applications.items():
        for env in ENVIRONMENTS:
            if envs.get(env):
                app_name = f"{env}-{app}"
                app_path = APPLICATIONS_DIR / f"{app_name}.yaml"
                needed_apps.append(app_path.name)

                app_sources = get_chart_sources(app)
                app_yaml = generate_application_manifest(app, env, app_sources)

                write_yaml(app_yaml, app_path)
                print(f"✅ Generated: {app_path}")

    # Clean up orphaned application manifests
    for existing_app in APPLICATIONS_DIR.glob("*.yaml"):
        if existing_app.name not in needed_apps:
            existing_app.unlink()
            print(f"❌ Removed: {existing_app}")


if __name__ == "__main__":
    generate_yaml()
