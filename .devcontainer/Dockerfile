# Azure Infrastructure Toolkit Development Container
# Base image with Python and common tools
FROM mcr.microsoft.com/devcontainers/python:1-3.11-bullseye

# Install additional system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    jq \
    unzip \
    wget \
    postgresql-client \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Python development tools
RUN pip install --no-cache-dir \
    black \
    flake8 \
    mypy \
    pytest \
    pytest-cov \
    pytest-asyncio \
    httpx \
    pre-commit

# Set up workspace
WORKDIR /workspaces/azure-infrastructure

# Create .azure directory for Azure CLI config persistence
RUN mkdir -p /home/vscode/.azure && chown -R vscode:vscode /home/vscode/.azure

# Default to non-root user
USER vscode
