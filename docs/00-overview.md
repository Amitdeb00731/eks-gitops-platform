# Phase 0: overview and prerequisites

This guide explains how the build is structured and what to install before
Phase 1.

## The three tiers

Every part of the platform sits in one of three tiers. The tier is stated at the
top of each later guide.

1. **Built live, briefly.** Brought up on AWS from Terraform, used to capture
   evidence, then destroyed the same day. Only Phases 2 and 6 touch AWS, and
   only for a single evidence run each.
2. **Proven locally, at zero cost.** Run on a local kind or k3d cluster on the
   laptop. The GitOps, progressive-delivery and observability layers (Phases 3
   to 5) are proven this way.
3. **Designed and documented.** Written as Terraform and runbooks and proven
   with validate, plan and a policy scan, not left applied. Multi-environment
   separation, cost automation and disaster recovery (Phases 1, 7 and 8) sit
   here.

The point of the split is honesty and cost control. The repository holds the
real artefacts; the live tier exists only to prove they work on AWS.

## Prerequisites

Install the following on the development laptop. Versions are indicative; pin
exact versions in `docs/adr/` as they are chosen.

| Tool | Purpose |
| --- | --- |
| AWS CLI v2 | Authenticating to the AWS account |
| Terraform (>= 1.6) | Infrastructure as code |
| kubectl | Talking to Kubernetes |
| Helm (>= 3) | Installing the observability stack and operators |
| kind or k3d | A local Kubernetes cluster for the zero-cost tier |
| Docker | Building images and running the local cluster |
| ArgoCD CLI | Managing ArgoCD from the command line |
| Checkov or tfsec | Scanning Terraform before it is applied |

The CI pipeline runs on GitLab CI (a free gitlab.com account). ArgoCD performs
delivery regardless of the CI platform.

## AWS account

The live tier reuses the existing cloud-iam-lab AWS workload account, under its
own project tag and VPC, in the account's pinned Region. The account already
carries guardrail policies: the Region is fixed, the security services cannot be
disabled, and sensitive deletions require multi-factor authentication. The
Terraform in this build stays inside those guardrails. If an action is denied by
a policy, it is documented and worked around, never resolved by weakening the
guardrail.

## How to read the guides

Each guide states its tier, its goal, the steps with real commands and
manifests, the evidence to capture, and the risk and resilience framing. Where a
control can be shown working, it is proven by first failing a known-bad input
and then passing, so the evidence shows the control actually doing its job.

## Cost and safety rules

- Terraform owns every billable resource. Nothing billable is created by hand.
- An EKS cluster is only ever up for one evidence run and is destroyed the same
  day, with the teardown checklist run first and a post-destroy sweep for
  leftovers.
- A low budget alert is set on the account before any live work.
- No secret is committed. The pipeline runs a secret scan on every change.
