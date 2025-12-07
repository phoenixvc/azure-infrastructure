# .NET Reference Implementation

ASP.NET Core 8 reference implementation parallel to the Python FastAPI app.

## Features

- **ASP.NET Core 8** with minimal hosting model
- **Entity Framework Core** with PostgreSQL
- **OpenTelemetry** integration with Azure Monitor
- **Polly** for resilience (retry, circuit breaker, timeout)
- **Rate limiting** with AspNetCoreRateLimit
- **Health checks** for Kubernetes/Azure probes
- **Swagger/OpenAPI** documentation

## Project Structure

```
src/dotnet-api/
├── Controllers/         # API endpoints
│   ├── ItemsController.cs
│   └── HealthController.cs
├── Models/             # Domain entities and DTOs
│   └── Item.cs
├── Abstractions/       # Interfaces for dependency injection
│   ├── IRepository.cs
│   ├── ICacheProvider.cs
│   ├── IMessagePublisher.cs
│   └── IStorageProvider.cs
├── Services/           # Implementations
│   ├── InMemoryRepository.cs
│   ├── InMemoryCacheProvider.cs
│   ├── InMemoryMessagePublisher.cs
│   └── InMemoryStorageProvider.cs
├── Middleware/         # Custom middleware
│   └── ExceptionHandlingMiddleware.cs
├── Extensions/         # DI extensions
│   └── ServiceCollectionExtensions.cs
├── Program.cs          # Entry point
└── appsettings.json    # Configuration
```

## Getting Started

### Prerequisites

- .NET 8 SDK
- Docker (optional, for PostgreSQL/Redis)

### Run Locally

```bash
cd src/dotnet-api
dotnet restore
dotnet run
```

The API will be available at:
- API: http://localhost:5000
- Swagger: http://localhost:5000/swagger
- Health: http://localhost:5000/health

### With Docker

```bash
docker build -t azure-infrastructure-api .
docker run -p 5000:80 azure-infrastructure-api
```

## Configuration

Environment variables or appsettings.json:

| Variable | Description |
|----------|-------------|
| `ConnectionStrings__Database` | PostgreSQL connection string |
| `ConnectionStrings__Redis` | Redis connection string |
| `Azure__KeyVaultUrl` | Key Vault URL |
| `Azure__StorageConnectionString` | Blob Storage connection |
| `Azure__ServiceBusConnectionString` | Service Bus connection |
| `Azure__ApplicationInsightsConnectionString` | App Insights connection |

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API information |
| GET | `/health` | Health check |
| GET | `/health/live` | Liveness probe |
| GET | `/health/ready` | Readiness probe |
| GET | `/api/v1/items` | List items (paginated) |
| GET | `/api/v1/items/{id}` | Get item by ID |
| POST | `/api/v1/items` | Create item |
| PUT | `/api/v1/items/{id}` | Update item |
| DELETE | `/api/v1/items/{id}` | Delete item |

## Resilience Patterns

### Retry Policy
- 3 retries with exponential backoff (2s, 4s, 8s)
- Handles transient HTTP errors

### Circuit Breaker
- Opens after 5 consecutive failures
- Stays open for 30 seconds

### Timeout
- Default 30 second timeout on HTTP calls

## Testing

```bash
dotnet test
```

## Azure Deployment

Deploy using the Bicep modules:

```bash
az deployment group create \
  --resource-group myapp-rg \
  --template-file infra/modules/container-apps/main.bicep \
  --parameters appName=dotnet-api containerImage=myacr.azurecr.io/dotnet-api:latest
```
