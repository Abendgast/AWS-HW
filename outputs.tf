output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "public_instance_id" {
  description = "ID of the public EC2 instance"
  value       = aws_instance.public_instance.id
}

output "public_instance_public_ip" {
  description = "Public IP of the public EC2 instance"
  value       = aws_instance.public_instance.public_ip
}

output "private_instance_id" {
  description = "ID of the private EC2 instance"
  value       = aws_instance.private_instance.id
}

output "private_instance_private_ip" {
  description = "Private IP of the private EC2 instance"
  value       = aws_instance.private_instance.private_ip
}

output "connection_string_to_public_instance" {
  description = "SSH command to connect to the public instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.public_instance.public_ip}"
}

output "connection_string_to_private_instance" {
  description = "SSH command to connect to the private instance from public instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.private_instance.private_ip}"
}
