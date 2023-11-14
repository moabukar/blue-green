variable "elb_sg_ingress_ports" {
  type    = list(number)
  default = [80, 443, 8080]
}


variable "lb_target_group_name" {
  type    = string
  default = "tg"
}
