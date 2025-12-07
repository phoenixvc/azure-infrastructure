# ADR-001: Database Selection

## Status

Accepted

## Date

2025-12-07

## Context

The application requires a persistent data store for structured data (items, users, orders). We need to select a database service that integrates well with Azure, supports our scalability requirements, and aligns with team expertise.

Key requirements:
- ACID compliance for transactional integrity
- High availability and disaster recovery
- Cost-effective for variable workloads
- Good tooling and ORM support
- Managed service to reduce operational overhead

## Decision Drivers

- **Azure Integration**: Native Azure service with VNet integration
- **Scalability**: Ability to scale from small workloads to enterprise
- **Cost**: Pay-per-use or predictable pricing models
- **Developer Experience**: ORM support, local development story
- **Operational Simplicity**: Managed service, automated backups

## Considered Options

1. **Azure Database for PostgreSQL Flexible Server**
2. **Azure SQL Database**
3. **Azure Cosmos DB (SQL API)**
4. **Azure Database for MySQL Flexible Server**

## Evaluation Matrix

| Criterion | Weight | PostgreSQL | Azure SQL | Cosmos DB | MySQL |
|-----------|--------|------------|-----------|-----------|-------|
| Azure Integration | 4 | 5 (20) | 5 (20) | 5 (20) | 5 (20) |
| Open Source / Portability | 4 | 5 (20) | 2 (8) | 2 (8) | 5 (20) |
| Cost Efficiency | 5 | 5 (25) | 3 (15) | 2 (10) | 5 (25) |
| Scalability | 4 | 4 (16) | 5 (20) | 5 (20) | 4 (16) |
| Developer Experience | 4 | 5 (20) | 4 (16) | 3 (12) | 4 (16) |
| JSON Support | 3 | 5 (15) | 4 (12) | 5 (15) | 3 (9) |
| Async Driver Support | 4 | 5 (20) | 4 (16) | 4 (16) | 4 (16) |
| Team Expertise | 3 | 4 (12) | 3 (9) | 2 (6) | 4 (12) |
| **Total** | **31** | **148** | **116** | **107** | **134** |

## Decision

**Azure Database for PostgreSQL Flexible Server**

## Rationale

PostgreSQL scored highest due to:

1. **Best-in-class async support**: `asyncpg` is the fastest PostgreSQL driver for Python, essential for async API architectures.

2. **Open source portability**: No vendor lock-in; can migrate to any PostgreSQL-compatible service or self-hosted solution.

3. **Cost efficiency**: Flexible Server offers burstable compute tiers ideal for variable workloads, with the ability to stop/start for development environments.

4. **Superior JSON support**: Native JSONB type with indexing for semi-structured data, bridging relational and document stores.

5. **Mature ecosystem**: Extensive tooling, extensions (PostGIS, pg_trgm), and community support.

## Consequences

### Positive

- Excellent SQLAlchemy async support via asyncpg driver
- Native VNet integration for security
- Built-in high availability with zone redundancy
- Automated backups with point-in-time restore
- Read replicas for scaling read workloads

### Negative

- Learning curve for teams unfamiliar with PostgreSQL
- Some Azure-specific features require PostgreSQL extensions
- Manual sharding for extreme horizontal scale (vs. Cosmos DB)

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Connection pool exhaustion | Medium | High | Use PgBouncer or connection pooling |
| Schema migration complexity | Low | Medium | Use Alembic with proper CI/CD |
| Regional availability | Low | High | Enable zone redundancy, geo-replicas |

## Abstraction Requirements

The codebase should implement a repository pattern to abstract database operations, enabling:
- Swapping database implementations without changing business logic
- Easier unit testing with mock repositories
- Potential future migration to different databases

## References

- Azure Database for PostgreSQL Flexible Server documentation
- asyncpg driver documentation
- SQLAlchemy async documentation
