# Java Spring Boot + MySQL Example

Enterprise Java API with Spring Boot and MySQL.

## Stack
- **API**: Spring Boot 3.2+
- **Database**: MySQL 8.0 (Azure Database for MySQL)
- **ORM**: Spring Data JPA / Hibernate
- **Build**: Maven / Gradle
- **Language**: Java 21

## Setup

```bash
# Replace src/api with Spring Boot implementation
cp -r examples/spring-mysql/api src/api

# Build and run with Maven
cd src/api
./mvnw spring-boot:run

# Or with Gradle
./gradlew bootRun
```

## Features
- Production-ready defaults
- Auto-configuration
- Actuator health endpoints
- Spring Security integration
- Flyway migrations
- OpenAPI/Swagger UI

## Project Structure
```
api/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/
│   │   │       ├── controller/
│   │   │       ├── service/
│   │   │       ├── repository/
│   │   │       ├── model/
│   │   │       └── Application.java
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/
│   └── test/
├── pom.xml
└── Dockerfile
```

## Use Cases
- Large enterprise applications
- Complex transactional systems
- Teams with Java expertise
- Microservices architecture
- Integration with existing Java systems

## Configuration
Update `infra/parameters/dev.bicepparam`:
```bicep
runtime: 'java'
javaVersion: '21'
databaseType: 'mysql'
mysqlVersion: '8.0'
```

## Application Properties
```yaml
# application.yml
spring:
  datasource:
    url: jdbc:mysql://${DB_HOST}:3306/${DB_NAME}
    username: ${DB_USER}
    password: ${DB_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
```

## Build Commands
```bash
# Build
./mvnw clean package

# Run tests
./mvnw test

# Build Docker image
./mvnw spring-boot:build-image
```
