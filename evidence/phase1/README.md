# Evidence: Phase 1, multi-environment Terraform foundation

Guide: [docs/01-foundation.md](../../docs/01-foundation.md).

## Static proof (captured 2026-11-17)

Captured in a clean Linux build environment with Terraform 1.17.2, the
`hashicorp/aws` provider 6.73.0 and Checkov 3.4.5. No AWS credentials were
involved; these prove the code, not the account.

| File | What it proves |
| --- | --- |
| [01-fmt-validate.txt](01-fmt-validate.txt) | All five configurations (bootstrap, network module, dev, staging, prod) are correctly formatted and valid. |
| [02-checkov-baseline.txt](02-checkov-baseline.txt) | The policy gate passes: 96 passed, 0 failed, 15 documented skips, exit code 0. |
| [03-checkov-gate-fail.txt](03-checkov-gate-fail.txt) | The gate catches a real misconfiguration: with the state bucket's public access block removed it fails `CKV2_AWS_6` and exits 1. |

The pass count drops from 96 to 91 in the failing run because the five checks that
inspect the public access block's own settings no longer have a resource to
inspect. The one failure is the check that every bucket has a public access block
at all, which is the control that matters.

## AWS proof (to be captured)

| File | What it proves |
| --- | --- |
| `04-bootstrap-apply.txt` | The state bucket and KMS key exist, created from a reviewed plan. |
| `05-plan-dev.txt`, `06-plan-staging.txt`, `07-plan-prod.txt` | Each environment initialises against its own state key and plans the same 23 resources. |
| `08-state-lock.txt` | A second run is refused while the first holds the state lock. |

Raw terminal captures and screenshots go under `raw/`, which is git-ignored.
