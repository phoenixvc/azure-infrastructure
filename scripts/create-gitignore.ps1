# Create .gitignore

$gitignore = @"
# Python
__pycache__/
*.py[cod]
venv/
*.egg-info/

# Node
node_modules/
dist/
.next/

# Environment
.env
*.env

# IDEs
.vscode/
.idea/

# OS
.DS_Store

# Azure
local.settings.json

# Database
*.db
*.sqlite

# Logs
*.log
"@

$gitignore | Out-File -FilePath ".gitignore" -Encoding UTF8

Write-Host "  ✓ .gitignore" -ForegroundColor Green
