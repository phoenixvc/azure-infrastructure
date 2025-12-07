# =============================================================================
# Azure Service Bus Module
# =============================================================================
# Terraform equivalent of infra/modules/service-bus/main.bicep
#
# Multi-cloud alternatives:
# - AWS: aws_sqs_queue + aws_sns_topic
# - GCP: google_pubsub_topic + google_pubsub_subscription

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

# -----------------------------------------------------------------------------
# Service Bus Namespace
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_namespace" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku                 = var.sku
  capacity            = var.sku == "Premium" ? var.capacity : 0

  premium_messaging_partitions = var.sku == "Premium" ? var.premium_messaging_partitions : null
  zone_redundant              = var.sku == "Premium" ? var.zone_redundant : false

  minimum_tls_version = "1.2"
  public_network_access_enabled = var.public_network_access_enabled

  local_auth_enabled = var.local_auth_enabled

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Queues
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_queue" "queues" {
  for_each = { for q in var.queues : q.name => q }

  name         = each.value.name
  namespace_id = azurerm_servicebus_namespace.main.id

  max_size_in_megabytes                = lookup(each.value, "max_size_in_megabytes", 1024)
  enable_partitioning                  = lookup(each.value, "enable_partitioning", false)
  requires_duplicate_detection         = lookup(each.value, "requires_duplicate_detection", false)
  requires_session                     = lookup(each.value, "requires_session", false)
  dead_lettering_on_message_expiration = lookup(each.value, "dead_lettering_on_message_expiration", true)
  max_delivery_count                   = lookup(each.value, "max_delivery_count", 10)
  lock_duration                        = lookup(each.value, "lock_duration", "PT1M")
  default_message_ttl                  = lookup(each.value, "default_message_ttl", "P14D")
}

# -----------------------------------------------------------------------------
# Topics (Standard and Premium only)
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_topic" "topics" {
  for_each = var.sku != "Basic" ? { for t in var.topics : t.name => t } : {}

  name         = each.value.name
  namespace_id = azurerm_servicebus_namespace.main.id

  max_size_in_megabytes        = lookup(each.value, "max_size_in_megabytes", 1024)
  enable_partitioning          = lookup(each.value, "enable_partitioning", false)
  requires_duplicate_detection = lookup(each.value, "requires_duplicate_detection", false)
  default_message_ttl          = lookup(each.value, "default_message_ttl", "P14D")
}

# -----------------------------------------------------------------------------
# Topic Subscriptions
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_subscription" "subscriptions" {
  for_each = var.sku != "Basic" ? merge([
    for topic in var.topics : {
      for sub in lookup(topic, "subscriptions", []) :
      "${topic.name}-${sub}" => {
        topic_name        = topic.name
        subscription_name = sub
      }
    }
  ]...) : {}

  name               = each.value.subscription_name
  topic_id           = azurerm_servicebus_topic.topics[each.value.topic_name].id

  max_delivery_count                   = 10
  lock_duration                        = "PT1M"
  dead_lettering_on_message_expiration = true
}

# -----------------------------------------------------------------------------
# Authorization Rules
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_namespace_authorization_rule" "app_access" {
  name         = "ApplicationAccess"
  namespace_id = azurerm_servicebus_namespace.main.id

  listen = true
  send   = true
  manage = false
}

resource "azurerm_servicebus_namespace_authorization_rule" "manage_access" {
  name         = "ManageAccess"
  namespace_id = azurerm_servicebus_namespace.main.id

  listen = true
  send   = true
  manage = true
}
