variable "kms_key_id" {
  type = string
}

variable "recovery_window_in_days" {
  type = string
}

variable "secret_string" {
  type    = string
  default = "CHANGE ME"
}

variable "secrets" {
  type = any
}
