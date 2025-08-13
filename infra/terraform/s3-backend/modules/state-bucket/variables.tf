variable "name" {
  description = "The base name for the S3 bucket and all other resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the S3 bucket and its resources"
  type        = map(string)
  default     = {}
}
