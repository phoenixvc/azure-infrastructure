# ADR-005: Infrastructure as Code Tooling

## Status

Accepted

## Date

2025-12-07

## Context

We need to manage Azure infrastructure declaratively with:
- Repeatable deployments across environments
- Version-controlled infrastructure changes
- Modular, reusable components
- CI/CD integration capabilities

The choice of IaC tool affects team productivity, deployment reliability, and long-term maintainability.

## Decision Drivers

- **Azure Integration**: Native support and feature parity
- **Learning Curve**: Time to productivity for team
- **Modularity**: Ability to create reusable components
- **Tooling**: IDE support, validation, and debugging
- **Community**: Documentation, examples, and support

## Considered Options

1. **Azure Bicep**
2. **Terraform (AzureRM Provider)**
3. **ARM Templates (JSON)**
4. **Pulumi (Python/TypeScript)**
5. **Azure CLI Scripts**

## Evaluation Matrix

| Criterion | Weight | Bicep | Terraform | ARM | Pulumi | CLI Scripts |
|-----------|--------|-------|-----------|-----|--------|-------------|
| Azure Feature Parity | 5 | 5 (25) | 4 (20) | 5 (25) | 4 (20) | 5 (25) |
| Learning Curve | 4 | 4 (16) | 3 (12) | 2 (8) | 3 (12) | 4 (16) |
| Modularity | 5 | 5 (25) | 5 (25) | 3 (15) | 5 (25) | 2 (10) |
| IDE Support | 4 | 5 (20) | 4 (16) | 3 (12) | 4 (16) | 3 (12) |
| Type Safety | 4 | 5 (20) | 3 (12) | 2 (8) | 5 (20) | 1 (4) |
| State Management | 4 | 4 (16) | 5 (20) | 4 (16) | 5 (20) | 1 (4) |
| Multi-Cloud | 2 | 1 (2) | 5 (10) | 1 (2) | 5 (10) | 1 (2) |
| Community/Docs | 4 | 4 (16) | 5 (20) | 4 (16) | 3 (12) | 4 (16) |
| **Total** | **32** | **140** | **135** | **102** | **135** | **89** |

### Scoring Guide
- **Weight**: 1 (Nice to have) → 5 (Critical)
- **Score**: 1 (Poor) → 5 (Excellent)

## Decision

**Azure Bicep** as primary IaC tool.

Consider **Terraform** if multi-cloud requirements emerge.

## Rationale

Bicep scored highest for Azure-focused deployments:

1. **First-party Azure support**: Same-day feature support, no provider lag.

2. **Clean syntax**: Dramatically simpler than ARM JSON while compiling to ARM.

3. **Excellent type safety**: IntelliSense, compile-time validation, and clear error messages.

4. **Native modules**: Built-in module system without registry complexity.

5. **Zero state management**: Uses Azure Resource Manager for state, no external backend needed.

### Bicep vs Terraform Decision Tree

| Question | If Yes | If No |
|----------|--------|-------|
| Is multi-cloud required? | Terraform | Continue to next question |
| Is team familiar with Terraform? | Terraform (leverage expertise) | Bicep (lower learning curve) |

## Consequences

### Positive

- Cleaner, more readable infrastructure code
- Compile-time validation catches errors early
- Excellent VS Code extension with IntelliSense
- No external state file to manage
- Direct ARM template compatibility
- Native Azure resource support

### Negative

- Azure-only (no multi-cloud)
- Smaller community than Terraform
- Limited third-party module ecosystem
- What-if deployment has limitations
- Less mature than ARM for edge cases

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Multi-cloud requirement | Low | High | Design modules for easy Terraform port |
| Missing resource support | Low | Medium | Fall back to ARM deployment resource |
| Team prefers Terraform | Medium | Low | Provide training, highlight benefits |
| Breaking changes | Low | Medium | Pin Bicep CLI version in CI/CD |

## Implementation Notes

### Project Structure

