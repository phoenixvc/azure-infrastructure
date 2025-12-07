#!/bin/bash
# Post-create script for GitHub Codespaces / Dev Container

set -e

echo "🔧 Setting up Azure Infrastructure Toolkit development environment..."

# Install Python dependencies for API
if [ -f "src/api/requirements.txt" ]; then
    echo "📦 Installing API dependencies..."
    pip install -r src/api/requirements.txt
fi

# Install test dependencies
if [ -f "tests/requirements.txt" ]; then
    echo "📦 Installing test dependencies..."
    pip install -r tests/requirements.txt
fi

# Install pre-commit hooks
if [ -f ".pre-commit-config.yaml" ]; then
    echo "🪝 Installing pre-commit hooks..."
    pre-commit install
fi

# Verify Azure CLI and Bicep
echo "✅ Verifying toolchain..."
echo "  Azure CLI: $(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo 'not installed')"
echo "  Bicep: $(az bicep version 2>/dev/null || echo 'not installed')"
echo "  Terraform: $(terraform version -json 2>/dev/null | jq -r '.terraform_version' || echo 'not installed')"
echo "  Python: $(python --version)"
echo "  Node.js: $(node --version 2>/dev/null || echo 'not installed')"

# Create useful aliases
cat >> ~/.bashrc << 'EOF'

# Azure Infrastructure Toolkit aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias azl='az login'
alias azs='az account show'
alias pytest-api='pytest tests/unit -v'
alias pytest-all='pytest tests -v'
alias api-start='cd src/api && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000'

# Bicep helpers
alias bicep-build='az bicep build'
alias bicep-validate='az deployment group validate'
EOF

echo ""
echo "🎉 Development environment ready!"
echo ""
echo "Quick start commands:"
echo "  api-start        - Start the FastAPI development server"
echo "  pytest-api       - Run unit tests"
echo "  pytest-all       - Run all tests"
echo "  az login         - Login to Azure"
echo "  tf init          - Initialize Terraform"
echo ""
