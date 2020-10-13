resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name}-vnet"
  resource_group_name = var.rg_name
  location            = var.rg_location
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.254.0.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "${var.name}-pip"
  resource_group_name = var.rg_name
  location            = var.rg_location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.domain_name_label
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
}

resource "azurerm_application_gateway" "app-gateway" {
  name                = var.name
  resource_group_name = var.rg_name
  location            = var.rg_location

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = 3
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
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
      cookie_based_affinity               = "Disabled"
      path                                = backend_http_settings.value.path
      port                                = backend_http_settings.value.is_https ? "443" : "80"
      protocol                            = backend_http_settings.value.is_https ? "Https" : "Http"
      request_timeout                     = 30
      probe_name                          = backend_http_settings.value.probe_name
      pick_host_name_from_backend_address = true
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
      pick_host_name_from_backend_http_settings = true
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.ssl_certificate_name != null ? "https-port" : "http-port"
      protocol                       = http_listener.value.ssl_certificate_name != null ? "Https" : "Http"
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name     = ssl_certificate.value.name
      data     = filebase64(ssl_certificate.value.pfx_cert_filepath)
      password = ssl_certificate.value.pfx_cert_password
    }
  }

  // Basic Rules
  dynamic "request_routing_rule" {
    for_each = var.basic_request_routing_rules
    content {
      name                        = request_routing_rule.value.name
      rule_type                   = "Basic"
      http_listener_name          = request_routing_rule.value.http_listener_name
      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
    }
  }

  // Redirect Rules
  dynamic "request_routing_rule" {
    for_each = var.redirect_request_routing_rules
    content {
      name                        = request_routing_rule.value.name
      rule_type                   = "Basic"
      http_listener_name          = request_routing_rule.value.http_listener_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
    }
  }

  // Path based rules
  dynamic "request_routing_rule" {
    for_each = var.path_based_request_routing_rules
    content {
      name                        = request_routing_rule.value.name
      rule_type                   = "PathBasedRouting"
      http_listener_name          = request_routing_rule.value.http_listener_name
      url_path_map_name           = request_routing_rule.value.url_path_map_name
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

  dynamic "redirect_configuration" {
    for_each = var.redirect_configurations
    content {
      name                 = redirect_configuration.value.name
      redirect_type        = redirect_configuration.value.redirect_type
      target_listener_name = redirect_configuration.value.target_listener_name
      target_url           = redirect_configuration.value.target_url
      include_path         = redirect_configuration.value.include_path
      include_query_string = redirect_configuration.value.include_query_string
    }
  }
}
