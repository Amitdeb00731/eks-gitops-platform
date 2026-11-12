# Documentation

The guides below run in order. Phase 1 is a full build guide; later phases are
written to the same structure and are filled with the exact commands and
manifests as each phase is executed.

| Guide | Phase | What it covers |
| --- | --- | --- |
| [00-overview.md](00-overview.md) | - | The three-tier approach, prerequisites, and how to read the guides |
| [01-foundation.md](01-foundation.md) | 1 | Multi-environment Terraform, modules, remote state, policy gate |
| [02-eks-cluster.md](02-eks-cluster.md) | 2 | EKS, node groups, IAM roles for service accounts, load balancer controller, teardown |
| [03-gitops-delivery.md](03-gitops-delivery.md) | 3 | GitLab CI build and sign, ArgoCD install and app-of-apps |
| [04-progressive-delivery.md](04-progressive-delivery.md) | 4 | Argo Rollouts canary and blue-green, Prometheus analysis, automated rollback |
| [05-observability.md](05-observability.md) | 5 | Prometheus, Grafana, Loki, Alertmanager, SLO dashboards, Slack alerts |
| [06-secrets.md](06-secrets.md) | 6 | AWS Secrets Manager or Vault, the External Secrets operator, rotation |
| [07-cost-optimisation.md](07-cost-optimisation.md) | 7 | Idle-resource detection, tagging, Slack reporting |
| [08-disaster-recovery.md](08-disaster-recovery.md) | 8 | Velero and database backups, cross-region restore drill, runbooks |
| [09-reporting.md](09-reporting.md) | 9 | Platform runbook, controls mapping, business report |

Architecture decision records are under [adr/](adr/).
