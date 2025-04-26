resource "aws_instance" "public_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              echo "Public EC2 instance" > /home/ec2-user/public.txt
              echo '${file("${var.key_name}.pem")}' > /home/ec2-user/${var.key_name}.pem
              chmod 600 /home/ec2-user/${var.key_name}.pem
              chown ec2-user:ec2-user /home/ec2-user/${var.key_name}.pem
              EOF

  tags = {
    Name = "${var.project_name}-public-instance"
  }

  depends_on = [aws_key_pair.ssh_key]
}

resource "aws_instance" "private_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              echo "Private EC2 instance" > /home/ec2-user/private.txt
              EOF

  tags = {
    Name = "${var.project_name}-private-instance"
  }

  depends_on = [aws_key_pair.ssh_key]
}
