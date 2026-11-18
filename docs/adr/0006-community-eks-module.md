# 0006: Use the community EKS module for the cluster

**Status:** accepted.

## Context

ADR 0005 wrote the network module from native resources, and noted the EKS
module would be decided separately. An EKS cluster is far larger: the control
plane, the OIDC provider, managed node groups with their launch templates and
IAM roles, the security groups, the access entries and the core addons. Writing
all of that by hand is a large, error-prone surface that a static scan cannot
make safe on its own, and it is not how a platform team runs EKS in practice.

## Decision

Use the community `terraform-aws-modules/eks/aws` module for the cluster,
wrapped in a thin local `modules/eks` that sets the platform's secure defaults:
the OIDC provider on, Kubernetes secrets encrypted with a dedicated KMS key,
control-plane audit logging, a public endpoint narrowed by CIDR plus private
access, and native EKS access entries instead of the aws-auth ConfigMap. Pin the
module to a patch range (`~> 21.30.0`).

IAM roles for service accounts are kept in our own native `modules/irsa` rather
than the community module, because the trust relationship is the security-
critical part and is small enough to own and to read in full. The AWS Load
Balancer Controller policy is the controller's own published policy, committed
and pinned to a release, not hand-maintained.

## Consequences

The cluster is built the way the industry builds it, on a maintained module that
tracks EKS changes, while the platform keeps its own thin, reviewable wrapper and
owns the parts that matter most for least privilege. The trade-off is a
dependency whose internals a static scan does not descend into; it is pinned by
version, which is the registry's supply-chain control, and this is recorded as a
documented `CKV_TF_1` skip. The community module cannot be fetched in the offline
build environment, so this phase's Terraform is validated during the live bring-up
on the operator workstation, which is where a live-tier phase is proven anyway.
