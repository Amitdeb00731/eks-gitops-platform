# Lab notes

A running log of the build, one entry per working session. Each entry records
what was done, what was proven, and anything that caught us out, in the STAR
form (situation, task, action, result).

## Conventions

- Three tiers, and every artefact is labelled: built live (briefly), proven
  locally, or designed and documented.
- No secret is ever committed. Credentials live in a secrets manager or in local
  environment variables that are git-ignored.
- One EKS cluster is only ever brought up for a single evidence run and is
  destroyed the same day.

## Entries

### Phase 1: foundation (in progress)

Situation: the platform needs a repeatable, reviewable way to define AWS
infrastructure across three environments.

Task: build reusable Terraform modules and per-environment overlays, with remote
state and a policy gate.

Action: scaffolding and the Phase 1 guide written. Execution to follow.

Result: to be recorded when Phase 1 is executed.
