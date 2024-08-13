variable "lab_prefix" {
  type = string
  default = "gbb"
}

variable "rg_prefix" {
  type = string
  default = "rg"
}

variable "attendee_count" {
    type = number
    default = 10
}

variable "location" {
  type = string
  default = "eastus2"
}

variable "password" {
  type = string
  default = ""
  sensitive = false
}
