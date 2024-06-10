# Define the provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}
provider "aws" {
  region  = "eu-west-2"
}

# Define the EC2 instance for the master node
resource "aws_instance" "master" {
  ami           = "ami-09627c82937ccdd6d" #  AMI
  instance_type = "t2.medium"
  user_data     = <<EOF
#!/bin/bash
echo "Copying the SSH Key to the server"
echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzsv8IPzbwJLbkpwppawFb1GLhRXVlV77u58IQuByeKoWPv4tGcMNpQ+TDrI4hiKaY1AJzhV12NQqV/WqEC7Y9UV5ZB0gx8I0MWAlpgvRyK4j5wN+HdBPBa0uE7GHbHBDVqLbXKP/7pe5eNpIESCiFEdXis4MZJT63ShVaDMH1TEnvq71vY3WJqm28DnrrkHTyfgNn/ukQzWf6jAr6nnLEaj3OSJIGVvKZLXgw4C8zi2m/7Ang2gJ2CJpB4v+gbXXxBJT7EfOI5m5wMXPnA4g14Ydr3cUshLiMoGr+OuKAYWtlcHseva6Wj1MQH8NftEXY4SWGZNW6S9Sd9l4DlxOHyBDwKjZWzWH2CQdUd3FQ4CZOyXqeQ5AHOYql4RzZKT/R0fX5rmcSz05MIS7os2H5N+H27E78ATE+CeFDTzr5UcrYUbBuyPsrdMzvn1zwGSLKCSTdQHtRajhh1SF9UbQGCDojHCBe7NS6kuCFFraeJLfhqRYPE5A1NMmact3JKHCEtvLGrYU2zqb0440gY4sPSyLPdz8gErFHSrWBFNcYOc5V1lrXN2Tj5cpw3Nw3zAJQG9UxUY0biaE0Wc9G0FsPyA9G3iwlOXklkGsBWl6VbzZ4kDM8Blm156Nq6jr7bJQhLw6zhasdLo0k4Djz8v580JXQKKxnJWZvnlVuxuwLww== houssein@strass-GL553VD" >> /home/ubuntu/.ssh/authorized_keys

EOF
  tags = {
    Name = "k8s-master"
  }
  provisioner "remote-exec" {
    inline = [
      "curl -O https://raw.githubusercontent.com/HousseinHmila/kube/main/script.sh",
      "chmod +x script.sh",
      "./script.sh"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./.ssh/id_rsa")
      host        = self.public_ip
    }
  }


}
