data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-role-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile-${random_string.suffix.result}"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_launch_template" "nginx" {
  name                   = "nginx-launch-template-${random_string.suffix.result}"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2.id]
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update system packages
    yum update -y
    
    # Install NGINX
    amazon-linux-extras install nginx1 -y
    
    # Start and enable NGINX service
    systemctl start nginx
    systemctl enable nginx
    
    # Create a custom index.html
    cat > /usr/share/nginx/html/index.html << 'INNEREOF'
    <!DOCTYPE html>
    <html>
    <head>
        <title>Welcome to NGINX on AWS</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 40px;
                text-align: center;
            }
            h1 {
                color: #333;
            }
            .container {
                max-width: 800px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f5f5f5;
                border-radius: 5px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Welcome to NGINX on AWS</h1>
            <p>This server is running on Amazon EC2 with NGINX.</p>
            <p>Instance metadata:</p>
            <pre id="instance-data">Loading instance data...</pre>
        </div>
        <script>
            fetch('http://169.254.169.254/latest/meta-data/instance-id')
                .then(response => response.text())
                .then(instanceId => {
                    document.getElementById('instance-data').innerText = 'Instance ID: ' + instanceId;
                })
                .catch(error => {
                    document.getElementById('instance-data').innerText = 'Error fetching instance data';
                });
        </script>
    </body>
    </html>
    INNEREOF
    
    # Restart NGINX to apply changes
    systemctl restart nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "nginx-instance-${random_string.suffix.result}"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
