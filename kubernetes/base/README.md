# kubernetes/base

The sample application's manifests: its Deployment (converted to an Argo Rollout
in Phase 4), its Service, and its readiness and liveness probes.

The application is a plain, honest demo HTTP service. It is not a
planted-vulnerability app; its job is to be deployed, rolled out and observed so
the platform's controls can be shown working.
