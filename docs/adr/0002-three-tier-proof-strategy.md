# 0002: Prove the platform in three tiers rather than running it continuously

**Status:** accepted.

## Context

A permanently running multi-cluster EKS estate across dev, staging and production
would cost well over 150 US dollars a month and would not fit a development
laptop. The goal is a credible, inspection-ready portfolio piece, not a
production service, and the lab budget is small.

## Decision

Prove the platform in three tiers, and label every artefact with its tier:

- Built live, briefly: one EKS cluster, brought up for a single evidence run and
  destroyed the same day.
- Proven locally: the Kubernetes layer on a local kind or k3d cluster at zero
  cost.
- Designed and documented: multi-environment, disaster recovery and cost
  automation as validated Terraform and runbooks, not left applied.

## Consequences

The repository holds the real artefacts and is the deliverable. Ongoing cost is
close to zero. A reviewer is told plainly what was proven live, locally, or by
design, which is more honest than claiming a running estate that is not there. The
trade-off is that no environment runs continuously; this is stated, not hidden.
