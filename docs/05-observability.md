# Phase 5: centralised observability

**Tier:** proven locally.

**Goal:** metrics, logs and alerts in one place, with service-level objectives and
alerts that reach a human on Slack.

**Risk and resilience framing:** early detection and measurable service levels. A
problem is seen in the burn of an error budget before customers feel it, which is
the operational-resilience expectation of seeing and containing disruption early.

## Steps

1. **Metrics.** Install `kube-prometheus-stack` with Helm (Prometheus, Grafana,
   node and kube-state metrics, Alertmanager). Keep retention short on the local
   cluster to fit the laptop.
2. **Logs.** Install Loki with a log shipper (promtail or the Grafana Agent) so
   logs sit beside metrics in Grafana.
3. **Dashboards as code.** Grafana dashboards are committed under
   `observability/` as JSON and loaded by the Grafana sidecar from a ConfigMap,
   so the dashboards are version-controlled, not clicked together.
4. **Service-level objectives.** Define an availability SLO and a latency SLO for
   the sample service, with a multi-window burn-rate alert, in
   `observability/slo/`.
5. **Alert routing.** Route the burn-rate alert through Alertmanager to a Slack
   channel. The Slack webhook is a secret: it is supplied at run time and never
   committed (Phase 6 moves it into the secrets manager).

## Fail then prove

Drive the sample service to breach its SLO (inject latency or errors). Confirm the
burn-rate alert fires and reaches Slack, then clear the fault and confirm the
alert resolves.

## Evidence to capture (into `evidence/phase5/`)

- The Grafana dashboards rendering live metrics and logs.
- The SLO definitions and the burn-rate alert rule.
- An alert firing to Slack and then resolving.

## Done checklist

_Operator runbook; the as-built result lives in the evidence files._

- [ ] kube-prometheus-stack installed
- [ ] Loki and log shipping installed
- [ ] Dashboards committed as code and loaded
- [ ] SLOs and burn-rate alert defined
- [ ] Alert shown firing to Slack and resolving

**Next, Phase 6:** move the Slack webhook and other secrets into a secrets manager.
