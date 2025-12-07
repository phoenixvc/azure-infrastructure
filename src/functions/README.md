# Azure Functions Template

Python Azure Functions template for event-driven processing.

---

## Structure

```
src/functions/
├── function_app.py          # Function definitions
├── host.json                # Function host configuration
├── local.settings.json      # Local development settings
├── requirements.txt
└── README.md
```

---

## Local Development

```bash
# Install Azure Functions Core Tools
# https://learn.microsoft.com/azure/azure-functions/functions-run-local

# Install dependencies
pip install -r requirements.txt

# Run locally
func start
```

---

## Function Types

### HTTP Trigger
```python
@app.route(route="hello")
def hello(req: func.HttpRequest) -> func.HttpResponse:
  return func.HttpResponse("Hello, World!")
```

### Timer Trigger
```python
@app.schedule(schedule="0 */5 * * * *", arg_name="timer")
def scheduled_job(timer: func.TimerRequest) -> None:
  logging.info("Timer trigger executed")
```

### Blob Trigger
```python
@app.blob_trigger(arg_name="blob", path="uploads/{name}", connection="AzureWebJobsStorage")
def process_blob(blob: func.InputStream):
  logging.info(f"Processing blob: {blob.name}")
```

---

## Azure Deployment

```bash
# Deploy to Function App
func azure functionapp publish nl-prod-rooivalk-func-euw
```

---

## Environment Variables

Configure in Azure Portal or via CLI:

```bash
az functionapp config appsettings set \
--name nl-prod-rooivalk-func-euw \
--resource-group nl-prod-rooivalk-rg-euw \
--settings "DATABASE_URL=<connection-string>"
```
