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
The last three commands stand for installing node version manager, his activation and installing required node version.

```tf
provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install git -y",
      "git clone https://github.com/KryvMykyta/testServer.git",
      "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash",
      ". ~/.nvm/nvm.sh",
      "nvm install 16"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = file("aws_key.pem")
    }
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

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install git -y",
      "git clone https://github.com/KryvMykyta/testServer.git",
      "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash",
      ". ~/.nvm/nvm.sh",
      "nvm install 16",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = file("aws_key.pem")
    }
  }
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
After finishing your code, execute these commands to setup your infrastructure:
```tf
terraform init
terraform apply
```

Then you have to connect to your EC2 instance either through SSH client or AWS Management Console.
<br>
Here we need to enter directory with our cloned files and change this line in app.js:
```tf
const token = process.env.TOKEN
```
Instead of `proccess.env.TOKEN` we need to enter our bot's API which we can obtain from specific telegram bot.<br>
<a href="https://t.me/botfather">BOT LINK</a>
<br>
<br>
![image](https://user-images.githubusercontent.com/114437342/216158048-b66c875c-bbd3-4311-973f-17428761b9a0.png)
<br>
<br>

<h2>Final Step</h2>

In your CLI, enter this command to install required Node.js module:
```tf
npm i node-telegram-bot-api
```
<br>

Finally, enter these commands:
```tf
screen
node app js
```
They will start your bot and constantly run it after closing CLI.
