# helm

Helm values files for the third-party charts the platform installs, pinned to
explicit chart versions.

Each subdirectory holds the values overlay for one chart: the observability
stack (Phase 5), the AWS Load Balancer controller and External Secrets operator
(Phases 2 and 6), and the platform add-ons they depend on. The charts
themselves are referenced by version, never vendored, so an upgrade is a
version bump in a committed file and a reviewable diff of the values that
change.
