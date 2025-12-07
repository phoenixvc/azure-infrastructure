# ADR-014: Programming Language & Runtime Selection

## Status

Accepted

## Date

2025-12-07

## Context

This infrastructure toolkit needs to support application development across various scenarios. We need to evaluate programming languages and runtimes based on:
- Azure service integration depth
- Team productivity and hiring pool
- Performance characteristics
- Ecosystem maturity
- Long-term maintainability

This decision affects framework choices, tooling, and deployment strategies.

## Decision Drivers

- **Azure Integration**: SDK quality, first-party support
- **Performance**: Throughput, latency, resource efficiency
- **Developer Productivity**: Time to delivery, debugging experience
- **Ecosystem**: Libraries, frameworks, community
- **Hiring**: Talent availability and cost
- **Type Safety**: Compile-time error detection

## Considered Options

1. **Python** (FastAPI, Django, Flask)
2. **C# / .NET** (ASP.NET Core, Minimal APIs)
3. **TypeScript / Node.js** (NestJS, Express, Fastify)
4. **Go** (Gin, Echo, Chi)
5. **Java / Kotlin** (Spring Boot, Quarkus, Micronaut)
6. **Rust** (Actix, Axum)

## Evaluation Matrix

| Criterion | Weight | Python | .NET | Node.js | Go | Java/Kotlin | Rust |
|-----------|--------|--------|------|---------|-----|-------------|------|
| Azure SDK Quality | 5 | 4 (20) | 5 (25) | 4 (20) | 4 (20) | 4 (20) | 3 (15) |
| Azure Service Integration | 5 | 4 (20) | 5 (25) | 4 (20) | 4 (20) | 4 (20) | 3 (15) |
| Raw Performance | 4 | 2 (8) | 5 (20) | 3 (12) | 5 (20) | 4 (16) | 5 (20) |
| Async Performance | 4 | 4 (16) | 5 (20) | 5 (20) | 5 (20) | 4 (16) | 5 (20) |
| Developer Productivity | 5 | 5 (25) | 4 (20) | 5 (25) | 3 (15) | 3 (15) | 2 (10) |
| Type Safety | 4 | 3 (12) | 5 (20) | 4 (16) | 5 (20) | 5 (20) | 5 (20) |
| Learning Curve | 4 | 5 (20) | 3 (12) | 4 (16) | 3 (12) | 2 (8) | 1 (4) |
| Hiring Pool | 4 | 5 (20) | 4 (16) | 5 (20) | 3 (12) | 4 (16) | 2 (8) |
| Container Size | 3 | 3 (9) | 4 (12) | 3 (9) | 5 (15) | 2 (6) | 5 (15) |
| Startup Time | 3 | 4 (12) | 4 (12) | 4 (12) | 5 (15) | 2 (6) | 5 (15) |
| AI/ML Integration | 4 | 5 (20) | 3 (12) | 3 (12) | 2 (8) | 3 (12) | 2 (8) |
| **Total** | **45** | **182** | **194** | **182** | **177** | **155** | **150** |

## Decision

**Tiered language recommendation based on use case**:

| Use Case | Primary | Alternative | Rationale |
|----------|---------|-------------|-----------|
| Enterprise APIs | .NET | Java/Kotlin | Best Azure integration, performance |
| Rapid Prototyping | Python | Node.js | Fastest time-to-market |
| AI/ML Workloads | Python | .NET (ML.NET) | Ecosystem dominance |
| High-Performance APIs | .NET | Go | Raw throughput, low latency |
| Serverless Functions | .NET, Python | Node.js | Cold start, execution time |
| CLI Tools | Go | .NET, Rust | Single binary, fast startup |
| Infrastructure Automation | Python | Go | Tooling ecosystem |
| Frontend/Full-stack | TypeScript | .NET (Blazor) | React/Vue ecosystem |

## Rationale by Language

### .NET (C#) - Highest Score: 194

**Strengths**:
- First-party Azure support (Microsoft ecosystem)
- Excellent async/await performance
- Strong typing with modern C# features
- Native AOT compilation for fast startup
- Minimal APIs for lightweight services

**Best for**: Enterprise applications, high-performance APIs, Azure-native solutions

### Python - Score: 182

