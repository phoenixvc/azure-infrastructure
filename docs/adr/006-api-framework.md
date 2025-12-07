# ADR-006: API Framework Selection

## Status

Accepted

## Date

2025-12-07

## Context

We need to select API frameworks across supported languages that provide:
- High performance and scalability
- Automatic API documentation (OpenAPI)
- Strong typing and validation
- Azure service integration
- Developer productivity

This ADR evaluates frameworks across multiple languages. See ADR-014 for language selection guidance.

## Decision Drivers

- **Performance**: Request throughput, latency
- **Documentation**: OpenAPI/Swagger generation
- **Type Safety**: Request/response validation
- **Azure Integration**: SDK compatibility, deployment support
- **Ecosystem**: Middleware, extensions, community

## Frameworks by Language

### .NET Frameworks

| Framework | Use Case | OpenAPI | Performance |
|-----------|----------|---------|-------------|
| ASP.NET Core Minimal APIs | High-performance APIs | Native | Excellent |
| ASP.NET Core MVC | Full-featured web apps | Native | Excellent |
| FastEndpoints | REPR pattern APIs | Native | Excellent |

### Python Frameworks

| Framework | Use Case | OpenAPI | Performance |
|-----------|----------|---------|-------------|
| FastAPI | Modern async APIs | Native | Very Good |
| Django REST Framework | Full-featured APIs | Via drf-spectacular | Good |
| Flask + Flask-RESTx | Lightweight APIs | Native | Good |
| Litestar | High-performance async | Native | Excellent |

### Node.js/TypeScript Frameworks

| Framework | Use Case | OpenAPI | Performance |
|-----------|----------|---------|-------------|
| NestJS | Enterprise Node.js | Native | Good |
| Fastify | High-performance APIs | Via plugin | Excellent |
| Express + tsoa | Traditional REST | Via tsoa | Good |
| Hono | Edge/serverless | Via plugin | Excellent |

### Go Frameworks

| Framework | Use Case | OpenAPI | Performance |
|-----------|----------|---------|-------------|
| Chi | Lightweight routing | Via swag | Excellent |
| Echo | Full-featured | Via swag | Excellent |
| Gin | Popular, fast | Via gin-swagger | Excellent |
| Fiber | Express-like | Via swagger | Excellent |

### Java/Kotlin Frameworks

| Framework | Use Case | OpenAPI | Performance |
|-----------|----------|---------|-------------|
| Spring Boot | Enterprise Java | Native | Good |
| Quarkus | Cloud-native Java | Native | Excellent |
| Micronaut | Low-memory footprint | Native | Excellent |
| Ktor (Kotlin) | Lightweight Kotlin | Via plugin | Excellent |

## Cross-Language Evaluation

| Criterion | Weight | .NET Minimal | FastAPI | NestJS | Go Chi | Spring Boot |
|-----------|--------|--------------|---------|--------|--------|-------------|
| Raw Performance | 4 | 5 (20) | 3 (12) | 3 (12) | 5 (20) | 3 (12) |
| OpenAPI Native | 5 | 5 (25) | 5 (25) | 5 (25) | 3 (15) | 5 (25) |
| Type Safety | 5 | 5 (25) | 4 (20) | 5 (25) | 4 (20) | 5 (25) |
| Azure Integration | 4 | 5 (20) | 4 (16) | 4 (16) | 4 (16) | 4 (16) |
| Learning Curve | 4 | 4 (16) | 5 (20) | 3 (12) | 4 (16) | 2 (8) |
| Ecosystem | 4 | 5 (20) | 4 (16) | 5 (20) | 4 (16) | 5 (20) |
| **Total** | **26** | **126** | **109** | **110** | **103** | **106** |

## Recommended Frameworks by Use Case

| Use Case | Recommended | Alternative |
|----------|-------------|-------------|
| High-performance enterprise | ASP.NET Core Minimal | Go Chi/Echo |
| Rapid API development | FastAPI | NestJS |
| AI/ML APIs | FastAPI | Flask |
| Full-stack TypeScript | NestJS | Fastify |
| Microservices | Go Chi | ASP.NET Core |
| Serverless functions | ASP.NET Core | FastAPI |
| Legacy enterprise | Spring Boot | ASP.NET Core |

## Decision

**Framework selection based on language choice**:

| If Language | Then Framework | Rationale |
|-------------|----------------|-----------|
| .NET | ASP.NET Core Minimal APIs | Best performance, native Azure |
| Python | FastAPI | Modern async, auto-docs |
| Node.js | NestJS or Fastify | Enterprise (NestJS) or Performance (Fastify) |
| Go | Chi or Echo | Idiomatic Go, high performance |
| Java | Quarkus or Spring Boot | Cloud-native (Quarkus) or Enterprise (Spring) |
| Kotlin | Ktor | Native Kotlin, lightweight |

## Common Patterns Across Frameworks

Regardless of framework, implement:

| Pattern | Purpose |
|---------|---------|
| Repository | Database abstraction |
| Dependency Injection | Testability, loose coupling |
| Middleware Pipeline | Cross-cutting concerns |
| Request Validation | Input sanitization |
| Error Handling | Consistent error responses |
| Health Endpoints | Kubernetes/Azure probes |

## OpenAPI Considerations

| Requirement | .NET | Python | Node.js | Go |
|-------------|------|--------|---------|-----|
| Auto-generation | Native | FastAPI native | Decorators | Code comments |
| Schema validation | Native | Pydantic | class-validator | go-playground/validator |
| Client generation | NSwag | openapi-generator | openapi-generator | oapi-codegen |

## Consequences

### Positive

- Clear framework guidance per language
- Consistent patterns across implementations
- OpenAPI-first approach enables client generation
- Performance-appropriate choices

### Negative

- Different frameworks require different expertise
- Varied testing and deployment patterns
- Inconsistent middleware implementations

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Framework lock-in | Medium | Medium | Use standard patterns, abstract I/O |
| Version fragmentation | Medium | Low | Pin versions, regular updates |
| Performance gaps | Low | Medium | Benchmark critical paths |

## This Repository

This repository includes a Python (FastAPI) reference implementation. Future additions may include:
- .NET Minimal API reference
- Node.js/NestJS reference
- Go Chi reference

## References

- ASP.NET Core documentation
- FastAPI documentation
- NestJS documentation
- TechEmpower Framework Benchmarks
