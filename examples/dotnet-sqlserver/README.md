# .NET + SQL Server Example

Enterprise stack using .NET and SQL Server.

## Stack
- **API**: ASP.NET Core 8.0
- **Database**: Azure SQL Database
- **ORM**: Entity Framework Core
- **Auth**: ASP.NET Identity

## Setup

```bash
# Replace src/api with .NET implementation
cp -r examples/dotnet-sqlserver/api src/api

# Build and run
cd src/api
dotnet restore
dotnet run
```

## Features
- Minimal API design
- Built-in dependency injection
- Entity Framework migrations
- Swagger/OpenAPI support
- Azure AD integration ready

## Use Cases
- Enterprise applications
- Complex business logic
- Strong typing requirements
- Microsoft ecosystem integration

## Configuration
Update `infra/parameters/dev.bicepparam`:
```bicep
databaseType: 'sqlserver'
runtime: 'dotnet'
```