**Strengths**:
- Dominant in AI/ML space
- Fastest prototyping speed
- Large talent pool
- Excellent for scripting and automation
- FastAPI provides modern async support

**Best for**: AI/ML workloads, data processing, rapid prototyping, automation

### TypeScript/Node.js - Score: 182

**Strengths**:
- Full-stack JavaScript ecosystem
- Excellent async I/O performance
- Huge npm ecosystem
- Same language for frontend/backend
- Strong typing with TypeScript

**Best for**: Full-stack applications, real-time services, BFF (Backend for Frontend)

### Go - Score: 177

**Strengths**:
- Excellent raw performance
- Fast compilation, tiny binaries
- Built-in concurrency (goroutines)
- Simple deployment (single binary)
- Great for cloud-native tools

**Best for**: Infrastructure tools, CLIs, high-concurrency services, Kubernetes operators

### Java/Kotlin - Score: 155

**Strengths**:
- Mature enterprise ecosystem
- Strong typing and tooling
- GraalVM for native compilation
- Kotlin provides modern syntax
- Spring Boot ecosystem

**Best for**: Enterprise backends, legacy integration, teams with Java expertise

### Rust - Score: 150

**Strengths**:
- Maximum performance and safety
- Zero-cost abstractions
- Memory safety without GC
- WebAssembly compilation
- Growing Azure SDK support

**Best for**: Performance-critical systems, WebAssembly, when safety is paramount

## Azure Service Considerations

| Service | .NET | Python | Node.js | Go | Java |
|---------|------|--------|---------|-----|------|
| Functions (Cold Start) | Fast | Medium | Fast | N/A* | Slow |
| App Service | Excellent | Good | Good | Good | Good |
| Container Apps | Excellent | Good | Good | Excellent | Good |
| AKS | Good | Good | Good | Excellent | Good |
| Azure SDK Coverage | 100% | 95% | 90% | 85% | 90% |

*Go not officially supported in Azure Functions

## Framework Recommendations by Language

| Language | API Framework | When to Use |
|----------|---------------|-------------|
| .NET | ASP.NET Core Minimal APIs | High-performance, enterprise |
| .NET | ASP.NET Core MVC | Full-featured web apps |
| Python | FastAPI | Modern async APIs |
| Python | Django | Full-featured web apps |
| Node.js | NestJS | Enterprise Node.js |
| Node.js | Fastify | High-performance APIs |
| Go | Chi or Echo | Lightweight APIs |
| Java | Spring Boot | Enterprise Java |
| Kotlin | Ktor | Lightweight Kotlin |

## Consequences

### Positive

- Clear guidance for technology selection
- Flexibility to choose based on use case
- Leverages each language's strengths
- Supports polyglot architecture where beneficial

### Negative

- Multiple languages increase operational complexity
- Cross-team knowledge sharing challenges
- Different deployment patterns per language
- Varied tooling and CI/CD configurations

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Language fragmentation | Medium | Medium | Establish primary language per team |
| Skill gaps | Medium | Medium | Training, hiring strategy |
| Inconsistent patterns | Medium | Low | Shared architecture guidelines |
| SDK feature parity | Low | Medium | Abstract provider interfaces |

## Recommendation for This Toolkit

This infrastructure toolkit provides:
- **Bicep modules**: Language-agnostic infrastructure
- **Reference implementations**: Python (included), .NET and Node.js (future)
- **Abstractions**: Language-agnostic patterns (repository, cache, messaging)

Teams should select language based on:
1. Existing team expertise
2. Specific workload requirements
3. Azure service integration needs
4. Performance requirements

## Testing Framework Recommendations

| Language | Unit Testing | Integration | E2E | Mocking |
|----------|--------------|-------------|-----|---------|
| Python | pytest | pytest-asyncio | pytest | unittest.mock |
| .NET | xUnit, NUnit | WebApplicationFactory | Playwright | Moq, NSubstitute |
| Node.js | Jest, Vitest | supertest | Playwright | jest.mock |
| Go | testing | testify | go-playwright | gomock |
| Java | JUnit 5 | Spring Test | Selenium | Mockito |
| Rust | cargo test | - | - | mockall |

## Observability Libraries

