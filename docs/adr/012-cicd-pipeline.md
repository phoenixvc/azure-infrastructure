# ADR-012: CI/CD Pipeline Strategy

## Status

Accepted

## Date

2025-12-07

## Context

The platform requires automated build, test, and deployment pipelines that:
- Support multiple environments (dev, staging, production)
- Enable infrastructure and application deployments
- Provide approval gates for production
- Integrate with Azure services
- Support both GitHub and Azure DevOps workflows

## Decision Drivers

- **Integration**: Azure service integration depth
- **Flexibility**: Support for various deployment patterns
- **Security**: Secret management, OIDC support
- **Cost**: Pricing for build minutes
- **Developer Experience**: Ease of use, documentation

## Considered Options

1. **GitHub Actions**
2. **Azure DevOps Pipelines**
3. **GitLab CI/CD**
4. **Jenkins**
5. **CircleCI**

## Evaluation Matrix

| Criterion | Weight | GitHub Actions | Azure DevOps | GitLab CI | Jenkins | CircleCI |
|-----------|--------|----------------|--------------|-----------|---------|----------|
| Azure Integration | 5 | 4 (20) | 5 (25) | 3 (15) | 3 (15) | 3 (15) |
| GitHub Integration | 5 | 5 (25) | 3 (15) | 3 (15) | 3 (15) | 4 (20) |
| OIDC Support | 4 | 5 (20) | 5 (20) | 4 (16) | 3 (12) | 4 (16) |
| Marketplace/Actions | 4 | 5 (20) | 4 (16) | 4 (16) | 5 (20) | 3 (12) |
| Self-hosted Runners | 3 | 5 (15) | 5 (15) | 5 (15) | 5 (15) | 3 (9) |
| Approval Gates | 4 | 4 (16) | 5 (20) | 4 (16) | 4 (16) | 3 (12) |
| Cost (Free Tier) | 3 | 4 (12) | 4 (12) | 4 (12) | 5 (15) | 3 (9) |
| Learning Curve | 3 | 5 (15) | 4 (12) | 4 (12) | 2 (6) | 4 (12) |
| **Total** | **31** | **143** | **135** | **117** | **114** | **105** |

## Decision

**GitHub Actions** as primary CI/CD platform with environment-specific configurations:

| Environment | Trigger | Approval | Deployment Target |
|-------------|---------|----------|-------------------|
| Development | Push to `main` | None | Dev subscription |
| Staging | Tag `v*-rc*` | None | Staging subscription |
| Production | Tag `v*` | Required | Production subscription |

Use **Azure DevOps** for organizations already invested in that ecosystem.

## Rationale

GitHub Actions selected because:

1. **Native GitHub integration**: PR checks, status checks, code owners integration
2. **OIDC with Azure**: Passwordless authentication using federated credentials
3. **Rich marketplace**: Pre-built actions for Bicep, Azure CLI, container operations
4. **Environments**: Built-in environment protection rules and secrets
5. **Matrix builds**: Parallel testing across configurations

## Pipeline Architecture

### Workflow Types

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| CI | Pull request | Build, test, lint, security scan |
| CD - Dev | Push to main | Deploy to development |
| CD - Staging | RC tag | Deploy to staging |
| CD - Prod | Release tag | Deploy to production with approval |
| Infrastructure | Infra changes | Bicep what-if and deploy |
| Scheduled | Cron | Security scans, dependency updates |

### Deployment Strategy

| Strategy | Use Case | Rollback |
|----------|----------|----------|
| Rolling | Standard deployments | Redeploy previous version |
| Blue-Green | Zero-downtime releases | Traffic shift |
| Canary | High-risk changes | Gradual rollout with monitoring |

### Quality Gates

| Stage | Checks |
|-------|--------|
| Build | Compile, lint, type check |
| Test | Unit tests, integration tests, coverage threshold |
| Security | Dependency scan, SAST, secret detection |
| Deploy | Smoke tests, health checks |
| Validation | E2E tests, performance baseline |

## Authentication Strategy

### OIDC Federated Credentials (Recommended)

- No secrets stored in GitHub
- Short-lived tokens from Azure AD
- Scoped to specific repository and environment
- Audit trail in Azure AD

### Service Principal (Alternative)

- For Azure DevOps or complex scenarios
- Secrets rotated via Key Vault
- Limited scope with RBAC

## Environment Configuration

| Environment | Subscription | Resource Naming | Scaling |
|-------------|--------------|-----------------|---------|
| Development | Non-prod | `{app}-dev-{region}` | Minimal |
| Staging | Non-prod | `{app}-stg-{region}` | Production-like |
| Production | Production | `{app}-prod-{region}` | Full scale |

## Consequences

### Positive

- Unified source control and CI/CD in GitHub
- OIDC eliminates long-lived credentials
- Environment protection rules enforce approvals
- Reusable workflows reduce duplication
- Native integration with GitHub security features

### Negative

- GitHub-hosted runners have time limits
- Complex workflows can be hard to debug
- YAML syntax learning curve
- Environment secrets require careful management

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Pipeline failures block deployments | Medium | High | Self-hosted runners, retry logic |
| Secret exposure | Low | Critical | OIDC, minimal secrets, audit logs |
| Deployment to wrong environment | Low | High | Environment protection, branch rules |
| Build time increases | Medium | Low | Caching, parallelization |

## Cost Estimation

### GitHub Actions Pricing

