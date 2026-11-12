# Phase 8: disaster recovery and backup

**Tier:** designed and documented. Backup configuration is validated locally; the
restore drill is documented and, where it can be, performed on a local cluster.

**Goal:** the platform and its data can be recovered after loss, and the recovery
has been rehearsed, not just assumed.

**Risk and resilience framing:** recovery and impact tolerance. Operational
resilience asks not only whether a service can be protected, but whether it can be
restored within an acceptable time. This phase sets a recovery-time and
recovery-point objective and tests against them.

## Steps

1. **Cluster backup.** Install Velero with an S3 backup location and a schedule.
   Velero backs up Kubernetes objects and, with the CSI integration, volume
   snapshots. Back up the sample app's namespace on a schedule.
2. **Data backup.** Enable automated snapshots on the managed database, with
   cross-region snapshot copy so a Region loss does not lose the data.
3. **Restore drill.** Restore the sample namespace from a Velero backup onto a
   fresh local cluster, and document a database restore from a cross-region
   snapshot. Record how long each took against the stated objectives.
4. **Runbook.** `dr/runbook.md` states the recovery-time objective, the
   recovery-point objective, the exact restore steps, and who does what.

## Evidence to capture (into `evidence/phase8/`)

- The Velero schedule and a completed backup.
- The database snapshot and cross-region copy configuration.
- The restore drill result, with timings against the objectives.
- The runbook.

## Done checklist

_Operator runbook; the as-built result lives in the evidence files._

- [ ] Velero installed with a schedule and backup location
- [ ] Database snapshots with cross-region copy configured
- [ ] Restore drill performed and timed
- [ ] Runbook with RTO and RPO written

**Next, Phase 9:** write the platform up for operators and for risk readers.
