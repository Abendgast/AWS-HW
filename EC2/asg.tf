resource "aws_autoscaling_group" "nginx" {
  name = "nginx-asg-${random_string.suffix.result}"
  
  vpc_zone_identifier = aws_subnet.private[*].id
  
  min_size             = var.asg_min_size
  max_size             = var.asg_max_size
  desired_capacity     = var.asg_desired_capacity
  
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "nginx-asg-instance-${random_string.suffix.result}"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Environment"
    value               = "Production"
    propagate_at_launch = true
  }
  
  depends_on = [aws_launch_template.nginx]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.nginx.name
  lb_target_group_arn    = aws_lb_target_group.nginx.arn
}

resource "aws_autoscaling_policy" "target_tracking" {
  name                   = "target-tracking-${random_string.suffix.result}"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.nginx.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-${random_string.suffix.result}"
  autoscaling_group_name = aws_autoscaling_group.nginx.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down-${random_string.suffix.result}"
  autoscaling_group_name = aws_autoscaling_group.nginx.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-${random_string.suffix.result}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.nginx.name
  }
  
  alarm_description = "This metric monitors high CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-${random_string.suffix.result}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.nginx.name
  }
  
  alarm_description = "This metric monitors low CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}
