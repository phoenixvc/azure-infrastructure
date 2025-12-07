# Node.js + PostgreSQL Example

Modern JavaScript/TypeScript API with PostgreSQL.

## Stack
- **API**: Express.js / Fastify (Node.js 20+)
- **Database**: PostgreSQL 15
- **ORM**: Prisma
- **Validation**: Zod
- **Language**: TypeScript

## Setup

```bash
# Replace src/api with Node.js implementation
cp -r examples/nodejs-postgres/api src/api

# Install dependencies
cd src/api
npm install

# Generate Prisma client
npx prisma generate

# Run migrations
npx prisma migrate dev

# Start development server
npm run dev
```

## Features
- Full TypeScript support
- Prisma ORM with type-safe queries
- Hot reload with nodemon
- ESLint + Prettier configured
- Jest for testing
- OpenAPI documentation

## Project Structure
```
api/
├── src/
│   ├── controllers/
│   ├── services/
│   ├── routes/
│   ├── middleware/
│   └── index.ts
├── prisma/
│   └── schema.prisma
├── tests/
└── package.json
```

## Use Cases
- Full-stack JavaScript teams
- Real-time applications (WebSocket support)
- Rapid prototyping
- Serverless deployments

## Configuration
Update `infra/parameters/dev.bicepparam`:
```bicep
runtime: 'node'
nodeVersion: '20-lts'
databaseType: 'postgresql'
```

## Scripts
- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run test` - Run tests
- `npm run lint` - Run linter
