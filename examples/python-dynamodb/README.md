# Python + DynamoDB Example

Serverless-ready Python API with DynamoDB-style storage.

## Stack
- **API**: FastAPI (Python 3.11+)
- **Database**: Azure Cosmos DB (Table API / DynamoDB-compatible)
- **SDK**: Boto3 / Azure SDK
- **Validation**: Pydantic

## Setup

```bash
# Replace src/api with DynamoDB implementation
cp -r examples/python-dynamodb/api src/api

# Install dependencies
cd src/api
pip install -r requirements.txt

# Run locally with local DynamoDB
docker run -p 8000:8000 amazon/dynamodb-local

# Run API
uvicorn main:app --reload --port 8001
```

## Features
- Serverless-optimized
- Single-table design patterns
- Auto-scaling storage
- Low-latency reads
- Global distribution ready
- Pay-per-request pricing

## Project Structure
```
api/
├── app/
│   ├── models/
│   ├── repositories/
│   ├── services/
│   └── routes/
├── scripts/
│   └── create_tables.py
├── requirements.txt
└── main.py
```

## Use Cases
- Serverless applications
- Variable/unpredictable traffic
- Simple key-value access patterns
- Global applications
- Event-driven architectures

## Configuration
Update `infra/parameters/dev.bicepparam`:
```bicep
databaseType: 'cosmosdb-table'
cosmosDbApiType: 'Table'
enableServerless: true
```

## Single-Table Design
```python
# Example entity types in one table
PK              SK              Data
USER#123        PROFILE         {name, email}
USER#123        ORDER#456       {total, status}
USER#123        ORDER#789       {total, status}
PRODUCT#ABC     METADATA        {name, price}
```

## Local Development
```bash
# Start local DynamoDB
docker-compose up dynamodb-local

# Create tables
python scripts/create_tables.py

# Run API
uvicorn main:app --reload
```