| Plan | Free Minutes | Cost per Minute |
|------|--------------|-----------------|
| Free | 2,000/mo | N/A |
| Team | 3,000/mo | $0.008 Linux |
| Enterprise | 50,000/mo | $0.008 Linux |
| Self-hosted | Unlimited | Infrastructure cost |

### Monthly Cost Scenarios

| Scenario | Builds/Day | Minutes/Build | Monthly Cost |
|----------|------------|---------------|--------------|
| Small project | 10 | 5 | Free tier |
| Medium project | 50 | 10 | ~$80 |
| Large project | 200 | 15 | ~$500 |
| Enterprise | 500 | 20 | ~$1,500+ |

### Cost Optimization Strategies

| Strategy | Savings | Implementation |
|----------|---------|----------------|
| Caching dependencies | 30-50% | actions/cache |
| Parallel jobs | 20-30% | Matrix builds |
| Self-hosted runners | 50-80% | EC2/VM |
| Skip unnecessary builds | 20% | Path filters |
| Smaller base images | 10-20% | Alpine, distroless |

## Multi-Cloud CI/CD Alternatives

### Platform Mapping

| GitHub Actions | Azure DevOps | GitLab CI | AWS | GCP |
|----------------|--------------|-----------|-----|-----|
| Workflows | Pipelines | .gitlab-ci.yml | CodePipeline | Cloud Build |
| Actions | Tasks | Scripts | CodeBuild | Build steps |
| Runners | Agents | Runners | CodeBuild | Cloud Build |
| Environments | Stages | Environments | Stages | - |
| Secrets | Variable Groups | Variables | Secrets Manager | Secret Manager |

### Multi-Cloud Deployment Support

| CI/CD Platform | Azure | AWS | GCP | Multi-Cloud |
|----------------|-------|-----|-----|-------------|
| GitHub Actions | Excellent | Excellent | Good | Yes |
| Azure DevOps | Native | Good | Fair | Yes |
| GitLab CI | Good | Good | Good | Yes |
| Jenkins | Good | Good | Good | Yes |
| ArgoCD | Good | Good | Good | Kubernetes-native |

### Cloud-Agnostic Tools

| Category | Tools | Purpose |
|----------|-------|---------|
| IaC Deployment | Terraform, Pulumi | Multi-cloud infra |
| Container Deployment | Helm, Kustomize | Kubernetes apps |
| GitOps | ArgoCD, Flux | Declarative deployments |
| Testing | Selenium, k6 | Cross-platform tests |
| Security | Trivy, Snyk | Universal scanning |

## Advanced Deployment Patterns

### Rollback Strategies

| Strategy | RTO | Complexity | Use Case |
|----------|-----|------------|----------|
| Redeploy previous | 5-15 min | Low | Standard apps |
| Blue-green switch | < 1 min | Medium | Zero-downtime |
| Database rollback | 15-60 min | High | Schema changes |
| Feature flag toggle | Instant | Low | Feature rollback |

### Progressive Delivery

| Stage | Traffic | Duration | Metrics to Watch |
|-------|---------|----------|------------------|
| Deploy | 0% | - | Build success |
| Smoke test | 0% | 5 min | Health checks |
| Canary | 5% | 30 min | Error rate, latency |
| Ramp up | 25% | 1 hour | Error rate, latency |
| Full rollout | 100% | - | All metrics |

### GitOps Workflow

| Component | Tool | Purpose |
|-----------|------|---------|
| Git repository | GitHub | Source of truth |
| CI pipeline | GitHub Actions | Build and test |
| CD controller | ArgoCD/Flux | Sync to cluster |
| Config repo | Separate repo | Environment configs |
| Secrets | Sealed Secrets | Encrypted in Git |

## Security Scanning Pipeline

### Scan Types

| Scan Type | Tool | Stage | Blocking |
|-----------|------|-------|----------|
| SAST | CodeQL, Semgrep | CI | Yes (high) |
| SCA | Dependabot, Snyk | CI | Yes (critical) |
| Container | Trivy, Defender | CI | Yes (critical) |
| Secrets | GitLeaks, TruffleHog | CI | Yes (all) |
| DAST | OWASP ZAP | Post-deploy | No |
| IaC | Checkov, tfsec | CI | Yes (high) |

### Security Gates

| Gate | Threshold | Action |
|------|-----------|--------|
| Critical vulnerabilities | 0 | Block |
| High vulnerabilities | < 5 | Block |
| Medium vulnerabilities | < 20 | Warn |
| Code coverage | > 80% | Block |
| Secrets detected | 0 | Block |

## Disaster Recovery

### Pipeline DR

| Scenario | Recovery | RTO |
|----------|----------|-----|
| GitHub outage | Azure DevOps backup | 1 hour |
| Runner failure | Self-hosted pool | 5 min |
| Secret compromise | Rotate via Key Vault | 15 min |
| Config corruption | Git revert | 5 min |

### Business Continuity

| Component | Primary | Backup |
|-----------|---------|--------|
| Source control | GitHub | Azure Repos mirror |
| CI/CD | GitHub Actions | Azure DevOps |
| Artifact storage | GitHub Packages | ACR |
| Secrets | GitHub Secrets | Key Vault |

## References

- GitHub Actions documentation
- Azure OIDC federation setup guide
- GitHub Environments and deployment protection
- Azure DevOps vs GitHub Actions comparison
- [GitHub Actions Pricing](https://github.com/pricing)
- [ArgoCD](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://opengitops.dev/)
