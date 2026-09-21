# 1. DATA BLOCK: Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# 2. DATA BLOCK: Get subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 3. DATA BLOCK: Get available Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# 4. DATA BLOCK: Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 5. RESOURCE: Security Group
resource "aws_security_group" "web_sg" {
  name        = "${var.environment}-web-sg"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name           = "${var.environment}-web-sg"
    Environment    = var.environment
    Project        = var.project_name
    Owner          = var.environment == "prod" ? "Production" : "Development"
    ManagedBy      = "Terraform"
    DeploymentTier = var.deployment_tier
  }
}

# 6. RESOURCE: EC2 Instances
resource "aws_instance" "web" {
  count = var.instance_count

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              
              cat <<HTML > /var/www/html/index.html
              <html>
              <body>
              <h2>--------------------------------</h2>
              <h2>STARTUP APPLICATION</h2>
              <h2>--------------------------------</h2>
              <p>Environment: ${upper(var.environment)}</p>
              <p>Deployment Tier: ${upper(var.deployment_tier)}</p>
              <p>Managed by Terraform</p>
              <h2>--------------------------------</h2>
              </body>
              </html>
              HTML
              EOF

  user_data_replace_on_change = true

  tags = {
    Name           = "${var.environment}-web-server-${count.index + 1}"
    Environment    = var.environment
    Project        = var.project_name
    Owner          = var.environment == "prod" ? "Production" : "Development"
    ManagedBy      = "Terraform"
    DeploymentTier = var.deployment_tier
  }
}
