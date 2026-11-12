# Phase 3: GitOps delivery with GitLab CI and ArgoCD

**Tier:** proven locally on kind, and on the live cluster during the Phase 2
bring-up.

**Goal:** a change flows from a commit to a running workload with no manual
deploy. GitLab CI builds, tests, scans and signs the image; ArgoCD syncs the
manifests from Git to the cluster.

**Risk and resilience framing:** declarative, auditable change with no manual
production access. Git is the single source of truth, and ArgoCD detects and
corrects drift, so the running state cannot quietly diverge from the reviewed
state.

## Steps

1. **Sample application.** A small HTTP service in `kubernetes/base/`, with a
   `Dockerfile`, a `Deployment`, a `Service` and a readiness probe. It is a
   plain, honest demo service, not a planted-vulnerability app.
2. **GitLab CI pipeline** (`ci/.gitlab-ci.yml`) with stages:
   - `build`: build the image.
   - `test`: run the unit tests.
   - `scan`: scan the image with Trivy; fail on a high or critical finding.
   - `sign`: sign the image with cosign (keyless), and record provenance.
   - `publish`: push the signed image and write the new tag into the config path
     that ArgoCD watches.
3. **Install ArgoCD** on the local kind cluster with Helm or the upstream
   manifests. Expose the UI locally.
4. **App-of-apps.** `kubernetes/argocd/` holds a root Application that points at a
   directory of child Applications, so adding a workload is a commit, not a
   console action.
5. **Sync and drift.** ArgoCD auto-syncs the sample app from Git. Prove drift
   detection: change a live replica count by hand with `kubectl`, and watch
   ArgoCD report `OutOfSync` and restore it.

## Fail then prove

Push an image whose Trivy scan has a high finding and confirm the pipeline stops
before publish. Fix it and confirm it proceeds. The paired result shows the scan
gate works.

## Evidence to capture (into `evidence/phase3/`)

- A pipeline run with all stages green, and the Trivy gate stopping a bad image.
- The signed image and its cosign verification.
- ArgoCD showing the app Synced and Healthy.
- The drift demonstration: a hand edit reverted by ArgoCD.

## Done checklist

_Operator runbook; the as-built result lives in the evidence files._

- [ ] Sample app and Dockerfile in `kubernetes/base/`
- [ ] GitLab CI pipeline building, testing, scanning, signing
- [ ] ArgoCD installed, app-of-apps in place
- [ ] Auto-sync working, drift corrected
- [ ] Trivy gate shown stopping a bad image, then passing

**Next, Phase 4:** roll releases out gradually with automated rollback.
