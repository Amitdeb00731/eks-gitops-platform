# Phase 6: secrets management

**Tier:** built live, briefly, for the pull path; rotation documented.

**Goal:** no secret in Git and no secret baked into an image. Secrets live in a
managed store, are pulled into the cluster at run time, and are rotated.

**Risk and resilience framing:** credential hygiene. There are no embedded or
standing secrets, so a leaked manifest or image reveals nothing, and a rotated
secret limits how long a compromised one is useful.

## Steps

1. **The store.** Create the secrets in AWS Secrets Manager with Terraform (the
   sample app's database URL, the Slack webhook from Phase 5). Vault is the
   alternative and is noted where it differs.
2. **External Secrets operator.** Install it on the cluster. A `SecretStore`
   authenticates to Secrets Manager through an IRSA role scoped to only the
   secrets this app needs.
3. **Sync.** An `ExternalSecret` pulls the managed secret into a Kubernetes Secret
   that the app mounts. The value exists in the cluster at run time only; nothing
   secret is in Git.
4. **Rotation.** Enable Secrets Manager rotation for the database credential (or
   document the rotation lambda where a managed rotation does not apply). The
   External Secrets operator re-syncs on a refresh interval, so a rotated secret
   reaches the workload without a redeploy.

## Fail then prove

Show a `git grep` and a secret scan finding nothing secret in the repository.
Show the app reading its credential from the synced Secret. Rotate the secret and
confirm the app picks up the new value on the next refresh.

## Evidence to capture (into `evidence/phase6/`)

- The secret scan and `git grep` returning nothing.
- The `ExternalSecret` syncing and the app consuming the value.
- The rotation configuration and a value changing after rotation.

## Done checklist

_Operator runbook; the as-built result lives in the evidence files._

- [ ] Secrets created in Secrets Manager via Terraform
- [ ] External Secrets operator installed with scoped IRSA
- [ ] App consuming a synced secret, nothing secret in Git
- [ ] Rotation configured and shown

**Next, Phase 7:** automate the detection of wasted cloud spend.
