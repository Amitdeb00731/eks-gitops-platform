# terraform

Infrastructure as code for the platform. See [docs/01-foundation.md](../docs/01-foundation.md).

- `bootstrap/` creates the S3 state bucket and the DynamoDB lock table. Run once.
- `modules/` holds reusable building blocks with no environment-specific values.
- `envs/` composes the modules into dev, staging and production, each with its own
  remote-state key.
- `policy/` holds the Checkov configuration and the baseline.

State is remote (S3) and locked (DynamoDB). Nothing is applied until it passes the
policy scan. NAT gateways default off, since they are the quiet monthly cost.
