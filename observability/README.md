# observability

The centralised observability stack (Phase 5), installed on the cluster via
Helm.

- Prometheus for metrics, Loki for logs, and Grafana for the dashboards over
  both.
- Alertmanager for routing, with the alert rules and routing tree committed
  here rather than clicked together in the UI.
- The SLO dashboards and their recording rules: the service-level objectives
  the platform holds itself to, and the burn-rate alerts that fire before an
  objective is breached.

Dashboards and alert rules are provisioned from files in this directory, so the
monitoring configuration is itself version-controlled and reviewable.
