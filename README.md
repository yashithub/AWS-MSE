# Terraform-Based Multi-Environment Application Infrastructure for a Startup

## 1. Project Objective
This project demonstrates how a startup can use a **single Terraform codebase** to provision isolated Development and Production AWS environments by leveraging Terraform Workspaces and variables.

## 2. Real-World Use Case
A small startup needs to deploy a simple web application. The application requires two separate environments:
*   **DEVELOPMENT**: A low-cost environment (using a single `t3.micro` instance) for developers to test new features.
*   **PRODUCTION**: A high-availability environment (using three `t3.small` instances spread across different Availability Zones) for real users.

Instead of writing separate Terraform code for Dev and Prod (which leads to duplication and errors), we use a single set of Terraform files. We use **Terraform Workspaces** to keep the infrastructure state isolated, and `.tfvars` files to pass environment-specific configurations.

## 3. Simple Architecture Diagram

```text
Same Terraform Codebase (main.tf)
       │
       ├─► Workspace: dev + terraform.tfvars.dev
       │      └── AWS: 1 × t3.micro EC2 (AZ: us-east-1a)
       │
       └─► Workspace: prod + terraform.tfvars.prod
              ├── AWS: 1 × t3.small EC2 (AZ: us-east-1a)
              ├── AWS: 1 × t3.small EC2 (AZ: us-east-1b)
              └── AWS: 1 × t3.small EC2 (AZ: us-east-1c)
```

## 4. File Structure
```
terraform-multi-env/
├── main.tf                 # Core AWS infrastructure definitions (EC2, SG, Data sources)
├── variables.tf            # Variable declarations (environment, instance_type, etc.)
├── terraform.tf            # Provider configuration and required versions
├── outputs.tf              # Outputs to display after applying (IPs, DNS, IDs)
├── terraform.tfvars.dev    # Values for the DEV environment
├── terraform.tfvars.prod   # Values for the PROD environment
└── README.md               # Project documentation and viva guide
```

## 5. Dev vs Prod Comparison

| Feature | DEV Workspace | PROD Workspace |
| :--- | :--- | :--- |
| **Instance Count** | 1 | 3 |
| **Instance Type** | `t3.micro` | `t3.small` |
| **Availability Zones**| Any single AZ | Distributed across 3 available AZs |
| **Deployment Tier** | testing | production |
| **Owner Tag** | Development | Production |

## 6. Important Terraform Concepts Explained
*   **Terraform**: An Infrastructure as Code (IaC) tool used to define and provision cloud resources safely and predictably.
*   **Terraform Workspace**: A feature that allows you to manage multiple distinct sets of infrastructure resources from the same working directory. Each workspace has its own isolated state file.
*   **Terraform Variable**: A way to parameterize your Terraform configurations, making your code reusable and dynamic.
*   **tfvars file**: A file containing actual values for variables. We use different files (`.tfvars.dev` and `.tfvars.prod`) to inject different configurations into our single codebase.
*   **Terraform Data Block**: A way to fetch information about existing resources in AWS (like finding the default VPC, subnets, or the latest AMI) without hardcoding IDs.
*   **Terraform Resource**: A block that defines a piece of infrastructure you want to create, such as an EC2 instance or a Security Group.
*   **Terraform State**: A file that Terraform uses to map real-world cloud resources to your configuration files.
*   **user_data**: A script that runs automatically when an EC2 instance first boots up.

## 7. Unique Project Features

### Production Distributed Across Availability Zones
High availability is crucial for Production. Instead of putting all three production instances in the same data center (Availability Zone), the configuration uses the `aws_availability_zones` data block. It dynamically loops through the available AZs using a mathematical modulo operation (`count.index % length(...)`) to distribute the EC2 instances. If one AZ fails, the application remains available in others.

### Environment-Aware Startup Webpage
To easily verify that the deployment worked and that the correct variables were used, a simple bash script is passed to the EC2 instances via `user_data`. This script installs a lightweight web server (Apache/httpd) and creates a custom HTML index page that displays the current environment (DEVELOPMENT or PRODUCTION) and the deployment tier directly on the webpage.

## 8. Exact Commands to Run

### Step 1: Initialize Terraform
```bash
terraform init
```

### Step 2: Create Workspaces
```bash
terraform workspace new dev
terraform workspace new prod
terraform workspace list
```

### Step 3: Plan and Apply Development
```bash
terraform workspace select dev
terraform plan -var-file="terraform.tfvars.dev"
terraform apply -var-file="terraform.tfvars.dev"
```

### Step 4: Plan and Apply Production
```bash
terraform workspace select prod
terraform plan -var-file="terraform.tfvars.prod"
terraform apply -var-file="terraform.tfvars.prod"
```

### Step 5: Formatting and Validation (Optional but recommended)
```bash
terraform fmt
terraform validate
```

## 9. Expected Outputs
When the apply finishes, you will see useful outputs like:
*   `environment_info`: Showing the workspace, tier, and instance count.
*   `instance_ids`: The AWS IDs of the created instances.
*   `public_ips`: The public IPs of the instances.
*   `public_dns`: The public DNS names.
*   `vpc_subnets`: The subnets queried dynamically.

If you paste one of the `public_ips` into your web browser, you will see the simple environment-aware text page confirming your deployment.

## 10. Simple Viva Questions and Answers

**Q1: What is Terraform?**
A: It is an Infrastructure as Code (IaC) tool that allows us to provision and manage cloud infrastructure using human-readable configuration files.

**Q2: Why did you choose Terraform for this project?**
A: To easily manage multi-environment infrastructure (Dev and Prod) from a single reusable codebase in an automated, repeatable way.

**Q3: What is a Terraform workspace?**
A: Workspaces allow us to manage multiple separate deployments of the same Terraform code by keeping their state files completely isolated from each other.

**Q4: Why are Dev and Prod using different workspaces?**
A: So that changes to the Dev infrastructure don't accidentally modify or destroy the Prod infrastructure. They maintain separate Terraform states.

**Q5: What is Terraform state?**
A: It is a file (`terraform.tfstate`) that Terraform uses to track which real-world AWS resources correspond to the resources defined in the code.

**Q6: What is a data block?**
A: A data block is used to query and fetch information from AWS about existing resources, like finding the default VPC ID or the latest Linux AMI.

**Q7: Why should AWS resource IDs not be hardcoded?**
A: Hardcoding IDs (like AMI or VPC IDs) makes the code rigid. If an AMI is deprecated or if you move to a different AWS region/account, hardcoded IDs will break the code. Data blocks make it dynamic and region-agnostic.

**Q8: Why do Dev and Prod have different tfvars?**
A: Because they require different configurations. Dev needs fewer, cheaper resources (1 x t3.micro), while Prod needs more resources for real traffic (3 x t3.small).

**Q9: What does terraform plan do?**
A: It shows an execution plan, detailing exactly what resources Terraform will create, modify, or destroy, without actually making any changes to AWS yet.

**Q10: Why does Prod have 3 instances distributed across Availability Zones?**
A: For High Availability (HA) and fault tolerance. If one Availability Zone (data center) goes offline, the other instances in different AZs will keep the application running.

**Q11: What is user_data and why are we using it?**
A: It is a bootstrap script that runs when an EC2 instance boots. We use it to automatically install a web server and generate a simple webpage that proves the correct environment was provisioned.

**Q12: What would happen if a developer changed the Dev infrastructure code (main.tf) to use an expensive instance type?**
A: Because Dev and Prod share `main.tf`, if it was hardcoded, Prod would be affected too. However, since we use variables, the developer only changes the `terraform.tfvars.dev` file, safely keeping the Prod configuration intact.
