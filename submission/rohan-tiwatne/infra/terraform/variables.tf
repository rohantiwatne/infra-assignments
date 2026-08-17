variable "namespace" {
  type    = string
  default = "config-service"
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_storage" {
  type    = string
  default = "1Gi"
}
