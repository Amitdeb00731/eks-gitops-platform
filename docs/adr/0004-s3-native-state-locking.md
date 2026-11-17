# 0004: S3 native state locking instead of DynamoDB

**Status:** accepted.

## Context

Remote state needs a lock so two Terraform runs cannot write it at once. The
original plan used the established pattern of an S3 bucket for state and a
DynamoDB table for the lock. Terraform 1.10 introduced native locking in the S3
backend (a lock object written alongside the state with a conditional write), and
later releases deprecate the DynamoDB lock arguments.

## Decision

Use the S3 backend with `use_lockfile = true`. Do not create a DynamoDB lock
table. Require Terraform 1.10 or later in every configuration.

## Consequences

One fewer resource to create, secure, pay for and tear down. The backend uses a
supported, non-deprecated mechanism. The lock is proven the same way as before: a
second run is refused while the first holds the lock, and the refusal names the
`.tflock` object in the state bucket. Anyone on an older Terraform release must
upgrade; the version constraint makes that failure explicit rather than silent.
