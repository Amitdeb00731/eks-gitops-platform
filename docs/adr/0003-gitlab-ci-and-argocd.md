# 0003: GitLab CI for build, ArgoCD for delivery

**Status:** accepted.

## Context

The pipeline needs continuous integration (build, test, scan, sign) and
continuous delivery (getting the result onto the cluster). The earlier DevSecOps
build used GitHub Actions, so a second ecosystem adds breadth. The platform is
described around GitLab CI and ArgoCD.

## Decision

Use GitLab CI, on a free gitlab.com account, for integration. Use ArgoCD for
delivery, pulling manifests from Git onto the cluster. The two are independent:
GitLab CI never deploys to the cluster directly; it writes the new image tag into
Git, and ArgoCD reconciles the cluster to Git.

## Consequences

Delivery is pull-based and declarative: the cluster follows Git, which is the
audit record, and no pipeline holds cluster credentials. GitLab CI complements the
GitHub Actions work in the DevSecOps build, showing a second CI ecosystem. If
GitLab is not wanted, GitHub Actions is a drop-in replacement for the integration
side, since ArgoCD does the delivery regardless.
