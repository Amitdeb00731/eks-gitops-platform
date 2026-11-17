# terraform/modules

Reusable modules with no environment-specific values. Each module has
`variables.tf`, `main.tf` and `outputs.tf`, and is composed by the environments
under `../envs/`.

- `network/` (Phase 1): VPC, a public and a private subnet per Availability Zone,
  routing, an optional NAT gateway, KMS-encrypted flow logs and a default-deny
  security group. Written from native resources (ADR 0005).
- `eks/` (Phase 2): the cluster, node groups and OIDC provider for IAM roles for
  service accounts.

Modules are added as each phase needs them.
