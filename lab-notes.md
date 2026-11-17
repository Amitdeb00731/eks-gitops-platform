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
infrastructure across three environments, with a control gate before anything is
applied.

Task: build reusable Terraform modules and per-environment overlays, with
encrypted remote state, state locking and a policy gate.

Action (2026-11-17): wrote the bootstrap (state bucket and KMS key), a network
module from native resources (VPC, subnets, routing, optional NAT, KMS-encrypted
flow logs, default-deny security group) and the dev, staging and prod overlays.
Validated all five configurations and ran Checkov.

Result so far: format and validation clean; Checkov baseline 96 passed, 0 failed,
15 documented skips; the gate shown failing on a removed public access block.
The bootstrap apply, the three plans and the state-lock proof are next.

What caught us out:

- Checkov flagged both KMS key policies (`CKV_AWS_109`, `111`, `356`) because it
  reads them as identity policies. In a key policy `Resource "*"` means the key
  itself, so these are documented skips rather than a weaker policy.
- The guide predicted the gate would fail on `CKV_AWS_53` to `56`. Removing the
  public access block removes the resource those checks inspect, so the real
  failure is `CKV2_AWS_6`. Running the gate, rather than assuming its output,
  corrected the guide.
- DynamoDB state locking is deprecated in current Terraform. The backend uses the
  S3 native lock file instead (ADR 0004).
