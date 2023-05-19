data "azuread_client_config" "current" {}

resource "azuread_group" "lab_attendees" {
  display_name     = "${var.lab_prefix} Lab Attendees"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
}

resource "azuread_group_member" "example" {
  for_each = azuread_user.default

  group_object_id  = azuread_group.lab_attendees.id
  member_object_id = each.value.object_id
}