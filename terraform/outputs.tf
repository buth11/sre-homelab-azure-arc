output "resource_group_id" {
  description = "ID of the created Resource Group"
  value       = azurerm_resource_group.sre_lab.id
}

output "resource_group_name" {
  description = "Name of the created Resource Group"
  value       = azurerm_resource_group.sre_lab.name
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.sre_lab.id
}

output "log_analytics_workspace_key" {
  description = "Primary shared key for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.sre_lab.primary_shared_key
  sensitive   = true
}

output "action_group_id" {
  description = "ID of the Monitor Action Group for SRE alerts"
  value       = azurerm_monitor_action_group.sre_alerts.id
}

output "subscription_id" {
  description = "Current Azure Subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

output "budget_name" {
  description = "Name of the FinOps budget created"
  value       = azurerm_consumption_budget_subscription.sre_lab.name
}
