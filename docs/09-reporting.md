# Phase 9: reporting and governance

**Tier:** written.

**Goal:** the platform is documented for the two audiences who judge it: operators
who run it, and risk and audit readers who assure it.

**Risk and resilience framing:** auditability and the business view. The controls
built in Phases 1 to 8 are mapped to recognised frameworks so a reviewer can see,
control by control, what is in place and how it is evidenced.

## Deliverables (into `report/`)

1. **Platform runbook** (`report/runbook.md`). How to operate the platform: deploy
   a new service, promote a release, respond to a failed rollout, read the
   dashboards, follow an alert, and run the disaster-recovery steps.
2. **Controls mapping** (`report/controls-mapping.md`). Each control mapped to the
   NIST Secure Software Development Framework, SOX IT general controls (change
   management, segregation of duties, audit trail), and the UK PRA and FCA
   operational-resilience expectations. Each row cites the evidence that proves
   it.
3. **Business report** (`report/business-report.md`). For a business and risk
   audience, in plain language: what the platform delivers, how the controls hold
   under a realistic failure, the residual risks, and an honest statement of
   scope (what was proven live, locally, or by design).

## Consolidation

The architecture decision records in `docs/adr/` are summarised here, so the
reasoning behind the main choices sits alongside the controls they produced.

## Done checklist

_Operator runbook; the as-built result lives in the report files._

- [ ] Platform runbook written
- [ ] Controls mapping written, every row cited
- [ ] Business report written, scope stated honestly
- [ ] Architecture decisions summarised

This closes the build. The repository then stands as a complete, honest,
inspection-ready account of a production-style bank delivery platform.
