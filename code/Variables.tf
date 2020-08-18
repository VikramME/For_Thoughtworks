variable "access_key" 
{ 
default = "your key here" 
}
variable "secret_key" 
{ 
default = "your key here" 
}
variable "region" 
{ 
default = "us-east-1" 
}
variable "vpc_cidr" 
{ 
default = "10.0.0.0/16" 
}
variable "subnet_one_cidr" 
{ 
default = "10.0.1.0/24" 
}
variable "subnet_two_cidr" 
{ 
default = ["10.0.2.0/24", "10.0.3.0/24"] 
}
variable "db_ports" { default = ["22", "3306"] }
variable "images" {
  type = "map"
  default = {
    "us-east-1"      = "ami-0943sdjfer4r33434"
  }
}
