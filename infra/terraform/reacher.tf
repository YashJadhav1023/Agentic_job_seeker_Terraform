locals {
  reacher_is_arm = startswith(var.reacher_instance_type, "t4g.")
  reacher_ami_param = format(
    "/aws/service/canonical/ubuntu/server/24.04/stable/current/%s/hvm/ebs-gp3/ami-id",
    local.reacher_is_arm ? "arm64" : "amd64"
  )
}

data "aws_ssm_parameter" "reacher_ubuntu" {
  count = var.enable_reacher ? 1 : 0
  name  = local.reacher_ami_param
}

# Dedicated security group for Reacher
resource "aws_security_group" "reacher" {
  count       = var.enable_reacher ? 1 : 0
  name        = "${var.name}-reacher-sg"
  description = "Reacher Email Verification: internal HTTP 3000 + outbound SMTP 25"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.name}-reacher-sg"
  }
}

# Ingress: Allow JobHub main instance to query Reacher API on port 3000
resource "aws_vpc_security_group_ingress_rule" "reacher_from_jobhub" {
  count                        = var.enable_reacher ? 1 : 0
  security_group_id            = aws_security_group.reacher[0].id
  referenced_security_group_id = aws_security_group.this.id
  ip_protocol                  = "tcp"
  from_port                    = 3000
  to_port                      = 3000
  description                  = "Internal HTTP from JobHub host"
}

# Egress: Allow Reacher to connect anywhere (specifically port 25 SMTP and port 53 DNS)
resource "aws_vpc_security_group_egress_rule" "reacher_all_egress" {
  count             = var.enable_reacher ? 1 : 0
  security_group_id = aws_security_group.reacher[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound traffic for SMTP probe and package updates"
}

# Reacher EC2 instance
resource "aws_instance" "reacher" {
  count                  = var.enable_reacher ? 1 : 0
  ami                    = data.aws_ssm_parameter.reacher_ubuntu[0].value
  instance_type          = var.reacher_instance_type
  subnet_id              = local.usable_subnets[0]
  vpc_security_group_ids = [aws_security_group.reacher[0].id]
  iam_instance_profile   = aws_iam_instance_profile.this.name # SSM access for remote management

  root_block_device {
    volume_size           = 15
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    apt-get update && apt-get install -y docker.io
    systemctl enable --now docker
    docker run -d --restart unless-stopped --name reacher -p 3000:3000 reacherhq/check-if-email-exists:latest
  EOF

  tags = {
    Name = "${var.name}-reacher"
    Role = "email-verification"
  }
}

# Elastic IP for Reacher so outbound mail verification has a static IP (for PTR/rDNS and AWS port 25 unblock)
resource "aws_eip" "reacher" {
  count  = var.enable_reacher ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.name}-reacher-eip"
  }
}

resource "aws_eip_association" "reacher" {
  count         = var.enable_reacher ? 1 : 0
  instance_id   = aws_instance.reacher[0].id
  allocation_id = aws_eip.reacher[0].id
}
