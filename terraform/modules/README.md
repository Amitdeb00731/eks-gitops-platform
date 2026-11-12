# terraform/modules

Reusable modules with no environment-specific values. Each module has
`variables.tf`, `main.tf` and `outputs.tf`, and is composed by the environments
under `../envs/`.

- `network/` (Phase 1): VPC, subnets and routing, wrapping the community VPC
  module with the small set of options the platform needs.
- `eks/` (Phase 2): the cluster, node groups and OIDC provider for IAM roles for
  service accounts.

Modules are added as each phase needs them.
