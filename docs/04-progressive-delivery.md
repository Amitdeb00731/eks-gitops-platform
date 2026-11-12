# Phase 4: progressive delivery and automated rollback

**Tier:** proven locally.

**Goal:** a new version reaches customers gradually, and a bad version is rolled
back automatically on its metrics, not by a human noticing.

**Risk and resilience framing:** reversible change and blast-radius control. A bad
release is seen by a small share of traffic, judged on real metrics, and withdrawn
before it reaches everyone. This is the control that turns "we can deploy often"
into "we can deploy often safely".

## Steps

1. **Install Argo Rollouts** on the local cluster. Argo Rollouts (or Flagger as
   the alternative) replaces the Deployment with a Rollout that understands canary
   and blue-green strategies.
2. **Convert the sample app to a Rollout** with a canary strategy: shift traffic
   in steps (for example 10, 25, 50, 100 per cent), pausing between steps for an
   analysis to run.
3. **Analysis against Prometheus.** An `AnalysisTemplate` queries Prometheus for
   the canary's success rate and latency. If the metric stays healthy, the
   rollout promotes to the next step; if it breaches the threshold, the rollout
   aborts and returns all traffic to the stable version.
4. **Blue-green variant.** Show the same app deployed blue-green, with traffic cut
   over only after the new version passes its checks, and an instant switch back.

## Fail then prove

Deploy a version that deliberately returns errors (or a seeded bad metric).
Confirm the canary analysis fails and Argo Rollouts rolls back automatically to
the stable version with no human action. Then deploy a healthy version and confirm
it promotes through every step.

## Evidence to capture (into `evidence/phase4/`)

- A healthy canary promoting through its steps, with the analysis passing.
- A bad version aborting and rolling back automatically, with the Prometheus
  query result that triggered it.
- The blue-green cutover and switch back.

## Done checklist

_Operator runbook; the as-built result lives in the evidence files._

- [ ] Argo Rollouts installed
- [ ] Sample app converted to a canary Rollout
- [ ] Prometheus analysis gating promotion
- [ ] Automated rollback shown on a bad version
- [ ] Blue-green variant shown

**Next, Phase 5:** the observability stack the rollback analysis depends on.
