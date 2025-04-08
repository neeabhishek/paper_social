terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.94.1"
    }
  }
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ec2_private_key" {
  filename        = var.filename
  file_permission = "0755"
  content         = tls_private_key.ec2_key.private_key_pem
}

resource "aws_key_pair" "ec2_keypair" {
  key_name   = "ec2_keypair"
  public_key = tls_private_key.ec2_key.public_key_openssh
}


resource "aws_instance" "webserver" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2_keypair.key_name
  vpc_security_group_ids = [aws_security_group.ps_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.cloudwatch_agent_profile.name

  tags = {
    Name        = "Paper_Social-${var.environment}"
    Environment = var.environment
  }

  provisioner "file" {
    source      = "${path.module}/setHostDep.sh"
    destination = "/tmp/setHostDep.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod -R 755 /tmp/setHostDep.sh",
      "sudo /tmp/setHostDep.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = var.user
    host        = aws_instance.webserver.public_ip
    timeout     = "5m"
    private_key = tls_private_key.ec2_key.private_key_pem
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update package lists
              apt-get update -y

              # Install necessary packages
              apt-get install -y wget

              # Download the CloudWatch Agent package
              wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

              # Install the CloudWatch Agent
              dpkg -i -E ./amazon-cloudwatch-agent.deb

              # Create the CloudWatch Agent configuration file
              cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOL
              {
                "agent": {
                  "metrics_collection_interval": 60,
                  "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
                },
                "logs": {
                  "logs_collected": {
                    "files": {
                      "collect_list": [
                        {
                          "file_path": "/tmp/app.log",
                          "log_group_name": "${aws_cloudwatch_log_group.ps_log_group.name}",
                          "log_stream_name": "${aws_cloudwatch_log_stream.ps_app_stream.name}"
                        }
                      ]
                    }
                  }
                }
              }
              EOL

              # Start the CloudWatch Agent
              amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
              EOF

}

resource "aws_security_group" "ps_sg" {
  name        = "paper_social_sg"
  description = "paper_social_sg"

  ingress {
    description = "Allow SSH Port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_blocks]
  }

  ingress {
    description = "Allow web-application Port"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.cidr_blocks]
  }

  egress {
    description = "Allow HTTPS port"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_blocks]
  }
  egress {
    description = "Allow Port 80 for fetching Ubuntu repo"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_blocks]
  }
}

resource "aws_cloudwatch_log_group" "ps_log_group" {
  name              = "PS_LogGroup"
  retention_in_days = 3
}
resource "aws_cloudwatch_log_stream" "ps_app_stream" {
  name           = "ps_app"
  log_group_name = aws_cloudwatch_log_group.ps_log_group.name
}
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "high_cpu_utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors high CPU utilization"
  alarm_actions       = [aws_sns_topic.alarm_notifications.arn]
}
resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  alarm_name          = "high_memory_utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors high memory utilization"
  alarm_actions       = [aws_sns_topic.alarm_notifications.arn]
}
resource "aws_sns_topic" "alarm_notifications" {
  name = "alarm-notification"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_iam_role" "cloudwatch_agent_role" {
  name = "cloudwatch_agent_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_policy_attachment" "cloudwatch_agent_policy_attach" {
  name       = "cloudwatch_agent_policy_attach"
  roles      = [aws_iam_role.cloudwatch_agent_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cloudwatch_agent_profile" {
  name = "cloudwatch_agent_profile"
  role = aws_iam_role.cloudwatch_agent_role.name
}
