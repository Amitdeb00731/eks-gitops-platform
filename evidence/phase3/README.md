# Evidence: Phase 3, GitOps delivery (GitLab CI and ArgoCD)

Guide: [docs/03-gitops-delivery.md](../../docs/03-gitops-delivery.md).

Phase 3 proves that a commit becomes a running workload with no manual deploy.
GitLab CI builds, scans, signs and promotes the image by writing the new tag into
Git. ArgoCD then reconciles the cluster to Git and self-heals any drift. No CI job
ever holds cluster credentials, and nothing is applied to the cluster by hand.

The continuous integration half runs on GitLab and is permanent. The continuous
delivery half was proven on a local single-node cluster on 2026-11-18. The key
terminal outputs are reproduced below, and the ArgoCD screenshot is under
`images/`.

## The chain

| Stage | What it proves |
| --- | --- |
| Build, test, scan, sign | On every push, GitLab CI runs `go vet` and the unit tests, builds the image daemonless with Kaniko, scans it with Trivy (the pipeline fails on any fixable HIGH or CRITICAL), and signs it with cosign keyless using the pipeline's own OIDC identity. No signing key is stored anywhere. |
| Promote through Git | On the default branch only, the promote stage runs `kustomize edit set image` and commits the new tag back to `main`. The deployed version is a reviewed commit, not a console action. |
| Deterministic scan | The build, runtime and test base images are pinned by digest, so the same commit always produces the same binary and the same scan result. A base image cannot be re-tagged underneath the pipeline. |
| ArgoCD app-of-apps | A single root Application watches `kubernetes/argocd/apps` and creates the child Applications committed there. Adding a workload is a commit, not a console action. |
| Delivery to the cluster | ArgoCD reads the private repository with a read-only deploy token, syncs `kubernetes/base`, and the workload comes up pulling its image from the private registry through a pull secret. |
| Drift self-heal | A manual change to the cluster is reverted automatically to match Git. |

## Continuous integration

The pipeline on `main` is green. The GitLab Duo automated review of the base-image
digest pinning returned a clean result with nothing to comment on. Representative
green pipelines on `main`:

- `e066a7c2`, pinning the Go toolchain for a deterministic Trivy gate.
- `01b9393e`, pinning the build, runtime and test base images by digest.

The pipeline definition is [`.gitlab-ci.yml`](../../.gitlab-ci.yml).

## Continuous delivery

ArgoCD v3.6.2 was installed on a single-node `kind` cluster (Kubernetes v1.37.0).
The app-of-apps root was applied once. It created the `sample-app` Application on
its own, which synced the deployment into the `sample-app` namespace.

```
NAME         SYNC STATUS   HEALTH STATUS
root         Synced        Healthy
sample-app   Synced        Healthy

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/sample-app   2/2     2            2
```

Both Applications read Synced and Healthy in the ArgoCD UI (`images/argocd-ui.png`).
The two pods are running the image pulled from the private GitLab registry through
the `gitlab-registry` pull secret.

## Drift self-heal, the key output

Git declares two replicas. The deployment was scaled to one behind ArgoCD's back.
Roughly one second later ArgoCD created a replacement pod and restored the
deployment to 2/2, because the child Application is configured with
`selfHeal: true`. The cluster cannot quietly diverge from the reviewed state in Git.

```
# drift introduced
deployment.apps/sample-app scaled      # replicas 2 -> 1
sample-app   1/2   ...

# ArgoCD reconciles, unprompted
sample-app-...-kjp69   0/1   ContainerCreating   0   1s
sample-app-...-kjp69   1/1   Running             0   9s
# back to 2/2, Synced, Healthy
```

## The workload serving

The application answered on both routes through a port-forward:

```
GET /         -> eks-gitops-platform sample app, version dev
GET /healthz  -> ok
```

## Security properties

- No CI job holds cluster credentials. CI writes to Git; ArgoCD reconciles the cluster to Git.
- Images are signed keyless with the pipeline's OIDC identity. No private key exists to leak.
- Base images are pinned by digest, so the scanned artefact and the shipped artefact are the same, reproducibly.
- The registry stays private. The cluster pulls through a least-privilege `read_registry` deploy token held in a pull secret, created out of band, so no credential is committed to Git.
- ArgoCD reads the repository through a separate least-privilege `read_repository` deploy token.
- The pod runs as a numeric non-root user with a read-only root filesystem, no privilege escalation and all Linux capabilities dropped.

## Reproducing the delivery half

The cluster ran on `kind` inside WSL2 Ubuntu, with Docker Engine installed in WSL2
rather than Docker Desktop, so the whole footprint is a few gigabytes. The install
and demonstration steps are in [`lab-notes.md`](lab-notes.md).
