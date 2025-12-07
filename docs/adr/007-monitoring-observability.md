# ADR-007: Monitoring & Observability Strategy

## Status

Accepted

## Date

2025-12-07

## Context

The platform requires comprehensive monitoring and observability to:
- Track application performance and health
- Diagnose issues and debug production problems
- Monitor infrastructure costs and usage
- Meet compliance and audit requirements
- Enable proactive alerting and incident response

We need a unified observability strategy covering metrics, logs, traces, and alerting.

## Decision Drivers

- **Azure Integration**: Native Azure service integration
- **Cost**: Pricing model aligned with usage
- **Correlation**: Ability to correlate logs, metrics, and traces
- **Retention**: Data retention for compliance
- **Alerting**: Flexible alerting and notification

## Considered Options

1. **Azure Monitor Stack** (App Insights + Log Analytics + Azure Monitor)
2. **Datadog**
3. **Elastic Stack (ELK) on Azure**
4. **Grafana Cloud + Prometheus**
5. **New Relic**

## Evaluation Matrix

| Criterion | Weight | Azure Monitor | Datadog | Elastic | Grafana | New Relic |
|-----------|--------|---------------|---------|---------|---------|-----------|
| Azure Integration | 5 | 5 (25) | 4 (20) | 3 (15) | 3 (15) | 4 (20) |
| Auto-instrumentation | 4 | 5 (20) | 5 (20) | 3 (12) | 3 (12) | 5 (20) |
| Distributed Tracing | 5 | 5 (25) | 5 (25) | 4 (20) | 4 (20) | 5 (25) |
| Log Analytics | 4 | 5 (20) | 5 (20) | 5 (20) | 4 (16) | 4 (16) |
| Cost at Scale | 4 | 4 (16) | 2 (8) | 3 (12) | 4 (16) | 2 (8) |
| Learning Curve | 3 | 4 (12) | 4 (12) | 3 (9) | 4 (12) | 4 (12) |
| Alerting | 4 | 4 (16) | 5 (20) | 4 (16) | 4 (16) | 5 (20) |
| Dashboard/Viz | 3 | 3 (9) | 5 (15) | 4 (12) | 5 (15) | 4 (12) |
| **Total** | **32** | **143** | **140** | **116** | **122** | **133** |

## Decision

**Azure Monitor Stack** as the primary observability platform:

- **Application Insights**: APM, distributed tracing, availability tests
- **Log Analytics**: Centralized log aggregation and querying
- **Azure Monitor**: Metrics, alerts, dashboards, workbooks

## Rationale

1. **Seamless Azure integration**: Auto-instrumentation for App Service, Functions, AKS with minimal configuration.

2. **Unified platform**: Single pane of glass for metrics, logs, traces without data silos.

3. **Cost-effective at scale**: Pay-per-GB ingestion with sampling and retention controls.

4. **Built-in correlation**: Automatic correlation IDs across distributed systems.

5. **Compliance ready**: Built-in data residency, RBAC, and audit logging.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Monitor                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Application  │  │     Log      │  │    Azure     │       │
│  │  Insights    │  │  Analytics   │  │   Monitor    │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                 │                │
│         │    ┌────────────┴────────────┐    │                │
│         │    │     KQL Queries         │    │                │
│         │    └────────────┬────────────┘    │                │
│         │                 │                 │                │
│  ┌──────┴─────────────────┴─────────────────┴──────┐        │
│  │              Workbooks / Dashboards              │        │
│  └──────────────────────┬───────────────────────────┘        │
│                         │                                    │
│  ┌──────────────────────┴───────────────────────────┐        │
│  │           Alerts → Action Groups                 │        │
│  │     (Email, SMS, Logic Apps, Azure Functions)    │        │
│  └──────────────────────────────────────────────────┘        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Implementation

### Observability Components

| Component | Purpose | Integration |
|-----------|---------|-------------|
| Application Insights | APM, traces, availability | Workspace-linked to Log Analytics |
| Log Analytics Workspace | Centralized logging | KQL queries, data retention |
| Azure Monitor Alerts | Proactive notifications | Action Groups for routing |

### Key Metrics to Monitor

| Layer | Metric | Alert Threshold |
|-------|--------|-----------------|
| API | Response time (P95) | > 500ms |
| API | Error rate | > 1% |
| API | Request rate | > 1000 RPS |
| Database | Connection pool usage | > 80% |
| Database | Query duration | > 100ms |
| Cache | Hit rate | < 80% |
| Cache | Memory usage | > 90% |

### Alert Severity Levels

| Severity | Use Case | Response Time |
|----------|----------|---------------|
| 0 (Critical) | Service down | Immediate |
| 1 (Error) | High error rate | < 15 min |
| 2 (Warning) | Performance degradation | < 1 hour |
| 3 (Informational) | Capacity warnings | Next business day |

See `infra/modules/log-analytics/` for the Bicep implementation.

## Consequences

### Positive

- Zero additional vendors or tools to manage
- Automatic SDK updates with Azure services
- Native integration with Azure alerting
- Cost visibility through Azure Cost Management
- RBAC through Azure AD

### Negative

- Less feature-rich dashboards than Grafana/Datadog
- KQL learning curve for complex queries
- Limited custom instrumentation flexibility
- Vendor lock-in to Azure

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Data ingestion costs | Medium | Medium | Configure sampling, retention policies |
| Query performance | Low | Low | Optimize KQL, use summarize |
| Alert fatigue | Medium | Medium | Tune thresholds, use smart detection |

## References

- [Azure Monitor Documentation](https://docs.microsoft.com/azure/azure-monitor/)
- [Application Insights](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [KQL Reference](https://docs.microsoft.com/azure/data-explorer/kusto/query/)