| Language | Traces | Metrics | Logs |
|----------|--------|---------|------|
| Python | opentelemetry-python | prometheus-client | structlog |
| .NET | OpenTelemetry.NET | App Metrics | Serilog |
| Node.js | @opentelemetry/node | prom-client | pino |
| Go | go.opentelemetry.io | prometheus/client | zerolog |
| Java | opentelemetry-java | micrometer | logback |

## Resilience Libraries

| Language | Circuit Breaker | Retry | Timeout |
|----------|-----------------|-------|---------|
| Python | pybreaker, tenacity | tenacity | asyncio.timeout |
| .NET | Polly | Polly | Polly |
| Node.js | opossum, cockatiel | async-retry | p-timeout |
| Go | gobreaker | avast/retry-go | context |
| Java | resilience4j | resilience4j | resilience4j |

## Cost Considerations by Language

### Developer Costs (Annual Salary Range, US)

| Language | Junior | Mid | Senior | Principal |
|----------|--------|-----|--------|-----------|
| Python | $70-90K | $100-130K | $140-170K | $180-220K |
| .NET | $70-90K | $100-130K | $140-180K | $180-230K |
| Node.js | $70-90K | $100-130K | $140-170K | $170-210K |
| Go | $80-100K | $110-150K | $160-200K | $200-250K |
| Java | $70-90K | $100-130K | $140-180K | $180-230K |
| Rust | $90-120K | $130-170K | $180-220K | $220-280K |

### Compute Cost Impact

| Language | Memory Efficiency | CPU Efficiency | Cold Start |
|----------|-------------------|----------------|------------|
| Go | Excellent | Excellent | Excellent |
| Rust | Excellent | Excellent | Excellent |
| .NET AOT | Good | Excellent | Good |
| .NET JIT | Fair | Excellent | Fair |
| Node.js | Fair | Good | Good |
| Python | Fair | Fair | Good |
| Java | Poor | Good | Poor |

### Serverless Cost Multiplier

| Language | Relative Cost | Why |
|----------|---------------|-----|
| Go | 1.0x | Fastest, least memory |
| Rust | 1.0x | Similar to Go |
| .NET AOT | 1.2x | Slightly larger |
| Node.js | 1.5x | More memory needed |
| Python | 1.8x | Slower execution |
| Java | 2.5x | High memory, slow start |

## Package Manager & Build Tools

| Language | Package Manager | Build Tool | Lockfile |
|----------|-----------------|------------|----------|
| Python | pip, poetry | setuptools, hatch | requirements.txt, poetry.lock |
| .NET | NuGet | MSBuild, dotnet CLI | packages.lock.json |
| Node.js | npm, pnpm, yarn | esbuild, webpack | package-lock.json |
| Go | go mod | go build | go.sum |
| Java | Maven, Gradle | Maven, Gradle | pom.xml, gradle.lockfile |
| Rust | Cargo | Cargo | Cargo.lock |

## Container Image Sizes

| Language | Base Image | Minimal Size | Typical App |
|----------|------------|--------------|-------------|
| Go | scratch | 5-15 MB | 20-50 MB |
| Rust | scratch | 5-15 MB | 20-50 MB |
| .NET AOT | distroless | 30-50 MB | 50-100 MB |
| .NET | mcr.microsoft.com | 200-300 MB | 250-400 MB |
| Node.js | node:alpine | 100-150 MB | 200-400 MB |
| Python | python:slim | 100-150 MB | 200-500 MB |
| Java | eclipse-temurin | 300-500 MB | 400-800 MB |

## IDE & Tooling Support

| Language | Primary IDE | LSP Quality | Debugging |
|----------|-------------|-------------|-----------|
| Python | VS Code, PyCharm | Excellent (Pylance) | Excellent |
| .NET | Visual Studio, Rider | Excellent (OmniSharp) | Excellent |
| Node.js | VS Code | Excellent | Excellent |
| Go | VS Code, GoLand | Excellent (gopls) | Good |
| Java | IntelliJ, VS Code | Excellent | Excellent |
| Rust | VS Code, RustRover | Good (rust-analyzer) | Good |

## References

- Azure SDK documentation (all languages)
- TechEmpower Framework Benchmarks
- Stack Overflow Developer Survey
- Azure Functions language support matrix
- [OpenTelemetry](https://opentelemetry.io/)
- [Polly (.NET)](https://github.com/App-vNext/Polly)
- [Tenacity (Python)](https://github.com/jd/tenacity)
