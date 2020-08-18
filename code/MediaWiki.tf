## Terraform: Deploy A MediaWiki Stack In the AWS

## Create main.tf
## creates a VPC, one public subnet, two private subnets, one EC2 instance and one MYSQL RDS instance

## aws provider

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

## available AZ's details
data "aws_availability_zones" "availability_zones" {}

## creation of  VPC
resource "aws_vpc" "myvpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc_mediawiki"
  }
}

## create public subnet
resource "aws_subnet" "myvpc_public_subnet" {
  vpc_id                  = "${aws_vpc.myvpc.id}"
  cidr_block              = "${var.subnet_one_cidr}"
  availability_zone       = "${data.aws_availability_zones.availability_zones.names[0]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "mediawiki_public_sub"
  }
}


## create private subnet one
resource "aws_subnet" "myvpc_private_subnet_one" {
  vpc_id            = "${aws_vpc.myvpc.id}"
  cidr_block        = "${element(var.subnet_two_cidr, 0)}"
  availability_zone = "${data.aws_availability_zones.availability_zones.names[0]}"
  tags = {
    Name = "mediawiki_private_sub_1"
  }
}
# create private subnet two
resource "aws_subnet" "myvpc_private_subnet_two" {
  vpc_id            = "${aws_vpc.myvpc.id}"
  cidr_block        = "${element(var.subnet_two_cidr, 1)}"
  availability_zone = "${data.aws_availability_zones.availability_zones.names[1]}"
  tags = {
    Name = "mediawiki_private_sub_2"
  }
}
## create internet gateway
resource "aws_internet_gateway" "myvpc_internet_gateway" {
  vpc_id = "${aws_vpc.myvpc.id}"
  tags=  {
    Name = "mediawiki_igw"
  }
}
## create public route table (assosiated with internet gateway)
resource "aws_route_table" "myvpc_public_subnet_route_table" {
  vpc_id = "${aws_vpc.myvpc.id}"
  route {
    cidr_block = "${var.route_table_cidr}"
    gateway_id = "${aws_internet_gateway.myvpc_internet_gateway.id}"
  }
  tags = {
    Name = "mediawiki_public_rtb"
  }
}

## create private subnet route table
resource "aws_route_table" "myvpc_private_subnet_route_table" {
  vpc_id = "${aws_vpc.myvpc.id}"
  tags = {
    Name = "mediawiki_private_rtb"
  }
}

## associate public subnet with public route table
resource "aws_route_table_association" "myvpc_public_subnet_route_table" {
  subnet_id      = "${aws_subnet.mediawiki_public_sub.id}"
  route_table_id = "${aws_route_table.mediawiki_public_rtb.id}"
}
## associate private subnets with private route table
resource "aws_route_table_association" "myvpc_private_subnet_one_route_table_assosiation" {
  subnet_id      = "${aws_subnet.mediawiki_private_sub_1.id}"
  route_table_id = "${aws_route_table.mediawiki_private_rtb.id}"
}
resource "aws_route_table_association" "myvpc_private_subnet_two_route_table_assosiation" {
  subnet_id      = "${aws_subnet.mediawiki_public_sub_2.id}"
  route_table_id = "${aws_route_table.mediawiki_private_rtb.id}"
}

## create security group for web application access
resource "aws_security_group" "mediawiki_web_sg" {
  name        = "mediawiki_web_sg"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.myvpc.id}"
  tags = {
    Name = "mediawiki_sg"
  }
}

## create security group ingress rule for web
resource "aws_security_group_rule" "web_ingress" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = "22"
  to_port           = "22"
  security_group_id = "${aws_security_group.mediawiki_web_sg.id}"
}

