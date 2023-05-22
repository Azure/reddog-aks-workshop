resource "azuread_user" "attendees" {
    count = var.attendee_count
    user_principal_name = "${var.lab_prefix}${count.index + 1}@${data.azuread_domains.example.domains.0.domain_name}"
    display_name        = "User ${count.index + 1}"
    mail_nickname       = "user${count.index}"
    password            = local.password
}
