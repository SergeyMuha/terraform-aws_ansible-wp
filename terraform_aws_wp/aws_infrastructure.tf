provider "aws" {
  region     = "us-east-1"
}
resource "aws_internet_gateway" "gwmuhas" {
  vpc_id = "${aws_vpc.vpcmuhas.id}"

  tags {
    Name = "muhas"
  }
}
resource "aws_vpc" "vpcmuhas" {
  cidr_block       = "192.168.0.0/24"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags {
    Name = "muhas"
  }
}

resource "aws_subnet" "subnetmuhas" {
  availability_zone = "us-east-1a"
  vpc_id     = "${aws_vpc.vpcmuhas.id}"
  cidr_block = "192.168.0.0/26"
  map_public_ip_on_launch = "true"

  tags {
    Name = "public_muhas"
  }
}

resource "aws_subnet" "subnetmuhass" {
  availability_zone = "us-east-1b"
  vpc_id     = "${aws_vpc.vpcmuhas.id}"
  cidr_block = "192.168.0.64/26"

  tags {
    Name = "private_muhas"
  }
}


resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.vpcmuhas.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.muhas.id}"
  provisioner "local-exec" {
    command = "cp ../ansible_wp_setup/roles/haproxy/templates/haproxy_workers.init ../ansible_wp_setup/roles/haproxy/templates/haproxy_workers_ip"
  }


  provisioner "local-exec" {
    command = "cp ../ansible_wp_setup/roles/haproxy/templates/haproxy.cfg.j2.initial ../ansible_wp_setup/roles/haproxy/templates/haproxy.cfg.j2"
  }

}
resource "aws_vpc_dhcp_options" "muhas" {
  domain_name          = "ec2.muhas"
  domain_name_servers  = ["AmazonProvidedDNS"]

  tags {
    Name = "muhas"
  }
}

resource "aws_default_route_table" "OutRouteMuhas" {
  default_route_table_id = "${aws_vpc.vpcmuhas.default_route_table_id}"

 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gwmuhas.id}"
  }


  tags {
    Name = "public_muhas"
  }
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.vpcmuhas.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gw.id}"
  }

  tags {
    Name = "muhas_private"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.subnetmuhass.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_eip" "ip" {
  vpc      = true
  tags {
    Name = "muhas"
  }

}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.ip.id}"
  subnet_id     = "${aws_subnet.subnetmuhas.id}"
  tags {
    Name = "muhas"
  }
}

resource "aws_default_security_group" "secgrmuhas" {
  vpc_id      = "${aws_vpc.vpcmuhas.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "muhas"
  }

}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.vpcmuhas.default_network_acl_id}"
  subnet_ids = ["${aws_subnet.subnetmuhas.id}"]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags {
    Name = "muhas"
  }
}

#resource "null_resource" "clear-config" {
#  provisioner "local-exec" {
#    command = "cat ../ansible_wp_setup/roles/haproxy/templates/haproxy_workers >> ../ansible_wp_setup/roles/haproxy/templates/haproxy.cfg.j2"
#  }

#  provisioner "local-exec" {
#    command = "cp ../ansible_wp_setup/roles/haproxy/templates/haproxy_workers.init ../ansible_wp_setup/roles/haproxy/templates/haproxy_workers_ip"
#  }


#  provisioner "local-exec" {
#    command = "cp ../ansible_wp_setup/roles/haproxy/templates/haproxy.cfg.j2.initial ../ansible_wp_setup/roles/haproxy/templates/haproxy.cfg.j2"
#  }
#  provisioner "local-exec" {
#    command = "echo '       ' server workers${aws_instance.workers.count.index} ${aws_instance.workers.*.private_ip}:80 >> ../ansible_wp_setup/roles/haproxy/templates/haproxy.cfg.j2"
#  }
#  triggers {
#    name = "${join(",", aws_instance.workers.*.id)}"
#  } 
#}

