# =============================================================================
# Azure Key Vault Module
# =============================================================================
# Terraform equivalent of infra/modules/key-vault/main.bicep
#
# Multi-cloud alternatives:
# - AWS: aws_secretsmanager_secret
# - GCP: google_secret_manager_secret

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = var.sku_name

  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization

  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days

  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    bypass                     = "AzureServices"
    default_action             = var.network_default_action
    ip_rules                   = var.allowed_ip_addresses
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Access Policies (when not using RBAC)
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_access_policy" "deployer" {
  count = var.enable_rbac_authorization ? 0 : 1

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]
  key_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Recover", "Backup", "Restore", "Purge"
  ]
  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Recover", "Backup", "Restore", "Purge"
  ]
}

# -----------------------------------------------------------------------------
# Secrets
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name         = each.key
  value        = each.value.value
  key_vault_id = azurerm_key_vault.main.id

  content_type = lookup(each.value, "content_type", null)

  expiration_date = lookup(each.value, "expiration_date", null)

  tags = lookup(each.value, "tags", {})

  depends_on = [azurerm_key_vault_access_policy.deployer]
}

# -----------------------------------------------------------------------------
# Diagnostic Settings
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
