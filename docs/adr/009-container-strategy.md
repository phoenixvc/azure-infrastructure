# ADR-009: Container & Compute Strategy

## Status

Accepted

## Date

2025-12-07

## Context

The platform needs to run containerized workloads with:
- Automatic scaling based on demand
- High availability and fault tolerance
- Cost optimization for variable workloads
- Support for both APIs and background jobs
- Integration with CI/CD pipelines

We need a container hosting strategy that balances operational simplicity, cost, and capability.

## Decision Drivers

- **Operational Complexity**: Team skill requirements
- **Scalability**: Auto-scaling capabilities
- **Cost**: Pricing model for our workload patterns
- **Features**: Ingress, secrets, networking
- **Portability**: Kubernetes compatibility

## Considered Options

1. **Azure App Service (Web Apps + Containers)**
2. **Azure Kubernetes Service (AKS)**
3. **Azure Container Apps (ACA)**
4. **Azure Container Instances (ACI)**
5. **Azure Functions (Containerized)**

## Evaluation Matrix

| Criterion | Weight | App Service | AKS | Container Apps | ACI | Functions |
|-----------|--------|-------------|-----|----------------|-----|-----------|
| Operational Simplicity | 5 | 5 (25) | 2 (10) | 4 (20) | 5 (25) | 5 (25) |
| Auto-scaling | 5 | 4 (20) | 5 (25) | 5 (25) | 2 (10) | 5 (25) |
| Cost Efficiency | 4 | 3 (12) | 3 (12) | 4 (16) | 5 (20) | 4 (16) |
| K8s Compatibility | 3 | 1 (3) | 5 (15) | 4 (12) | 3 (9) | 1 (3) |
| Networking | 4 | 4 (16) | 5 (20) | 4 (16) | 3 (12) | 3 (12) |
| Secrets Management | 4 | 4 (16) | 5 (20) | 4 (16) | 3 (12) | 4 (16) |
| Microservices Support | 4 | 3 (12) | 5 (20) | 5 (20) | 2 (8) | 3 (12) |
| Background Jobs | 4 | 3 (12) | 5 (20) | 5 (20) | 4 (16) | 5 (20) |
| **Total** | **33** | **116** | **142** | **145** | **112** | **129** |

## Decision

**Azure Container Apps (ACA)** as the primary compute platform with:

| Workload | Platform | Rationale |
|----------|----------|-----------|
| APIs/Web Apps | Container Apps | Scale to zero, KEDA scaling |
| Background Jobs | Container Apps Jobs | Event-driven execution |
| Scheduled Tasks | Container Apps Jobs | Cron-based scheduling |
| Legacy Apps | App Service | Easier migration path |
| Complex Orchestration | AKS | When full K8s needed |

## Rationale

Azure Container Apps scored highest due to:

1. **Serverless containers**: Scale to zero with per-second billing, ideal for variable workloads.

2. **Built-in KEDA**: Event-driven auto-scaling for queues, HTTP, custom metrics.

3. **Managed Dapr**: Sidecar support for service discovery, pub/sub, state management.

4. **Simplified networking**: Built-in ingress, traffic splitting, easy VNet integration.

5. **Kubernetes foundation**: Uses K8s under the hood without the management overhead.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                Container Apps Environment                        │
│                    (Managed Kubernetes)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   API Service   │  │  Worker Service │  │  Job (Cron)     │  │
│  │   ───────────   │  │  ─────────────  │  │  ───────────    │  │
│  │   Replicas: 1-10│  │  Replicas: 1-5  │  │  Schedule: 0 *  │  │
│  │   HTTP Scaling  │  │  Queue Scaling  │  │  * * *          │  │
│  └────────┬────────┘  └────────┬────────┘  └─────────────────┘  │
│           │                    │                                 │
│  ┌────────┴────────────────────┴────────┐                       │
│  │            Dapr Sidecars             │                       │
│  │  (Service Discovery, Pub/Sub, State) │                       │
│  └──────────────────────────────────────┘                       │
│                                                                  │
│  ┌──────────────────────────────────────┐                       │
│  │         Internal Ingress             │                       │
│  │      (Service-to-Service)            │                       │
│  └──────────────────────────────────────┘                       │
│                                                                  │
└───────────────────────┬─────────────────────────────────────────┘
                        │
            ┌───────────┴───────────┐
            │    External Ingress   │
            │   (HTTPS, Custom DNS) │
            └───────────────────────┘
