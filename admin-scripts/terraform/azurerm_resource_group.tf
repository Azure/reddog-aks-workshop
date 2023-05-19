resource "azurerm_resource_group" "default" {
  count = var.attendee_count

  name = "${var.rg_prefix}-${count.index + 1}"
  location = var.location
}

resource "azurerm_role_assignment" "rg_contributor" {
  for_each = {for i, user in azuread_user.attendees: i => user }

  scope                = azurerm_resource_group.default[each.key].id
  role_definition_name = "Contributor"
  principal_id         = each.value.object_id
}