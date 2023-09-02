variable "image_flavor" {
  type = string
  default = "Ubuntu-22.04-202208"
}

variable "compute_flavor" {
  type = string
  default = "Basic-1-1-10"
}

variable "key_pair_name" {
  type = string
  default = "ControlVM-LD9iWO3J"
}

variable "availability_zone_name" {
  type = string
  default = "MS1"
}
