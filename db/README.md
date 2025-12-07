# Database

Database migrations and seed data.

---

## Running Migrations

```bash
# Connect to database
psql -h nl-dev-rooivalk-db-euw.postgres.database.azure.com \
   -U dbadmin \
   -d rooivalk_dev

# Run migration
\i db/migrations/001_initial_schema.sql
```

---

## Seeding Data

```bash
psql -h localhost -U postgres -d rooivalk_dev -f db/seeds/dev_data.sql
```

---

## Best Practices

- Always use migrations (never manual schema changes)
- Test migrations on dev before prod
- Version control all migrations
