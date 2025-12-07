# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records for the Azure Infrastructure project. ADRs document significant technical decisions made during the project, including context, alternatives considered, and rationale.

## Index

| ADR | Title | Status | Category |
|-----|-------|--------|----------|
| [ADR-001](001-database-selection.md) | Database Selection | Accepted | Data |
| [ADR-002](002-caching-strategy.md) | Caching Strategy | Accepted | Data |
| [ADR-003](003-messaging-infrastructure.md) | Messaging Infrastructure | Accepted | Integration |
| [ADR-004](004-authentication-approach.md) | Authentication Approach | Accepted | Security |
| [ADR-005](005-infrastructure-as-code.md) | Infrastructure as Code Tooling | Accepted | DevOps |
| [ADR-006](006-api-framework.md) | API Framework Selection | Accepted | Application |
| [ADR-007](007-monitoring-observability.md) | Monitoring & Observability | Accepted | Operations |
| [ADR-008](008-ai-integration.md) | AI Integration Strategy | Accepted | Application |
| [ADR-009](009-container-strategy.md) | Container & Compute Strategy | Accepted | Infrastructure |
| [ADR-010](010-storage-strategy.md) | Storage Strategy | Accepted | Data |
| [ADR-011](011-networking-security.md) | Networking & Security | Accepted | Security |
| [ADR-012](012-cicd-pipeline.md) | CI/CD Pipeline Strategy | Accepted | DevOps |
| [ADR-013](013-secret-management.md) | Secret Management | Accepted | Security |
| [ADR-014](014-programming-language.md) | Programming Language & Runtime | Accepted | Foundation |
| [ADR-015](015-mobile-development.md) | Mobile Development Strategy | Accepted | Client |
| [ADR-016](016-cloud-platform-comparison.md) | Cloud Platform Comparison & SWOT | Accepted | Strategic |

## Categories

### Strategic
- Cloud Platform Comparison (Azure vs AWS vs GCP)
- Project SWOT Analysis & Retrospective

### Foundation
- Programming Language & Runtime Selection (multi-language evaluation)
- API Framework Selection (language-specific frameworks)

### Client Layer
- Mobile Development (Flutter, React Native, Native)

### Application Layer
- AI Integration (Azure OpenAI, AI Foundry)

### Data Layer
- Database (PostgreSQL Flexible Server)
- Caching (Azure Redis)
- Storage (Azure Blob Storage)

### Infrastructure Layer
- Compute (Azure Container Apps)
- IaC Tooling (Bicep)

### Integration Layer
- Messaging (Azure Service Bus)

### Security Layer
- Authentication (API Key + JWT)
- Networking (VNet, Private Endpoints)
- Secrets (Azure Key Vault)

### Operations Layer
- Monitoring (Azure Monitor + App Insights)
- CI/CD (GitHub Actions)

## ADR Template

New ADRs should follow the [template](template.md).

## Evaluation Methodology

Each ADR uses a weighted scoring system for alternatives:

- **Weight**: Importance of the criterion (1-5, where 5 is critical)
- **Score**: How well the option meets the criterion (1-5, where 5 is excellent)
- **Weighted Score**: Weight × Score

The option with the highest total weighted score is typically selected, though other factors (team expertise, existing infrastructure) may influence the final decision.

## Decision Guidelines

### When to Create an ADR

- Choosing between technologies or services
- Significant architectural changes
- Changes that are difficult to reverse
- Decisions affecting multiple teams

### When NOT to Create an ADR

- Implementation details
- Bug fixes
- Minor configuration changes
- Decisions that can be easily reversed

## Status Definitions

- **Proposed**: Under discussion
- **Accepted**: Decision made and implemented
- **Deprecated**: Superseded by a newer ADR
- **Rejected**: Considered but not adopted
