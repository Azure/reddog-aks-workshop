resource "azuread_group" "lab_attendees" {
  display_name     = "${var.lab_prefix} Lab Attendees"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
}

resource "azuread_group_member" "lab_attendees" {
  for_each = {for i, user in azuread_user.attendees: i => user }

  group_object_id  = azuread_group.lab_attendees.id
  member_object_id = each.value.object_id
}