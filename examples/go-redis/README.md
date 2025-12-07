# Go + Redis Example

High-performance API with Go and Redis caching.

## Stack
- **API**: Gin / Echo (Go 1.21+)
- **Cache**: Redis (Azure Cache for Redis)
- **Database**: PostgreSQL (optional)
- **Validation**: go-playground/validator

## Setup

```bash
# Replace src/api with Go implementation
cp -r examples/go-redis/api src/api

# Download dependencies
cd src/api
go mod download

# Run
go run main.go
```

## Features
- Extremely fast performance
- Built-in concurrency
- Small memory footprint
- Single binary deployment
- Redis session/cache management
- Graceful shutdown

## Project Structure
```
api/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── handlers/
│   ├── services/
│   ├── repository/
│   └── middleware/
├── pkg/
│   ├── redis/
│   └── config/
├── go.mod
└── go.sum
```

## Use Cases
- High-throughput APIs
- Microservices
- Real-time systems
- CLI tools
- Performance-critical applications

## Configuration
Update `infra/parameters/dev.bicepparam`:
```bicep
runtime: 'go'
cacheType: 'redis'
redisSku: 'Basic'
```

## Environment Variables
```bash
PORT=8080
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=
GIN_MODE=debug
```

## Build
```bash
# Development
go run cmd/server/main.go

# Production build
go build -o api cmd/server/main.go
./api
```