resource "aws_instance" "workers" {
  count = 3
  ami           = "ami-467ca739"
  associate_public_ip_address = "false"
  instance_type = "t2.micro"
  subnet_id	= "${aws_subnet.subnetmuhass.id}"
  key_name 	= "sergeymuha"

  provisioner "local-exec" {
    command = "echo '       ' server workers${count.index} ${self.private_ip}:80 >> ../ansible_wp_setup/roles/haproxy/templates/haproxy.cfg.j2"
  }
  provisioner "local-exec" {
    command = "echo ${self.private_ip}  >> ../ansible_wp_setup/roles/haproxy/templates/haproxy_workers_ip"
  }

  tags {
    Name = "workers_muha_${count.index}"
    ansible_group = "workers"
  }
}
output "filesysid" {
  value = "${aws_efs_file_system.docroot.dns_name}"
}
resource "aws_instance" "haproxy" {
  count = 1
  ami           = "ami-467ca739"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.subnetmuhas.id}"
  key_name      = "sergeymuha"
  provisioner "file" {
    source      = "files/filesysid_for_mount.txt"
    destination = "/tmp/filesysid_for_mount.txt"
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/aws_altoros_key.pem")}"
    }
  }
  provisioner "file" {
    source      = "files/endpoint_for_wpdb.txt"
    destination = "/tmp/endpoint_for_wpdb.txt"
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/aws_altoros_key.pem")}"
    }
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/aws_altoros_key.pem")}"
    }
    scripts = [
      "mount.sh",
    ]
  }

  provisioner "file" {
    source      = "mount.sh"
    destination = "/tmp/mount.sh"
    
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/aws_altoros_key.pem")}"
    }
  }

  tags {
    Name = "haproxy_muha"
  }
}

resource "aws_instance" "bastion" {
  count = 1
  ami           = "ami-467ca739"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.subnetmuhas.id}"
  key_name      = "sergeymuha"

  provisioner "file" {
    source      = "mount.sh"
    destination = "/tmp/mount.sh"

    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/aws_altoros_key.pem")}"
    }
  }

  provisioner "file" {
    source      = "~/.ssh/aws_altoros_key.pem"
    destination = "~/.ssh/aws_altoros_key.pem"
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/aws_altoros_key.pem")}"
    }
  }

  provisioner "file" {
    source      = "../ansible_wp_setup/roles/haproxy/templates/haproxy_workers_ip"
    destination = "/tmp/haproxy_workers_ip"

    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/aws_altoros_key.pem")}"
    }
  }


  provisioner "file" {
    source      = "files/filesysid_for_mount.txt"
    destination = "/tmp/filesysid_for_mount.txt"
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/aws_altoros_key.pem")}"
    }
  }


  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/aws_altoros_key.pem")}"
    }
    scripts = [
      "bastion_init.sh",
    ]
  }

  provisioner "file" {
    source      = "../ansible_wp_setup/"
    destination = "/home/ec2-user/"
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/aws_altoros_key.pem")}"
    }
  }


  tags {
    Name = "bastion_host_muha"
  }
}


output "endpoint_for_wpdb" {
  value = "${aws_db_instance.wordpressdb.endpoint}"
}

resource "aws_db_instance" "wordpressdb" {
  identifier = "dbinstance"
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "wordpress"
  username             = "wordpress"
  password             = "wordpress"
  db_subnet_group_name = "${aws_db_subnet_group.wp.id}"
  skip_final_snapshot     = "true"
  
  provisioner "local-exec" {
    command = "echo ${aws_db_instance.wordpressdb.endpoint} > files/endpoint_for_wpdb.txt"
  }

  tags {
    Name = "muhas"
  }

}
resource "aws_db_subnet_group" "wp" {
  name       = "wp"
  subnet_ids = ["${aws_subnet.subnetmuhas.id}","${aws_subnet.subnetmuhass.id}"]

  tags {
    Name = "muhas"
  }
}

resource "aws_efs_file_system" "docroot" {
  creation_token = "docroot"
  
  provisioner "local-exec" {
    command = "echo ${aws_efs_file_system.docroot.dns_name} > files/filesysid_for_mount.txt"
  }

  tags {
    Name = "muhas_docroot"
  }
}

resource "aws_efs_mount_target" "a" {
  file_system_id = "${aws_efs_file_system.docroot.id}"
  subnet_id      = "${aws_subnet.subnetmuhas.id}"
}

resource "aws_efs_mount_target" "b" {
  file_system_id = "${aws_efs_file_system.docroot.id}"
  subnet_id      = "${aws_subnet.subnetmuhass.id}"
}

