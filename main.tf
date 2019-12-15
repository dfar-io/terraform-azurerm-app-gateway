resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name}vnet"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "10.254.0.0/24"
}

resource "azurerm_public_ip" "publicip" {
  name                = "${var.name}pip"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = var.is_public_ip_allocation_static ? "Static" : "Dynamic"
  sku                 = "Standard"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
}

resource "azurerm_application_gateway" "network" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnet.id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.publicip.id
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      ip_addresses = backend_address_pool.value.ip_addresses
      fqdns        = backend_address_pool.value.fqdns
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.value.name
      cookie_based_affinity               = backend_http_settings.value.has_cookie_based_affinity ? "Enabled" : "Disabled"
      path                                = backend_http_settings.value.path
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.is_https ? "Https" : "Http"
      request_timeout                     = backend_http_settings.value.request_timeout
      probe_name                          = backend_http_settings.value.probe_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
    }
  }

  dynamic "probe" {
    for_each = var.probes
    content {
      interval                                  = 30
      name                                      = probe.value.name
      path                                      = probe.value.path
      protocol                                  = probe.value.is_https ? "Https" : "Http"
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.is_https ? "https-port" : "http-port"
      protocol                       = http_listener.value.is_https ? "Https" : "Http"
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                       = request_routing_rule.value.name
      rule_type                  = request_routing_rule.value.is_path_based ? "PathBasedRouting" : "Basic"
      http_listener_name         = request_routing_rule.value.http_listener_name
      backend_address_pool_name  = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name = request_routing_rule.value.backend_http_settings_name
      url_path_map_name          = request_routing_rule.value.url_path_map_name
    }
  }

  dynamic "url_path_map" {
    for_each = var.url_path_maps
    content {
      name                               = url_path_map.value.name
      default_backend_http_settings_name = url_path_map.value.default_backend_http_settings_name
      default_backend_address_pool_name  = url_path_map.value.default_backend_address_pool_name

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules
        content {
          name                       = path_rule.value.name
          backend_address_pool_name  = path_rule.value.backend_address_pool_name
          backend_http_settings_name = path_rule.value.backend_http_settings_name
          paths                      = path_rule.value.paths
        }
      }
    }
  }
}
