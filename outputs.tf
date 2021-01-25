output "fqdn" {
    description = "Fully-qualified domain for App Gateway Public IP. Requires domain_name_label to be defined."
    value = azurerm_public_ip.publicip.fqdn
}

output "ip_address" {
    description = "Public IP Address of App Gateway."
    value = (var.sku_tier == "Standard" ?
        data.azurerm_public_ip.publicip.ip_address :
        azurerm_public_ip.publicip.ip_address)
}