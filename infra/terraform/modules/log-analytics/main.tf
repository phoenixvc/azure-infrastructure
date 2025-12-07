# =============================================================================
# Azure Log Analytics Workspace Module
# =============================================================================
# Terraform equivalent of infra/modules/log-analytics/main.bicep
#
# Multi-cloud alternatives:
# - AWS: aws_cloudwatch_log_group
# - GCP: google_logging_project_sink

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

# -----------------------------------------------------------------------------
# Log Analytics Workspace
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku               = var.sku
  retention_in_days = var.retention_in_days
  daily_quota_gb    = var.daily_quota_gb

  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Application Insights
# -----------------------------------------------------------------------------

resource "azurerm_application_insights" "main" {
  count = var.create_application_insights ? 1 : 0

  name                = var.application_insights_name != null ? var.application_insights_name : "${var.name}-ai"
  resource_group_name = var.resource_group_name
  location            = var.location

  application_type = var.application_type
  workspace_id     = azurerm_log_analytics_workspace.main.id

  retention_in_days = var.app_insights_retention_days
  sampling_percentage = var.sampling_percentage

  disable_ip_masking = var.disable_ip_masking

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Solutions
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_solution" "solutions" {
  for_each = toset(var.solutions)

  solution_name         = each.value
  resource_group_name   = var.resource_group_name
  location              = var.location
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/${each.value}"
  }
}
