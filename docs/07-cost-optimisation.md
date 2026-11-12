# Phase 7: cost-optimisation automation

**Tier:** designed. The script is written and validated against the account in a
read-only dry run; a scheduled deployment is optional.

**Goal:** find wasted spend automatically, tag it, and report the saving to Slack.

**Risk and resilience framing:** cost governance and waste control. A bank watches
cloud spend as a managed cost; automated detection turns an occasional manual
review into a standing control.

## Steps

1. **The detector** (`cost/idle_resources.py`, boto3). It finds:
   - EC2 instances with low average CPU over the last fortnight (from CloudWatch).
   - EBS volumes in the `available` state (unattached).
   - Elastic IPs with no association.
2. **Tag, do not delete.** The script tags each finding (for example
   `review=idle-candidate`) rather than deleting anything, so a human decides.
   Deletion stays a separate, deliberate step.
3. **Report.** It posts a summary to Slack: the resources found, their type, and
   the estimated monthly saving if they were removed.
4. **Schedule (optional).** An EventBridge rule can run the detector on a schedule
   through Lambda. For the portfolio, a dry run and a sample report are enough;
   the scheduled deployment is documented as the production step.

## Evidence to capture (into `evidence/phase7/`)

- The detector's output against the account (read-only).
- A sample Slack report.
- The tags applied to a candidate resource.

## Done checklist

_Operator runbook; the as-built result lives in the evidence files._

- [ ] Detector written and validated read-only
- [ ] Findings tagged, not deleted
- [ ] Slack report produced
- [ ] Scheduled deployment documented as the production step

**Next, Phase 8:** back up the platform and prove it can be restored.
