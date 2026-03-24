# variables.tf

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  default     = "East US"
  description = "Azure region"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM"
}

variable "public_key_path" {
  type        = string
  description = "Path to your SSH public key"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "rg_name" {
  type        = string
  description = "Azure Resource group"
}

variable "public_ip" {
  type        = string
  description = "Public IP for NSG rules"
}

variable "storage_account_name" {
  type        = string
  description = "Storage acc name"
}

variable "storage_container_name" {
  type        = string
  description = "storage cont name"
}

variable "alert_email_address" {
  type        = string
  description = "Email of the admin"
}

variable "keyvault_name" {
  type        = string
  description = "Nom Vault"
}

variable "secret_name" {
  type        = string
  description = "Secret name dans Vault"
}
