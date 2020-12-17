output "fqdn" {
    description = "Fully-qualified domain for App Gateway Public IP. Requires domain_name_label to be defined."
    value = azurerm_public_ip.publicip.fqdn
}