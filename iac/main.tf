resource "azurerm_resource_group" "rg" {
  name     = "${var.application_name}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "log" {
  name                = "${var.application_name}-${var.environment}-log"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
}

resource "azurerm_application_insights" "appi" {
  name                = "${var.application_name}-${var.environment}-appi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log.id
}

resource "azurerm_service_plan" "asp" {
  name                   = "${var.application_name}-${var.environment}-asp"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  os_type                = "Windows"
  sku_name               = var.app_service_plan_sku
  #zone_balancing_enabled = true
}

resource "azurerm_windows_web_app" "app" {
  name                = "${var.application_name}-${var.environment}-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.appi.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appi.connection_string
  }

  site_config {
    application_stack { 
      dotnet_version = "v8.0"
      current_stack  = "dotnet"
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "${var.application_name}-${var.environment}-autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_service_plan.asp.id

  profile {
    name = "defaultProfile"
    capacity {
      minimum = "1"
      maximum = "5"
      default = "1"
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.asp.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.asp.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}