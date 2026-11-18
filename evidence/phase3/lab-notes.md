# Phase 3 lab notes: standing up the delivery half

These notes record how the ArgoCD half of Phase 3 was demonstrated on a local
single-node cluster, and the problems met along the way. The continuous
integration half is defined in [`.gitlab-ci.yml`](../../.gitlab-ci.yml) and runs on
GitLab.

## Environment

- Windows laptop, WSL2 with an Ubuntu distribution.
- Docker Engine installed inside WSL2 (not Docker Desktop), to keep the footprint small.
- `kind` for a single-node cluster, `kubectl`, and ArgoCD installed from the upstream stable manifest.
- A cloud sandbox cannot host the cluster, because nested privileged containers are blocked there, so the delivery half runs on the laptop.

## Steps

1. Install Docker Engine in WSL2 from the official script, add the user to the `docker` group, and start the service. Confirm with `docker run --rm hello-world`.
2. Install `kubectl` (latest stable) and `kind` (latest release) as single binaries under `/usr/local/bin`.
3. Create the cluster: `kind create cluster --name gitops`. Confirm the node reaches `Ready`.
4. Install ArgoCD into the `argocd` namespace from the stable manifest, and wait for the deployments to roll out.
5. Create two GitLab deploy tokens, each least privilege: one with `read_repository` for ArgoCD to read the private repository, and one with `read_registry` for the cluster to pull the image.
6. Create the ArgoCD repository credential as a secret labelled `argocd.argoproj.io/secret-type: repository`, holding the `read_repository` token.
7. Create the pull secret `gitlab-registry` in the `sample-app` namespace as a `docker-registry` secret, holding the `read_registry` token, with `--docker-server=registry.gitlab.com`.
8. Add `imagePullSecrets` naming that secret to the deployment, and merge it to `main` so ArgoCD syncs it from Git. Only the secret's name is committed, never the credential.
9. Apply the app-of-apps root Application. ArgoCD creates the child Application and syncs the workload.

## Problems and resolutions

- **ArgoCD reported `ComparisonError: ... authentication required: HTTP Basic: Access denied`.** The root Application showed `SYNC STATUS: Unknown`, and the repo-server log carried the authentication error. Cause: the repository credential was invalid. Resolution: recreate the repository secret with a valid `read_repository` deploy token, then force a re-check with `kubectl -n argocd annotate application root argocd.argoproj.io/refresh=hard --overwrite`. Lesson: the deploy tokens must be created first and their real values used; a template left with placeholder values produces exactly this error.

- **A `kubectl` download left a dangling symlink.** `curl` failed with `Failure writing output to destination` and `chmod` reported a dangling symlink at the target path. Cause: a pre-existing broken symlink at `/usr/local/bin/kubectl`. Resolution: `sudo rm -f /usr/local/bin/kubectl`, then download the binary again.

## Verification

- `kubectl get applications -n argocd` shows `root` and `sample-app` both Synced and Healthy.
- `kubectl -n sample-app get deploy sample-app` shows 2/2.
- Drift test: scale the deployment to one replica, then watch ArgoCD restore it to two within a couple of seconds.
- The application answers `GET /` with its greeting and `GET /healthz` with `ok` through a port-forward.
- The ArgoCD UI shows both Applications green (`images/argocd-ui.png`).

## Teardown

The cluster is local and disposable. `kind delete cluster --name gitops` removes it
entirely. The GitLab deploy tokens should be revoked when the demonstration is no
longer needed.
