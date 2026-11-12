# ci

The GitLab CI pipeline definition and its supporting scripts (Phase 3).

- `.gitlab-ci.yml` lives at the repository root; this directory holds the job
  scripts and templates it includes.
- Stages run in order: validate (Terraform fmt and validate, Helm lint), scan
  (Checkov on the Terraform, Trivy on container images), and the release gate
  that signs and promotes an image only when every preceding stage passes.

The pipeline is the single path to production. A change reaches the cluster
through a merge that the pipeline approved, never through a direct push or a
console action.
