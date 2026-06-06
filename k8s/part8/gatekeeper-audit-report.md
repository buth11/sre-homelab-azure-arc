# Gatekeeper Audit Report
Date: 2026-06-06
Cluster: K3s-Homelab (Azure Arc)
Mode: dryrun (Azure Policy managed)

## Summary

| Policy | Violations | Description |
|--------|-----------|-------------|
| k8sazurev3containerlimits | 34 | Containers without resource limits |
| k8sazurev2containerallowedimages | 30 | Images outside allowed registry |
| k8sazurev2blockautomounttoken | 21 | Automount service account token enabled |
| k8sazurev3allowedusersgroups | 22 | Non-compliant user/group settings |
| k8sazurev3hostnetworkingports | 15 | Host networking/ports violations |
| k8sazurev3readonlyrootfilesystem | 9 | Writable root filesystem |
| k8sazurev4hostfilesystem | 9 | Host filesystem access |
| k8sazurev3noprivilegeescalation | 3 | Privilege escalation allowed |
| k8sazurev1blockdefault | 6 | Resources in default namespace |
| k8sazurev2blockhostnamespace | 6 | Host namespace usage |

## Key Findings

### containerlimits — 34 violations (namespace: monitoring)
Containers without resource limits detected:
- prometheus (prometheus-monitoring-kube-prometheus-prometheus-0)
- init-config-reloader, config-reloader (same pod)
- node-exporter (3x — one per node)
- kube-state-metrics
- kube-prometheus-stack operator
- grafana

Root cause: kube-prometheus-stack Helm chart does not set resource limits
by default. Fix: add limits in Helm values.yaml.

### containerallowedimages — 30 violations
Images from non-whitelisted registries (docker.io, ghcr.io).
Azure Policy allows only mcr.microsoft.com by default.
Fix: update policy parameters to include docker.io and ghcr.io.

## Architecture Note
Gatekeeper is managed by Azure Arc + Azure Policy addon.
Custom ConstraintTemplates cannot be created directly — must go through
Azure Policy definitions. This is by design for centralized governance.

## Enforcement Action
All policies currently in dryrun mode — violations are audited but NOT blocked.
To enforce: change enforcement action to deny in Azure Policy assignment.
