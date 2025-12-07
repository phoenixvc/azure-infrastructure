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

## References

- [Azure Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Playground](https://aka.ms/bicepdemo)
- [Bicep vs Terraform](https://docs.microsoft.com/azure/developer/terraform/comparing-terraform-and-bicep)
- [ARM Template Reference](https://docs.microsoft.com/azure/templates/)
