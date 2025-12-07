# Flask + MongoDB Example

Alternative stack using Flask and MongoDB.

## Stack
- **API**: Flask (Python 3.11+)
- **Database**: MongoDB (Azure Cosmos DB)
- **ODM**: PyMongo
- **Validation**: Marshmallow

## Setup

```bash
# Replace src/api with Flask implementation
cp -r examples/flask-mongodb/api src/api

# Install dependencies
cd src/api
pip install -r requirements.txt

# Run
flask run
```

## Use Cases
- Document-heavy applications
- Flexible schema requirements
- Rapid prototyping
- Real-time analytics

## Configuration
Update `infra/parameters/dev.bicepparam`:
```bicep
databaseType: 'cosmosdb'
```
