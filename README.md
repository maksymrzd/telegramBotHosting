<h1 align="center">Hosting Telegram bot on AWS</h1>

Setup `aws_instance` with desired OS and assign this `aws_security_group` using dynamic blocks.
```tf
resource "aws_instance" "my-tg-bot" {
  ami                         = "ami-06c39ed6b42908a36"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.tgbotsecuritygroup.id]
  key_name                    = "aws_key"
  associate_public_ip_address = "true"

  tags = {
    Name = "my-tg-bot"
  }
}

```
This `aws_security_group` block allows all inbound traffic on 80, 443 and 22 ports.

```tf
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
```

Add `remote-exec` and `connection` blocks to your `aws_instance` block for terraform to connect to your instance and execute required commands.

The first three commands in `remote_exec` block stand for updating all packages, installing git and cloning a public repository with required JavaScript files for bot.
<br>
The next four commands stand for installing node version manager, his activation and installing required node version.
<br>
After this we need to move to the directory with app.js file and install the required library here.
<br>
Then we need to change the line in app.js file to our API usind sed command and execute our script.

```tf
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

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = file("aws_key.pem")
    }
  }
```
We add our script using provisioner "file" and specify the path:
```tf
provisioner "file" {
      source      = "startbot.sh"
      destination = "/home/ec2-user/startbot.sh"
    }
```
Script creates telegram-bot.service on our created system, enables and starts it:
```tf
#!/bin/bash

sudo mkdir -p /etc/systemd/system
sudo tee /etc/systemd/system/telegram-bot.service > /dev/null <<EOF
[Unit]
Description=Telegram Bot Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/testServer
ExecStart=/home/ec2-user/.nvm/versions/node/v16.19.1/bin/node /home/ec2-user/testServer/app.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable telegram-bot.service
sudo systemctl start telegram-bot.service
```
And also we need to specify a variable for our API:
```tf
variable "bot_api_key" {
  type        = string
  description = "The API key for the Telegram bot."
}
```

The final terraform code should look like this:
```tf
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
```
After finishing your code, execute these commands to setup your infrastructure and add our variable:
```tf
terraform init
terraform apply -var 'bot_api_key=YourAPI'

```

After the infrastructure is ready, your bot is ready to use!
