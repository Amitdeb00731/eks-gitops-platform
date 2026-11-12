# kubernetes/argocd

ArgoCD's own declarations (Phase 3).

- The app-of-apps root Application, which points ArgoCD at this directory.
- The child Applications, one per workload, each naming a path in this
  repository and a destination namespace.

Adding a workload is a commit to this directory, not a console action. ArgoCD
reconciles whatever is committed here, so the set of running applications is
itself under version control and reviewable in a pull request.
