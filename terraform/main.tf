provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "my-tg-bot" {
  ami                         = "ami-06c39ed6b42908a36"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.tgbotsecuritygroup.id]
  key_name                    = "aws_key"
  associate_public_ip_address = "true"

  tags = {
    Name = "my-tg-bot"
  }

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = file("aws_key.pem")
    }

    provisioner "file" {
      source      = "startbot.sh"
      destination = "/home/ec2-user/startbot.sh"
    }

    provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install git -y",
      "git clone https://github.com/KryvMykyta/testServer.git",
      "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash",
      ". ~/.nvm/nvm.sh",
      "nvm install 16",
      "npm install -g npm@9.5.0",
      "cd testServer/",
      "npm i node-telegram-bot-api",
      "sed -i \"$(grep -n 'const token = process.env.TOKEN' app.js | cut -d: -f1)s/.*/const token = '${var.bot_api_key}'/\" app.js",
      "cd ..",
      "sudo chmod +x /home/ec2-user/startbot.sh",
      "sudo /home/ec2-user/startbot.sh"
    ]
    }
}

variable "bot_api_key" {
  type        = string
  description = "The API key for the Telegram bot."
}

resource "aws_security_group" "tgbotsecuritygroup" {

  dynamic "ingress" {
    for_each = ["80", "443", "22"]
    content {
      description = "HTTP, HTTPS, SSH ports"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}




