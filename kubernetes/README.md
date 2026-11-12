# kubernetes

The declarative state ArgoCD reconciles onto the cluster.

- `base/` the sample application manifests (Deployment or Rollout, Service, probes).
- `argocd/` ArgoCD's own definitions: the app-of-apps root and the child
  Applications, so adding a workload is a commit, not a console action.
- `rollouts/` Argo Rollouts specifications: the canary and blue-green strategies
  and the Prometheus analysis templates.

Git is the single source of truth. ArgoCD detects and corrects drift, so the
running state cannot quietly diverge from what is committed here.
