# ci

The GitLab CI pipeline for the sample application (Phase 3).

- `.gitlab-ci.yml` lives at the repository root and defines the pipeline.
- `trivy-gate-demo/` is a throwaway image for demonstrating the scan gate failing,
  run by hand. It is never deployed or signed.

## Stages

The pipeline runs in order, and each stage must pass before the next:

- `test`: `go vet` and the unit tests for the app in `kubernetes/base/app`.
- `build`: build the image with Kaniko (no Docker daemon) and push it to the
  project's container registry, tagged with the commit SHA.
- `scan`: scan the image with Trivy and fail on any fixable HIGH or CRITICAL
  finding.
- `sign`: sign the image with cosign, keyless, using the pipeline's own OIDC
  identity, so no private key is held anywhere.
- `promote`: on the default branch only, write the new image tag into
  `kubernetes/base/kustomization.yaml` and push it back to Git.

The pipeline is the single path to the cluster. It never deploys directly: it
writes the approved tag to Git, and ArgoCD reconciles the cluster to Git. A change
reaches the cluster through a merge the pipeline approved, never through a direct
push or a console action.

## Required CI/CD variables

- `PROMOTE_TOKEN`: a project access token with `write_repository` scope, used by
  the promote stage to push the tag bump. Everything else (`CI_REGISTRY*`,
  `CI_PROJECT_DIR`, the OIDC token) is provided by GitLab.
