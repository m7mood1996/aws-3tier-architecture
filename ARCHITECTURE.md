# 🗺️ Three-Tier Highly Available AWS Architecture

This document blueprints the production-grade network topologies and component interactions deployed via our Terraform stack. The design is structured to satisfy the **Design Resilient Architectures** and **Design Secure Architectures** domains of the **AWS Certified Solutions Architect – Associate (SAA-C03)** exam.

---

## 🏗️ Visual Component & Network Blueprint

```text
                        [ Public Internet Client ]
                                     │
                                     ▼ (HTTP Port 80)
┌─────────────────────────────────────────────────────────────────────────┐
│ 🌐 PUBLIC TIER: Application Load Balancer (ALB)                         │
│                                                                         │
│    [ Public Subnet 1 (AZ-A) ]            [ Public Subnet 2 (AZ-B) ]     │
│    ┌────────────────────────┐            ┌────────────────────────┐     │
│    │    ALB Routing Node    │            │    ALB Routing Node    │     │
│    └───────────┬────────────┘            └───────────┬────────────┘     │
└────────────────┼─────────────────────────────────────┼──────────────────┘
                 └──────────────────┬──────────────────┘
                                    ▼ (Security Group Chaining Connection)
┌─────────────────────────────────────────────────────────────────────────┐
│ 💻 PRIVATE TIER: Auto Scaling Group (EC2 Instances)                     │
│                                                                         │
│    [ Private Subnet 1 (AZ-A) ]           [ Private Subnet 2 (AZ-B) ]    │
│    ┌────────────────────────┐            ┌────────────────────────┐     │
│    │ 🖥️ EC2 App Server      │            │ 🖥️ EC2 App Server      │     │
│    └───────────┬────────────┘            └───────────┬────────────┘     │
└────────────────┼─────────────────────────────────────┼──────────────────┘
                 └──────────────────┬──────────────────┘
                                    ▼ (PostgreSQL Port 5432)
┌─────────────────────────────────────────────────────────────────────────┐
│ 🗄️ DATA TIER: Amazon RDS PostgreSQL Cluster                             │
│                                                                         │
│    [ Data Subnet 1 (AZ-A) ]              [ Data Subnet 2 (AZ-B) ]       │
│    ┌────────────────────────┐            ┌────────────────────────┐     │
│    │ 🗄️ Primary DB (Active) │───────────►│ 🗄️ Standby DB (Passive)│     │
│    └────────────────────────┘ Synchronous└────────────────────────┘     │
│                              Replication                                │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🚦 Traffic & Connection Mechanics

### 1. Public Tier (Ingress)
* **Resource:** `aws_lb.external_alb` (Shared cross-AZ DNS endpoint).
* **Network Target:** Traffic enters the `public_1` and `public_2` subnets from the public internet via the **Internet Gateway (IGW)**.
* **Firewall Layer:** `aws_security_group.alb_sg` permits open incoming traffic strictly on `TCP Port 80`.

### 2. Private Tier (Compute)
* **Resource:** `aws_autoscaling_group.app_asg` containing `t3.micro` EC2 instances.
* **Network Target:** Isolated inside `private_1` and `private_2` subnets. They possess no public IP addresses.
* **Firewall Layer:** `aws_security_group.ec2_sg` uses **Security Group Chaining**. It explicitly drops any internet traffic unless the data packet originates directly from the `alb_sg` firewall layer.

### 3. Data Tier (Storage)
* **Resource:** `aws_db_instance.postgres` (`multi_az = true`).
* **Network Target:** Deeply isolated within `data_1` and `data_2` subnets via `aws_db_subnet_group.db_segments`.
* **Firewall Layer:** `aws_security_group.db_sg` rejects all network requests except for SQL connections over `TCP Port 5432` originating solely from the private application EC2 instances.
* **High Availability Link:** The passive Standby instance does **not** process client queries. It receives data exclusively via a synchronous AWS-managed background replication loop originating from the active Primary DB.
