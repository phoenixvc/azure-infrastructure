# =============================================================================
# Azure Container Apps Module
# =============================================================================
# Terraform equivalent of infra/modules/container-apps/main.bicep
#
# Multi-cloud alternatives:
# - AWS: aws_apprunner_service or aws_ecs_service
# - GCP: google_cloud_run_v2_service

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

# -----------------------------------------------------------------------------
# Container Apps Environment
# -----------------------------------------------------------------------------

resource "azurerm_container_app_environment" "main" {
  name                = var.environment_name
  resource_group_name = var.resource_group_name
  location            = var.location

  log_analytics_workspace_id = var.log_analytics_workspace_id

  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled

  zone_redundancy_enabled = var.zone_redundancy_enabled

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Container App
# -----------------------------------------------------------------------------

resource "azurerm_container_app" "main" {
  name                         = var.app_name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = var.revision_mode

  # Identity
  dynamic "identity" {
    for_each = var.user_assigned_identity_ids != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.user_assigned_identity_ids
    }
  }

  dynamic "identity" {
    for_each = var.user_assigned_identity_ids == null ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Ingress
  dynamic "ingress" {
    for_each = var.enable_ingress ? [1] : []
    content {
      external_enabled = var.external_ingress
      target_port      = var.target_port
      transport        = var.transport

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

  # Registry
  dynamic "registry" {
    for_each = var.container_registry_server != null ? [1] : []
    content {
      server               = var.container_registry_server
      username             = var.container_registry_username
      password_secret_name = var.container_registry_password_secret_name
    }
  }

  # Secrets
  dynamic "secret" {
    for_each = var.secrets
    content {
      name  = secret.key
      value = secret.value
    }
  }

  # Template
  template {
    container {
      name   = var.app_name
      image  = var.container_image
      cpu    = var.cpu
      memory = var.memory

      # Environment variables
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret environment variables
      dynamic "env" {
        for_each = var.secret_environment_variables
        content {
          name        = env.key
          secret_name = env.value
        }
      }

      # Liveness probe
      dynamic "liveness_probe" {
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        content {
          transport = "HTTP"
          port      = liveness_probe.value.port
          path      = liveness_probe.value.path
        }
      }

      # Readiness probe
      dynamic "readiness_probe" {
        for_each = var.readiness_probe != null ? [var.readiness_probe] : []
        content {
          transport = "HTTP"
          port      = readiness_probe.value.port
          path      = readiness_probe.value.path
        }
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    # HTTP scaling rule
    dynamic "http_scale_rule" {
      for_each = var.enable_http_scaling ? [1] : []
      content {
        name                = "http-scaling"
        concurrent_requests = var.http_concurrent_requests
      }
    }

    # Custom scaling rules
    dynamic "custom_scale_rule" {
      for_each = var.custom_scale_rules
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.type
        metadata         = custom_scale_rule.value.metadata
      }
    }
  }

  # Dapr
  dynamic "dapr" {
    for_each = var.enable_dapr ? [1] : []
    content {
      app_id       = var.dapr_app_id
      app_port     = var.dapr_app_port
      app_protocol = var.dapr_app_protocol
    }
  }

  tags = var.tags
}
