# terraform/policy

The pre-apply policy gate. Checkov scans the Terraform before anything is applied,
and the pipeline fails on a violation.

Run from the repository root:

```
checkov -d terraform --config-file terraform/policy/.checkov.yaml
```

## Baseline

135 passed, 0 failed, 16 skipped (Checkov 3.4.5, through Phase 2 code). The gate is proven
by removing the state bucket's public access block, which fails `CKV2_AWS_6`, then
restoring it. See [evidence/phase1](../../evidence/phase1/README.md).

## Documented exceptions

Every skip is an inline `checkov:skip` comment beside the resource it applies to,
with its reason, so the exception is reviewed with the code it excuses. A skip is
a recorded risk acceptance, not a silent exclusion.

| Check | Resource | Reason |
| --- | --- | --- |
| CKV_AWS_18 | State bucket | Access logging needs a second bucket that would itself fail this check. CloudTrail data events are the audit record for state access. |
| CKV_AWS_144 | State bucket | The account's service control policy pins a single Region, so cross-Region replication is not permitted. Versioning provides recovery. |
| CKV2_AWS_62 | State bucket | Event notifications have no consumer for a state bucket. Changes are audited through CloudTrail. |
| CKV_AWS_109, CKV_AWS_111, CKV_AWS_356 | State key policy, flow log key policy | These checks are written for identity policies. In a KMS key policy, `Resource "*"` means the key itself, and the account-root statement is the AWS default key policy that keeps the key manageable through IAM. |
| CKV_TF_1 | `module.eks` | Registry modules are pinned by version, the registry's supply-chain control. Commit-hash pinning applies to git sources, not registry sources. |

The three key-policy checks are counted once per key in each configuration that
uses it, which gives 12 of the skips; the state bucket accounts for 3, and the
EKS module source for 1.
