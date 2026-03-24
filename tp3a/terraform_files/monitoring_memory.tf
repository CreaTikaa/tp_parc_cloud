# monitoring_memory.tf

resource "azurerm_monitor_action_group" "email_alert" {
  name                = "vm-email-actiongroup"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "vmalert"

  email_receiver {
    name                    = "SendToAdmin"
    email_address           = var.alert_email_address
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "memory_alert" {
  name                = "low-memory-alert"
  resource_group_name = azurerm_resource_group.main.name
  
  scopes              = [azurerm_linux_virtual_machine.main.id]
  description         = "Alert RAM less de 512 Mo."

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 536870912 
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_alert.id
  }
}
