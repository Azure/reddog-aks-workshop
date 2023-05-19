resource "azurerm_resource_group" "default" {
  count = var.attendee_count

  name = "${var.rg_prefix}-${count.index + 1}"
  location = var.location
}