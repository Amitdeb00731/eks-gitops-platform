# terraform/envs

One directory per environment: `dev/`, `staging/`, `prod/`. Each is a thin
composition of the modules under `../modules/`, plus the only per-environment
differences: the remote-state key, the CIDR range, and sizes.

The three environments are identical in shape and differ only where they must, so
a change proven in dev behaves the same in production. Dev is the environment
applied for real during the Phase 2 bring-up; staging and production are proven by
`terraform plan`.
