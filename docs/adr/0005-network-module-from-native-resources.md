# 0005: Network module written from native resources

**Status:** accepted.

## Context

The original plan wrapped the community `terraform-aws-modules/vpc` module. It is
well tested, but it is large, exposes many options the platform does not use, and
its resources are only visible to a static policy scan once the module has been
downloaded. The platform needs a small network: a VPC, a public and a private
subnet per Availability Zone, routing, an optional NAT gateway, flow logs and a
locked-down default security group.

## Decision

Write the network module from native AWS provider resources. Keep the interface
small (CIDR, zones, subnet ranges, NAT on or off, flow log retention) and put the
security defaults inside the module: flow logs always on and KMS-encrypted, the
default security group with no rules, and no public IP assigned on launch.

## Consequences

Every resource is in the repository and visible to Checkov without fetching
external code, so the policy gate covers the whole network. The module is short
enough to review in one sitting, which suits a change-control process. The cost is
owning roughly 300 lines that a community module would otherwise maintain. The
EKS module in Phase 2 is a different trade-off (far more complex, and the
community module is the industry default), and is decided there.
