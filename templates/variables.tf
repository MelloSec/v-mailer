variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

# variable "script_url" {
#   description = "URL to the post-deployment script"
#   type        = string
# }

# variable "script_url" {
#   description = "URL to the post-deployment script"
#   type        = string
#   default     = "<<<SCRIPTURL>>>"
# }
