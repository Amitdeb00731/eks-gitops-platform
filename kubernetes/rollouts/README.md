# kubernetes/rollouts

Argo Rollouts specifications (Phase 4).

- The canary strategy: progressive traffic shifting with pauses and automated
  analysis between steps.
- The blue-green strategy: a parallel preview environment promoted only after
  its checks pass.
- The Prometheus AnalysisTemplates the rollout queries at each step. A failed
  analysis aborts the rollout and returns traffic to the stable version, with
  no human in the loop.

The point is a deployment that proves itself against live metrics before it
takes full traffic, and rolls itself back when it cannot.
