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

## Cost Estimation

### Azure Monitor Pricing Components

| Component | Pricing Model | Typical Cost |
|-----------|---------------|--------------|
| Log Analytics ingestion | Per GB | ~$2.76/GB |
| App Insights ingestion | Per GB | ~$2.76/GB |
| Retention (>30 days) | Per GB/month | ~$0.12/GB |
| Alerts | Per rule/month | ~$0.10-1.50 |
| Availability tests | Per test/month | ~$1.00 |

### Cost Optimization Strategies

| Strategy | Savings | Implementation |
|----------|---------|----------------|
| Sampling | 50-90% | Enable adaptive sampling |
| Retention policies | 30-50% | Set appropriate retention |
| Data collection rules | 20-40% | Filter unnecessary data |
| Commitment tiers | 10-30% | 100GB+/day commitments |
| Archive tier | 60-80% | Move cold data to archive |

### Monthly Cost Estimates

| Tier | Data Volume | Estimated Cost |
|------|-------------|----------------|
| Small | 5 GB/day | ~$400/month |
| Medium | 50 GB/day | ~$3,500/month |
| Large | 500 GB/day | ~$25,000/month |

## Multi-Cloud Alternatives

### Observability Platform Mapping

| Azure | AWS | GCP | Open Source |
|-------|-----|-----|-------------|
| Application Insights | X-Ray | Cloud Trace | Jaeger, Zipkin |
| Log Analytics | CloudWatch Logs | Cloud Logging | Loki, Elasticsearch |
| Azure Monitor | CloudWatch | Cloud Monitoring | Prometheus + Grafana |
| Alerts | CloudWatch Alarms | Cloud Alerting | Alertmanager |
| Workbooks | CloudWatch Dashboards | Looker Studio | Grafana |

### OpenTelemetry Integration

| Component | Azure | AWS | GCP | Self-Hosted |
|-----------|-------|-----|-----|-------------|
| Traces | App Insights | X-Ray | Cloud Trace | Jaeger |
| Metrics | Azure Monitor | CloudWatch | Cloud Monitoring | Prometheus |
| Logs | Log Analytics | CloudWatch | Cloud Logging | Loki |
| Collector | OTLP exporter | OTLP exporter | OTLP exporter | OTLP exporter |

### Cloud-Agnostic Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Collection | OpenTelemetry | Vendor-neutral instrumentation |
| Traces | Jaeger or Tempo | Distributed tracing |
| Metrics | Prometheus | Metrics collection |
| Logs | Loki | Log aggregation |
| Visualization | Grafana | Unified dashboards |
| Alerting | Alertmanager | Alert routing |

## Disaster Recovery

### Log Data Retention Strategy

| Priority | Data Type | Retention | DR Approach |
|----------|-----------|-----------|-------------|
| Critical | Security logs | 7 years | Geo-replicated storage |
| High | Application logs | 90 days | Cross-region export |
| Medium | Debug logs | 30 days | Single region |
| Low | Verbose traces | 7 days | No backup |

### Workspace Recovery

| Scenario | RTO | RPO | Recovery Steps |
|----------|-----|-----|----------------|
| Accidental deletion | 14 days | 0 | Soft delete recovery |
| Region outage | 4 hours | 1 hour | Secondary workspace |
| Data corruption | 1 hour | 15 min | Point-in-time restore |

### Cross-Region Export

| Method | Latency | Cost | Use Case |
|--------|---------|------|----------|
| Event Hub export | Near real-time | Medium | Live replication |
| Continuous export | 5-10 min | Low | Compliance archive |
| Query export | Manual | Low | Ad-hoc backup |

## SRE Best Practices

### SLI/SLO Definitions

| Service | SLI | SLO Target |
|---------|-----|------------|
| API | Availability | 99.9% |
| API | Latency P95 | < 200ms |
| API | Error rate | < 0.1% |
| Background jobs | Success rate | 99.5% |
| Background jobs | Processing time | < 5 min |

### Error Budgets

| SLO | Monthly Budget | Alert Threshold |
|-----|----------------|-----------------|
| 99.9% availability | 43.2 min downtime | 50% burned |
| 99.95% availability | 21.6 min downtime | 50% burned |
| 99.99% availability | 4.3 min downtime | 25% burned |

### On-Call Runbook Topics

| Topic | Content |
|-------|---------|
| Escalation | Contact matrix by severity |
| Triage | Decision tree for common alerts |
| Recovery | Standard mitigation procedures |
| Communication | Status page update process |
| Post-mortem | Incident documentation template |

## References

- [Azure Monitor Documentation](https://docs.microsoft.com/azure/azure-monitor/)
- [Application Insights](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [KQL Reference](https://docs.microsoft.com/azure/data-explorer/kusto/query/)
- [OpenTelemetry](https://opentelemetry.io/)
- [SRE Workbook](https://sre.google/workbook/table-of-contents/)