| Directory | Purpose |
|-----------|---------|
| `infra/main.bicep` | Orchestrator template |
| `infra/parameters/*.bicepparam` | Environment-specific parameters (dev, staging, prod) |
| `infra/modules/` | Reusable module library |

### Module Conventions

| Convention | Description |
|------------|-------------|
| Standard parameters | `name`, `location`, `tags` on all modules |
| Standard outputs | `resourceId`, `resourceName` for chaining |
| Decorator usage | `@description`, `@allowed`, `@minLength` for validation |

### Deployment Operations

| Operation | Purpose |
|-----------|---------|
| Validate | Compile Bicep to ARM, check syntax |
| What-if | Preview changes before deployment |
| Deploy | Create or update resources |

See `infra/` directory for the actual implementation.

## Terraform Parallel Modules

For teams requiring multi-cloud, maintain parallel Terraform modules:

| Bicep Module | Terraform Equivalent |
|--------------|---------------------|
| `modules/vnet/` | `terraform/modules/network/` |
| `modules/postgres/` | `terraform/modules/database/` |
| `modules/key-vault/` | `terraform/modules/secrets/` |
| `modules/container-registry/` | `terraform/modules/registry/` |
| `modules/log-analytics/` | `terraform/modules/monitoring/` |

### Multi-Cloud Provider Mapping

| Azure Resource | AWS Equivalent | GCP Equivalent |
|----------------|----------------|----------------|
| VNet | VPC | VPC |
| App Service | Elastic Beanstalk | App Engine |
| Container Apps | ECS/Fargate | Cloud Run |
| PostgreSQL Flexible | RDS PostgreSQL | Cloud SQL |
| Key Vault | Secrets Manager | Secret Manager |
| Storage Account | S3 | Cloud Storage |

## Deployment Strategies

### Blue-Green Deployment

| Phase | Action |
|-------|--------|
| 1. Deploy Green | Create new environment alongside Blue |
| 2. Test Green | Validate new deployment |
| 3. Switch Traffic | Update DNS/load balancer to Green |
| 4. Monitor | Watch for issues |
| 5. Decommission Blue | Remove old environment after validation |

### Canary Deployment

| Phase | Traffic Split |
|-------|---------------|
| Initial | 100% to current, 0% to canary |
| Phase 1 | 95% current, 5% canary |
| Phase 2 | 80% current, 20% canary |
| Phase 3 | 50% current, 50% canary |
| Complete | 0% current, 100% new |

### Rollback Strategies

| Strategy | RTO | Complexity |
|----------|-----|------------|
| Revert commit + redeploy | 5-15 min | Low |
| Blue-green switch back | 1-2 min | Medium |
| Database point-in-time restore | 15-60 min | High |
| Full environment rebuild | 30-120 min | High |

## Cost Considerations

### Deployment Costs

| Factor | Impact | Mitigation |
|--------|--------|------------|
| Duplicate resources (blue-green) | +100% during deployment | Short deployment window |
| Log retention | Ongoing | Set appropriate retention |
| Backup storage | Ongoing | Lifecycle policies |
| Idle dev environments | Significant | Scheduled start/stop |

### Cost Optimization Flags

| Parameter | Purpose |
|-----------|---------|
| `deployToProduction` | Skip expensive resources in dev |
| `enableHighAvailability` | Zone redundancy only in prod |
| `skuTier` | Burstable in dev, General in prod |

## GitOps Workflow

| Component | Tool | Purpose |
|-----------|------|---------|
| Source of truth | Git repository | Version control |
| Change detection | GitHub Actions / ADO | Trigger on commit |
| Validation | `az bicep build` | Syntax check |
| Preview | `az deployment what-if` | Change preview |
| Apply | `az deployment create` | Actual deployment |
| Drift detection | Scheduled workflow | Detect manual changes |

## References

- [Azure Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Playground](https://aka.ms/bicepdemo)
- [Bicep vs Terraform](https://docs.microsoft.com/azure/developer/terraform/comparing-terraform-and-bicep)
- [ARM Template Reference](https://docs.microsoft.com/azure/templates/)