```

## Implementation

### Container App Configuration

| Configuration | Description |
|---------------|-------------|
| Revision mode | Multiple revisions for traffic splitting |
| Ingress | External with custom DNS support |
| Secrets | Key Vault references via managed identity |
| Registry | ACR with managed identity authentication |
| Health probes | Liveness and readiness endpoints |

### Scaling Options

| Scaling Type | Trigger | Use Case |
|--------------|---------|----------|
| HTTP | Concurrent requests | API workloads |
| KEDA (Queue) | Message count | Background processors |
| KEDA (Custom) | Custom metrics | Specialized workloads |
| Schedule | Cron expression | Jobs and maintenance |

### Resource Sizing

| Workload | CPU | Memory | Min Replicas | Max Replicas |
|----------|-----|--------|--------------|--------------|
| Light API | 0.25 | 0.5Gi | 0 | 5 |
| Standard API | 0.5 | 1Gi | 1 | 10 |
| Heavy Processing | 1.0 | 2Gi | 1 | 20 |
| Background Job | 0.25 | 0.5Gi | 0 | 10 |

## When to Use Each Platform

| Scenario | Platform | Reason |
|----------|----------|--------|
| REST APIs | Container Apps | HTTP scaling, scale to zero |
| Event processors | Container Apps | KEDA scaling, queue triggers |
| Scheduled jobs | Container Apps Jobs | Cron support, one-time execution |
| Complex microservices | AKS | Full K8s control |
| Legacy .NET apps | App Service | Simpler migration |
| Burst compute | ACI | Quick spin-up, no cluster |

## Consequences

### Positive

- Minimal infrastructure management
- Scale to zero reduces costs
- Built-in Dapr for microservices patterns
- Easy revision management and traffic splitting
- Integrated with Azure services

### Negative

- Less control than raw Kubernetes
- Some AKS features not available
- Cold start latency on scale from zero
- Regional availability limited

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Cold start latency | Medium | Medium | Keep minReplicas=1 for critical paths |
| Resource limits | Low | Medium | Monitor usage, request increases |
| Feature gaps vs AKS | Medium | Low | Use AKS for complex needs |

## Cost Estimation

### Azure Container Apps Pricing

| Component | Pricing | Notes |
|-----------|---------|-------|
| vCPU | ~$0.000024/vCPU-second | Active usage only |
| Memory | ~$0.000003/GiB-second | Active usage only |
| Requests | First 2M free, then $0.40/M | HTTP requests |
| Idle | ~$0.0048/hour (min 0.25 vCPU) | When minReplicas > 0 |

### Monthly Cost Scenarios

| Workload | Config | Usage | Monthly Cost |
|----------|--------|-------|--------------|
| Light API | 0.25 vCPU, 0.5Gi | 8h/day active | ~$15 |
| Standard API | 0.5 vCPU, 1Gi, min=1 | 24/7 | ~$50 |
| Heavy API | 1 vCPU, 2Gi, 5 replicas avg | 24/7 | ~$400 |
| Background worker | 0.25 vCPU, 0.5Gi | 2h/day | ~$5 |
| Cron job (daily) | 0.25 vCPU, 0.5Gi | 10min/day | ~$1 |

### Cost Comparison by Platform

| Platform | Small App | Medium App | Large App |
|----------|-----------|------------|-----------|
| Container Apps | $15/mo | $50/mo | $400/mo |
| App Service (B1) | $13/mo | $55/mo | $220/mo |
| AKS (D2s v3 x 3) | $250/mo | $250/mo | $500/mo |
| ACI (on-demand) | Variable | Variable | Variable |

## Multi-Cloud Alternatives

### Container Platform Mapping

| Azure | AWS | GCP | Self-Hosted |
|-------|-----|-----|-------------|
| Container Apps | App Runner | Cloud Run | Knative |
| Container Apps | ECS Fargate | Cloud Run | Kubernetes |
| AKS | EKS | GKE | Kubernetes |
| ACI | Fargate (standalone) | Cloud Run Jobs | Docker |
| App Service | Elastic Beanstalk | App Engine | Docker Compose |

### Feature Comparison

| Feature | ACA | App Runner | Cloud Run |
|---------|-----|------------|-----------|
| Scale to zero | Yes | Yes | Yes |
| Min instances | 0 | 1 | 0 |
| Max instances | 300 | 25 | 1000 |
| Custom domains | Yes | Yes | Yes |
| VPC integration | Yes | Yes | Yes |
| GPU support | No | No | Yes |
| Dapr support | Yes | No | No |

### Kubernetes Distribution Comparison

| Platform | Management | Cost | Best For |
|----------|------------|------|----------|
| AKS | Azure managed | Control plane free | Azure ecosystem |
| EKS | AWS managed | $72/mo/cluster | AWS ecosystem |
| GKE | Google managed | $72/mo/cluster | Best K8s features |
| OpenShift | Red Hat managed | Premium | Enterprise |
| Rancher | Self-managed | License | Multi-cluster |

## Disaster Recovery

### High Availability Configuration

| Level | Configuration | RTO | RPO |
|-------|---------------|-----|-----|
| Basic | minReplicas=1 | Minutes | 0 |
| Standard | minReplicas=2, zone-redundant | Seconds | 0 |
| Premium | Multi-region, traffic manager | Seconds | 0 |

### Multi-Region Deployment

| Component | Primary Region | Secondary Region |
|-----------|----------------|------------------|
| Container Apps | Active | Standby or Active |
| Database | Primary | Geo-replica |
| Storage | GRS enabled | Auto-failover |
| DNS | Traffic Manager | Health probe based |

### Failover Strategies

| Strategy | Trigger | Automation |
|----------|---------|------------|
| Manual | Operator decision | CLI/Portal |
| Health-based | Failed health probes | Traffic Manager |
| Metric-based | Error rate threshold | Azure Automation |
| Scheduled | DR drill | Runbook |

### Recovery Runbook

| Step | Action | Responsible |
|------|--------|-------------|
| 1 | Detect failure via alerts | Automated |
| 2 | Confirm outage scope | On-call engineer |
| 3 | Update DNS/Traffic Manager | Automated or manual |
| 4 | Verify secondary region | On-call engineer |
| 5 | Communicate status | Incident manager |
| 6 | Monitor recovery | On-call engineer |
| 7 | Post-incident review | Team |

## Container Security

### Image Security

| Practice | Tool | Implementation |
|----------|------|----------------|
| Scan images | Defender for Containers | CI/CD integration |
| Sign images | Notation/Cosign | Registry policy |
| Base images | Microsoft CBL-Mariner | Minimal attack surface |
| Update policy | Dependabot | Weekly updates |

### Runtime Security

| Control | Azure Feature | Purpose |
|---------|---------------|---------|
| Network isolation | VNet integration | Private networking |
| Secrets | Key Vault references | No hardcoded secrets |
| Identity | Managed Identity | No credentials |
| Egress control | NSG rules | Restrict outbound |

## Blue-Green Deployment

| Phase | Traffic Split | Action |
|-------|---------------|--------|
| Deploy green | 0% to green | Create new revision |
| Smoke test | 0% to green | Verify health |
| Canary | 10% to green | Monitor metrics |
| Ramp | 50% to green | Expand testing |
| Complete | 100% to green | Full cutover |
| Rollback | 100% to blue | If issues detected |

## References

- [Azure Container Apps](https://docs.microsoft.com/azure/container-apps/)
- [KEDA Scalers](https://keda.sh/docs/scalers/)
- [Dapr on Container Apps](https://docs.microsoft.com/azure/container-apps/dapr-overview)
- [Container Apps Pricing](https://azure.microsoft.com/pricing/details/container-apps/)
- [Cloud Run](https://cloud.google.com/run)
- [AWS App Runner](https://aws.amazon.com/apprunner/)
