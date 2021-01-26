// Required
variable "rg_name" {
  description = "Name of the resource group to place App Gateway in."
}
variable "rg_location" {
  description = "Location of the resource group to place App Gateway in."
}
variable "name" {
  description = "Name of App Gateway"
}


// Optional
variable "backend_address_pools" {
  description = "List of backend address pools."
  type = list(object({
    name         = string
    ip_addresses = list(string)
    fqdns        = list(string)
  }))
}
variable "backend_http_settings" {
  description = "List of backend HTTP settings."
  type = list(object({
    name            = string
    path            = string
    is_https        = bool
    request_timeout = string
    probe_name      = string
  }))
}
variable "http_listeners" {
  description = "List of HTTP/HTTPS listeners. HTTPS listeners require an SSL Certificate object."
  type = list(object({
    name                 = string
    ssl_certificate_name = string
    host_name            = string
    require_sni          = bool
  }))
}
variable "basic_request_routing_rules" {
  description = "Request routing rules to be used for listeners."
  type = list(object({
    name                        = string
    http_listener_name          = string
    backend_address_pool_name   = string
    backend_http_settings_name  = string
  }))
  default = []
}
variable "redirect_request_routing_rules" {
  description = "Request routing rules to be used for listeners."
  type = list(object({
    name                        = string
    http_listener_name          = string
    redirect_configuration_name = string
  }))
  default = []
}
variable "path_based_request_routing_rules" {
  description = "Request routing rules to be used for listeners."
  type = list(object({
    name               = string
    http_listener_name = string
    url_path_map_name  = string
  }))
  default = []
}

variable "sku_name" {
  description = "Name of App Gateway SKU. Options include Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2"
  default     = "Standard_Small"
}
variable "sku_tier" {
  description = "Tier of App Gateway SKU. Options include Standard, Standard_v2, WAF and WAF_v2"
  default     = "Standard"
}
variable "probes" {
  description = "Health probes used to test backend health."
  default     = []
  type = list(object({
    name                                      = string
    path                                      = string
    is_https                                  = bool
  }))
}
variable "url_path_maps" {
  description = "URL path maps associated to path-based rules."
  default     = []
  type = list(object({
    name                               = string
    default_backend_http_settings_name = string
    default_backend_address_pool_name  = string
    path_rules = list(object({
      name                       = string
      backend_address_pool_name  = string
      backend_http_settings_name = string
      paths                      = list(string)
    }))
  }))
}

variable "domain_name_label" {
  description = "Domain name label for Public IP created."
  default = null
}

variable "ips_allowed" {
  description = "A list of IP addresses to allow to connect to App Gateway."
  default     = []
  type = list(object({
    name         = string
    priority     = number
    ip_addresses = string
  }))
}

variable "redirect_configurations" {
  description = "A collection of redirect configurations."
  default     = []
  type = list(object({
    name                 = string
    redirect_type        = string
    target_listener_name = string
    target_url           = string
    include_path         = bool
    include_query_string = bool
  }))
}

variable "ssl_certificates" {
  description = "SSL Certificate objects to be used for HTTPS listeners. Requires a PFX certificate stored on the machine running the Terraform apply."
  default     = []
  type = list(object({
    name              = string
    pfx_cert_filepath = string
    pfx_cert_password = string
  }))
}