resource "aws_security_group_rule" "web_ingress" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = "443"
  to_port           = "442"
  security_group_id = "${aws_security_group.mediawiki_web_sg.id}"
}
resource "aws_security_group_rule" "web_ingress" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = "80"
  to_port           = "80"
  security_group_id = "${aws_security_group.mediawiki_web_sg.id}"
}
resource "aws_security_group_rule" "web_ingress" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = "8080"
  to_port           = "8080"
  security_group_id = "${aws_security_group.mediawiki_web_sg.id}"
}
## create security group egress rule for web
resource "aws_security_group_rule" "web_egress" {
  count             = "${length(var.web_ports)}"
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = "${element(var.web_ports, count.index)}"
  to_port           = "${element(var.web_ports, count.index)}"
  security_group_id = "${aws_security_group.mediawiki_web_sg.id}"
}
## create security group for db
resource "aws_security_group" "db_security_group" {
  name        = "db_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.myvpc.id}"
  tags = {
    Name = "myvpc_db_security_group"
  }
}
## create security group ingress rule for db
resource "aws_security_group_rule" "db_ingress" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = "3306"
  to_port           = "3306"
  security_group_id = "${aws_security_group.db_security_group.id}"
}
## create security group egress rule for db
resource "aws_security_group_rule" "db_egress" {
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = "${element(var.db_ports, count.index)}"
  to_port           = "${element(var.db_ports, count.index)}"
  security_group_id = "${aws_security_group.db_security_group.id}"
}
## create EC2 instance
resource "aws_instance" "my_web_instance" {
  ami                    = "${lookup(var.images, var.region)}"
  instance_type          = "t2.large"
  key_name               = "myprivate"
  vpc_security_group_ids = ["${aws_security_group.mediawiki_web_sg.id}"]
  subnet_id              = "${aws_subnet.myvpc_public_subnet.id}"
  tags = {
    Name = "my_web_instance"
  }
  volume_tags = {
    Name = "my_web_instance_volume"
  }
  provisioner "remote-exec" { #install apache, mysql client, php, auto on httpd and mysql client, Install wikimedia
    inline = [
      "sudo mkdir -p /var/www/html/",
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo service httpd start",
      "sudo usermod -a -G apache centos",
      "sudo chown -R centos:apache /var/www",
      "sudo yum install -y mysql php php-mysql",
	  "sudo service mysqld start",
	  "sudo chkconfig httpd on",
	  "sudo chkconfig mysqld on",
	  "wget https://releases.wikimedia.org/mediawiki/1.34/mediawiki-1.34.2.tar.gz.sig",
	  "gpg --verify mediawiki-1.34.2.tar.gz.sig mediawiki-1.34.2.tar.gz",
	  "sudo tar -zxf /home/username/mediawiki-1.34.2.tar.gz"
	  "ln -s mediawiki-1.34.2/ mediawiki"
	  "sudo mv mediawiki-1.34.2 /var/www/mediawiki",
	  "sudo chown -R apache:apache /var/www/mediawiki/",
	  "sudo chmod 755 /var/www/mediawiki/",
	  "sudo service httpd restart"
	  "system-config-firewall-tui",
	  "sudo firewall-cmd --permanent --zone=public --add-service=http",
	  "sudo firewall-cmd --permanent --zone=public --add-service=https",
	  "sudo systemctl restart firewalld",
	  "sudo getenforce",
	  "sudo restorecon -FR /var/www/html/mediawiki/"	 
	  
	  
	  ]
  }
  provisioner "file" { #copy the index file form local to remote
   source      = "d:\\terraform\\index.php"
    destination = "/tmp/index.php"
  }
  provisioner "remote-exec" {
	inline = [
	   "sudo mv /tmp/index.php /var/www/html/index.php"
	   ]
	}
 
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = ""
    host     = self.public_ip 
    #copy .pem to instance home directory
	#chmod 600 id_rsa.pem
    private_key = "${file("local:\\terraform\\private\\myprivate.pem")}"
}
  
}

## create aws rds subnet groups
resource "aws_db_subnet_group" "wikidatabase_database_subnet_group" {
  name       = "mydbsg"
  subnet_ids = ["${aws_subnet.myvpc_private_subnet_one.id}", "${aws_subnet.myvpc_private_subnet_two.id}"]
  tags = {
    Name = "wikidatabase_database_subnet_group"
  }
}

## create aws mysql rds instance
resource "aws_db_instance" "wikidatabase_instance" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  port                   = 3306
  vpc_security_group_ids = ["${aws_security_group.db_security_group.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.my_database_subnet_group.name}"
  name                   = "wikidatabase"
  identifier             = "wikidatabase"
  username               = "wiki"
  password               = "THISpasswordSHOULDbeCHANGED"
  tags = {
    Name = "wikidatabase_instance"
  }
}
## Creation of db user
resource "mysql_user" "wiki" {
  user               = "wiki"
  host               = "wikidatabase"
  plaintext_password = "THISpasswordSHOULDbeCHANGED"
}

## grant permissions to the user
resource "mysql_grant" "wiki" {
  user       = "${mysql_user.wiki.user}"
  host       = "${mysql_user.wiki.host}"
  database   = "wikidatabase"
  privileges = ["SELECT", "UPDATE"]
}

## output webserver and dbserver address
output "db_server_address" {
  value = "${aws_db_instance.wikidatabase_instance.address}"
}
output "web_server_address" {
  value = "${aws_instance.my_web_instance.public_dns}"
}