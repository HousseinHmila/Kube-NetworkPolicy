# Define the provider
provider "aws" {
  region = "us-west-2" # region
}

# Define the VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Define the subnet
resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a" # availability zone
}

# Define the security group
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the EC2 instance for the master node
resource "aws_instance" "master" {
  ami           = "ami-0c55b159cbfafe1f0" #  AMI
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.subnet.id
  security_groups = [aws_security_group.allow_all.name]

  tags = {
    Name = "k8s-master"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl",
      "sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y kubelet kubeadm kubectl cri-tools",
      "sudo apt-mark hold kubelet kubeadm kubectl",
      "cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf",
      "overlay",
      "br_netfilter",
      "EOF",
      "modprobe overlay",
      "modprobe br_netfilter",
      "cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf",
      "net.bridge.bridge-nf-call-iptables  = 1",
      "net.ipv4.ip_forward                 = 1",
      "net.bridge.bridge-nf-call-ip6tables = 1",
      "EOF",
      "sysctl --system",
      "apt-get install -y containerd",
      "mkdir -p /etc/containerd",
      "containerd config default > /etc/containerd/config.toml",
      "sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml",
      "systemctl restart containerd",
      "kubeadm init --pod-network-cidr=10.244.0.0/16",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
    ]

    connection {
      type     = "ssh"
      user     = "ubuntu" # Change to your instance user
      private_key = file("~/.ssh/id_rsa") # Change to your private key path
      host     = self.public_ip
    }
  }
}


# Output the master public IP
output "master_public_ip" {
  value = aws_instance.master.public_ip
}

