terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }


  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "sretfstate5496"
    container_name       = "tfstate"
    key                  = "sre-homelab.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ─────────────────────────────────────────────
# Resource Group
# ─────────────────────────────────────────────
resource "azurerm_resource_group" "sre_lab" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ─────────────────────────────────────────────
# Log Analytics Workspace
# ─────────────────────────────────────────────
resource "azurerm_log_analytics_workspace" "sre_lab" {
  name                = "sre-lab-workspace-${random_string.suffix.result}"
  location            = azurerm_resource_group.sre_lab.location
  resource_group_name = azurerm_resource_group.sre_lab.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ─────────────────────────────────────────────
# Cost Management Budget (FinOps)
# ─────────────────────────────────────────────
resource "azurerm_consumption_budget_subscription" "sre_lab" {
  name            = var.budget_name
  subscription_id = data.azurerm_subscription.current.id

  amount     = var.budget_amount_usd
  time_grain = "Monthly"

  time_period {
    start_date = "2026-05-01T00:00:00Z"
    end_date   = "2028-04-30T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }
}

# ─────────────────────────────────────────────
# Action Group for Alerts
# ─────────────────────────────────────────────
resource "azurerm_monitor_action_group" "sre_alerts" {
  name                = "SRE-Lab-Alerts"
  resource_group_name = azurerm_resource_group.sre_lab.name
  short_name          = "sre-alerts"
  tags                = local.common_tags

  email_receiver {
    name                    = "SRE Engineer"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# ─────────────────────────────────────────────
# Alert Rule: OOMKill detection
# ─────────────────────────────────────────────
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "oom_kill" {
  name                = "sre-lab-oomkill-alert"
  location            = azurerm_resource_group.sre_lab.location
  resource_group_name = azurerm_resource_group.sre_lab.name
  tags                = local.common_tags

  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [azurerm_log_analytics_workspace.sre_lab.id]
  severity             = 2
  description          = "Fires when a container is OOMKilled in the K3s cluster"

  criteria {
    query = <<-QUERY
      KubeEvents
      | where Type == "Warning"
      | where Reason == "OOMKilling"
      | summarize count() by bin(TimeGenerated, 5m)
    QUERY

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.sre_alerts.id]
  }
}

# ─────────────────────────────────────────────
# Data sources
# ─────────────────────────────────────────────
data "azurerm_subscription" "current" {}
