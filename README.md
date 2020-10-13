# Azure Application Gateway Module

Terraform Module to deploy an Application Gateway into Azure.

## Usage

### Basic Usage

This configuration creates a proxy server that serves a UI and API.

```
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-${var.env}-rg"
  location = "Central US"
}

locals {
  ui-beap       = "ui-beap"
  api-beap      = "api-beap"
  ui-htst       = "ui-htst"
  api-htst      = "api-htst"
  http-listener = "http-listener"
  http-url-path = "http-url-path"
}

module "app-gateway" {
  source      = "dfar-io/app-gateway/azurerm"
  name        = "APP_GATEWAY_NAME"
  rg_location = azurerm_resource_group.rg.location
  rg_name     = azurerm_resource_group.rg.name

  backend_address_pools = [
    {
      name  = local.ui-beap
      ip_addresses = null
      fqdns = ["UI_URL"]
    },
    {
      name  = local.api-beap
      ip_addresses = null
      fqdns = ["API_URL"]
    }
  ]

  backend_http_settings = [
    {
      name = local.ui-htst
      path = "/"
      is_https = true
      probe_name = null
    },
    {
      name = local.api-htst
      path = "/api/"
      is_https = true
      probe_name = null
    }
  ]

  http_listeners = [
    {
      name     = local.http-listener
      is_https = false
    }
  ]

  path_based_request_routing_rules = [
    {
      name               = "http-rqrt"
      http_listener_name = local.http-listener
      url_path_map_name  = "http-url-path"
    }
  ]

  url_path_maps = [
    {
      name                               = "http-url-path"
      default_backend_address_pool_name  = local.ui-beap
      default_backend_http_settings_name = local.ui-htst
      path_rules = [
        {
          name                       = "api"
          backend_address_pool_name  = local.api-beap
          backend_http_settings_name = local.api-htst
          paths                      = ["/api/*"]
        }
      ]
    }
  ]
}
```