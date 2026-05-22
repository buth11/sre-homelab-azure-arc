variable "resource_group_name" {
  description = "Name of the Azure Resource Group for the SRE homelab"
  type        = string
  default     = "SRE-Lab-RG"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "West Europe"

  validation {
    condition     = contains(["West Europe", "North Europe", "East US", "East US 2"], var.location)
    error_message = "Location must be one of the supported Azure regions."
  }
}

variable "budget_name" {
  description = "Name of the Azure Cost Management budget"
  type        = string
  default     = "SRE-Lab-Budget"
}

variable "budget_amount_usd" {
  description = "Monthly budget cap in USD (FinOps guardrail)"
  type        = number
  default     = 5

  validation {
    condition     = var.budget_amount_usd > 0 && var.budget_amount_usd <= 50
    error_message = "Budget must be between 1 and 50 USD for this lab environment."
  }
}

variable "alert_email" {
  description = "Email address for SRE alert notifications"
  type        = string
  default     = "buth11@interia.pl"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Must be a valid email address."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics Workspace"
  type        = number
  default     = 30

  validation {
    condition     = contains([7, 14, 30, 60, 90], var.log_retention_days)
    error_message = "Retention must be 7, 14, 30, 60, or 90 days."
  }
}

locals {
  common_tags = {
    environment  = "lab"
    owner        = "bartosz.suszko"
    project      = "sre-homelab-azure-arc"
    managed_by   = "terraform"
    created_date = "2026-05"
    purpose      = "SRE Interview Portfolio"
  }
}
