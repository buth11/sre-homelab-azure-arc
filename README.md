# SRE Homelab: Azure Arc Hybrid Cloud Lab

> **A Proof-of-Value project demonstrating hybrid cloud orchestration, Kubernetes,
> Infrastructure-as-Code, observability, FinOps, Policy as Code, CI/CD pipeline
> automation, advanced Kubernetes operations, GitOps, security scanning, automated
> TLS, event-driven autoscaling, Helm, OPA/Gatekeeper, Chaos Engineering, and
> Service Mesh using K3s and Microsoft Azure Arc.**

![Part](https://img.shields.io/badge/Progress-Part%2010%20Complete-0078d4)
![Cost](https://img.shields.io/badge/Azure%20Cost-0.00%20USD-107c10)
![SLO](https://img.shields.io/badge/SLO-100%25%20Availability-107c10)
![GitOps](https://img.shields.io/badge/GitOps-FluxCD%202.8.8-5468ff)
![Security](https://img.shields.io/badge/Security-Trivy%20%2B%20Defender%20%2B%20Linkerd-red)
![TLS](https://img.shields.io/badge/TLS-cert--manager%20v1.20.2-brightgreen)
![Chaos](https://img.shields.io/badge/Chaos-Chaos%20Mesh-orange)

---

## Overview

This project documents the design, deployment, and operation of a production-grade
**hybrid Edge-to-Cloud environment** built on commodity hardware. A three-node K3s
Kubernetes cluster running on-premises (Olsztyn, Poland) is connected to Microsoft
Azure through Azure Arc, enabling centralized governance, monitoring, policy enforcement,
CI/CD automation, GitOps, and automated TLS management from a single cloud control plane.

Built to demonstrate hands-on SRE competencies directly relevant to managing
enterprise SaaS infrastructure at scale.

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Hypervisor | KVM on Fedora 43 | Host virtualization |
| OS | Ubuntu Server 24.04 LTS | All cluster nodes |
| Kubernetes | K3s v1.35.4+k3s1 | Lightweight K8s distribution |
| Ingress | Traefik (built-in K3s) | HTTPS routing + TLS termination |
| TLS Management | cert-manager v1.20.2 | Automatic certificate issuance and renewal |
| Autoscaling (CPU) | HPA (autoscaling/v2) | CPU-based pod autoscaling 2-8 replicas |
| Autoscaling (events) | KEDA | Event-driven autoscaling via Prometheus |
| Package Management | Helm v3 + custom chart | Kubernetes application packaging |
| Policy Enforcement | OPA/Gatekeeper (Azure Arc) | Admission control, audit 34+ violations |
| Chaos Engineering | Chaos Mesh | PodChaos, self-healing verification |
| Service Mesh | Linkerd edge-26.6.1 | mTLS, sidecar proxy injection |
| Network Security | NetworkPolicy | Pod-level firewall (least privilege) |
| Access Control | RBAC + ServiceAccount | Application-level least privilege |
| GitOps | FluxCD 2.8.8 | Git-driven cluster reconciliation |
| Security Scanning | Trivy 0.70.0 | Container image CVE scanning |
| Runtime Security | Defender for Cloud (Containers) | Microsoft threat detection |
| Cloud Bridge | Azure Arc | Hybrid control plane |
| Cloud Monitoring | Azure Monitor + Container Insights | Telemetry, KQL analytics, alerting |
| Local Monitoring | Prometheus + Grafana (Helm) | Open-source observability stack |
| IaC | Terraform + Remote State | Infrastructure as Code |
| CI/CD | Azure DevOps Pipelines | Automated plan + approval gate + apply |
| Source Control | GitHub (SSH auth) | Version control, pipeline trigger |

---

## Key SRE Practices Demonstrated

### Part 1 — Hybrid Cloud Foundation
- 3-node K3s cluster connected to Azure Arc
- Azure Monitor + Container Insights + KQL (SLO 100%, 184/184 samples)
- Prometheus + Grafana local monitoring stack
- Azure Policy — 2 policies Compliant
- FinOps — $0.00 cost across all parts

### Part 2 — IaC, CI/CD, and Automation
- Terraform remote state (Azure Blob, locking, versioning)
- Azure DevOps 2-stage pipeline: plan → approval gate → apply (4m 24s)

### Part 3 — Advanced Kubernetes Operations
- Ingress + TLS, HPA (2→8 replicas, 860% CPU), NetworkPolicy, RBAC

### Part 4 — GitOps and Security
- FluxCD: git push → automatic deploy (no kubectl apply)
- Trivy: 1 CRITICAL + 12 HIGH CVEs in traefik/whoami:latest
- Defender for Cloud: DaemonSet on all 3 nodes

### Part 5 — Automated TLS
- cert-manager: certificate issued in 22s from Ingress annotation
- Auto-renewal: renewBefore configured, zero manual intervention

### Part 6 — Event-Driven Autoscaling
- KEDA: Prometheus trigger, scale 1→8 replicas, cooldown 30s
- Scale to zero capability (vs HPA minimum 1)

### Part 7 — Helm Chart
- Custom chart: aras-demo-app v0.1.0
- Templates: Deployment, Service, Ingress, RBAC, NetworkPolicy
- Demonstrated: install, upgrade (--set), rollback, history

### Part 8 — OPA/Gatekeeper Policy Audit
- 16 ConstraintTemplates deployed by Azure Arc
- 34 containerlimits violations (Prometheus stack without limits)
- 30 containerallowedimages violations documented

### Part 9 — Chaos Engineering
- Chaos Mesh PodChaos: pod-kill every 30s
- Self-healing verified: pods replaced in <5 seconds
- Zero downtime during chaos experiments

### Part 10 — Service Mesh
- Linkerd edge-26.6.1 installed with viz extension
- Namespace default meshed: MESHED 2/2
- mTLS automatically enabled between all meshed pods

---

## Lab Results

| Metric | P1 | P2 | P3 | P4 | P5 | P6 | P7 | P8 | P9 | P10 |
|--------|----|----|----|----|----|----|----|----|----|----|
| Cost | $0 | $0 | $0 | $0 | $0 | $0 | $0 | $0 | $0 | $0 |
| SLO | 100% | — | — | — | — | — | — | — | — | — |
| CI/CD | — | 4m24s | — | — | — | — | — | — | — | — |
| TLS | — | — | Manual | — | Auto | — | — | — | — | — |
| Autoscaling | — | — | HPA 2-8 | — | — | KEDA 1-8 | — | — | — | — |
| GitOps | — | — | — | FluxCD | — | — | — | — | — | — |
| CVE scan | — | — | — | 1 CRIT | — | — | — | — | — | — |
| Helm | — | — | — | — | — | — | v0.1.0 | — | — | — |
| Policy | — | — | — | — | — | — | — | 34 viol. | — | — |
| Chaos | — | — | — | — | — | — | — | — | pod-kill | — |
| mTLS | — | — | — | — | — | — | — | — | — | 2/2 |
| Issues | 6 | 8 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 |

---

## Repository Structure

```
sre-homelab-azure-arc/
├── README.md
├── terraform/
├── k8s/
│   ├── deployment-whoami.yaml
│   ├── service-loadbalancer.yaml
│   ├── part3/   # Ingress, HPA, NetworkPolicy, RBAC
│   ├── part4/   # FluxCD GitOps, Trivy scans
│   ├── part5/   # cert-manager ClusterIssuers + Ingress
│   ├── part6/   # KEDA ScaledObject
│   ├── part7/   # Helm chart aras-demo-app
│   │   └── charts/aras-demo-app/
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── deployment.yaml
│   │           ├── service.yaml
│   │           ├── ingress.yaml
│   │           ├── rbac.yaml
│   │           ├── networkpolicy.yaml
│   │           └── NOTES.txt
│   ├── part8/   # OPA/Gatekeeper audit report
│   ├── part9/   # Chaos Mesh experiments
│   └── part10/  # Linkerd notes
├── scripts/
├── pipelines/
├── monitoring/
└── docs/
    ├── SRE_Case_Study_EN_v6.pdf
    ├── SRE_Case_Study_PL_v6.pdf
    └── Przewodnik_Techniczny_SRE_Lab_KOMPLETNY.docx
```

---

## Troubleshooting Log — 17 Issues

| ID | Issue | Resolution |
|----|-------|-----------|
| ISSUE-001 | KQL: CPUCapacityNanoCores missing | Use getschema |
| ISSUE-002 | Azure Policy: missing params | Add --params |
| ISSUE-003 | Terraform: RG already exists | terraform import |
| ISSUE-004 | Terraform: stale plan | Regenerate after import |
| ISSUE-005 | Container Insights after VM restart | Reinstall extension |
| ISSUE-006 | etcd Split-Brain (ks3 vs k3s) | kubectl delete node + re-register |
| ISSUE-007 | Azure DevOps: TerraformInstaller missing | Install from Marketplace |
| ISSUE-008 | Pipeline: Variable Group permission | View → Permit |
| ISSUE-009 | sudo ~ expansion | Use full path /home/buth11/ |
| ISSUE-010 | HPA cpu: unknown | Add resources.requests |
| ISSUE-011 | RBAC: apiRef instead of apiGroup | Fix field name |
| ISSUE-012 | cert-manager: duration < 1h rejected | Min 1h5m, renewBefore 6m |
| ISSUE-013 | KEDA: conflict with existing HPA | Delete HPA first |
| ISSUE-014 | Helm: ServiceAccount already exists | Delete old SA before install |
| ISSUE-015 | OPA: custom ConstraintTemplate blocked | Azure Arc manages Gatekeeper |
| ISSUE-016 | Chaos Mesh: scheduler field removed | Use duration instead |
| ISSUE-017 | Linkerd: container has no sh | Use linkerd-proxy container |

---

## Author

**Bartosz Suszko**
IT Solutions Bartosz Suszko · Olsztyn, Poland
8+ years in IT infrastructure · Banking · Industrial IoT/OEE
[analitykbiznesowy.pl](https://analitykbiznesowy.pl)
