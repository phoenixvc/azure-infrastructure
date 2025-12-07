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

1. **Best-in-class async support**: Fastest drivers across all major languages (asyncpg, Npgsql, node-postgres).

2. **Open source portability**: No vendor lock-in; can migrate to any PostgreSQL-compatible service or self-hosted solution.

3. **Cost efficiency**: Flexible Server offers burstable compute tiers ideal for variable workloads, with the ability to stop/start for development environments.

4. **Superior JSON support**: Native JSONB type with indexing for semi-structured data, bridging relational and document stores.

5. **Mature ecosystem**: Extensive tooling, extensions (PostGIS, pg_trgm), and community support.

## Multi-Language Driver Support

| Language | Recommended Driver | Async Support | Connection Pooling |
|----------|-------------------|---------------|-------------------|
| Python | asyncpg + SQLAlchemy | Native async | Built-in |
| .NET | Npgsql + EF Core | Native async | Built-in |
| Node.js | node-postgres (pg) | Promises/async | pg-pool |
| Go | pgx | Context-based | pgxpool |
| Java | JDBC + HikariCP | Reactive (R2DBC) | HikariCP |
| Rust | sqlx | Native async | Built-in |

## Cost Estimation

### Azure PostgreSQL Flexible Server Pricing

| Tier | vCores | Memory | Storage | Monthly Cost (Est.) |
|------|--------|--------|---------|---------------------|
| Burstable B1ms | 1 | 2 GB | 32 GB | ~$15-25 |
| Burstable B2s | 2 | 4 GB | 64 GB | ~$30-50 |
| General Purpose D2s | 2 | 8 GB | 128 GB | ~$100-150 |
| General Purpose D4s | 4 | 16 GB | 256 GB | ~$200-300 |
| Memory Optimized E4s | 4 | 32 GB | 512 GB | ~$350-500 |

*Costs vary by region; includes compute + storage + backup*

### Cost Optimization Strategies

| Strategy | Savings | Trade-off |
|----------|---------|-----------|
| Stop dev instances | 60-80% | Manual restart needed |
| Reserved capacity (1yr) | 30-40% | Commitment required |
| Burstable tiers | 50-70% | Limited sustained performance |
| Read replicas | N/A | Offload read traffic |
| Connection pooling | Indirect | Fewer connections = smaller tier |

## Multi-Cloud Alternatives

| Cloud | Managed PostgreSQL | Key Differences |
|-------|-------------------|-----------------|
| Azure | Flexible Server | Best M365/Entra integration |
| AWS | RDS / Aurora PostgreSQL | Aurora offers serverless v2 |
| GCP | Cloud SQL / AlloyDB | AlloyDB for high performance |
| Self-hosted | Kubernetes + CloudNativePG | Full control, more ops burden |

### Terraform Multi-Cloud Example

| Provider | Resource Type |
|----------|---------------|
| Azure | `azurerm_postgresql_flexible_server` |
| AWS | `aws_db_instance` (engine=postgres) |
| GCP | `google_sql_database_instance` |

## Disaster Recovery

### High Availability Options

| Configuration | RTO | RPO | Cost Impact |
|---------------|-----|-----|-------------|
| Single zone | Hours | Up to 24h | Baseline |
| Zone redundant HA | Minutes | Near zero | +25-50% |
| Geo-replica (read) | Minutes | Minutes | +100% |
| Geo-restore | Hours | Hours | Backup cost only |

### Backup Strategy

| Backup Type | Retention | Recovery |
|-------------|-----------|----------|
| Automated daily | 7-35 days | Point-in-time restore |
| Geo-redundant backup | 7-35 days | Cross-region restore |
| Manual export | Unlimited | Full database restore |
| Logical replication | Real-time | Continuous sync |

### DR Runbook Summary

| Scenario | Action | Recovery Time |
|----------|--------|---------------|
| Zone failure | Automatic failover (if HA enabled) | 1-2 minutes |
| Region failure | Promote geo-replica or geo-restore | 15-60 minutes |
| Data corruption | Point-in-time restore | 5-30 minutes |
| Accidental deletion | Point-in-time restore | 5-30 minutes |

## Data Migration Patterns

| Migration Type | Tool | Use Case |
|----------------|------|----------|
| Schema-only | pg_dump --schema-only | Initial setup |
| Full export/import | pg_dump / pg_restore | Small databases (<100GB) |
| Continuous sync | Azure DMS | Minimal downtime |
| Logical replication | Native PostgreSQL | Zero downtime |
| Change data capture | Debezium | Event-driven migration |

### Migration Checklist

| Step | Description |
|------|-------------|
| 1. Assess | Inventory schemas, size, dependencies |
| 2. Test | Run migration in non-prod environment |
| 3. Validate | Compare row counts, checksums |
| 4. Cutover | Switch connection strings |
| 5. Verify | Run application smoke tests |
| 6. Cleanup | Decommission old database |

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
