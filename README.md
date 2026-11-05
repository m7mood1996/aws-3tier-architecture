# AWS 3-Tier Architecture (Terraform)

A highly available 3-tier web architecture on AWS, built with Terraform as practice.

```
                Internet
                   │  HTTP :80
        ┌──────────▼───────────┐
        │  Application LB      │   Public subnets   10.0.1.0/24, 10.0.2.0/24
        └──────────┬───────────┘
                   │  HTTP :80 (from ALB SG only)
        ┌──────────▼───────────┐
        │  EC2 Auto Scaling    │   Private subnets  10.0.11.0/24, 10.0.12.0/24
        │  Group (1–3 x t3.micro)
        └──────────┬───────────┘
                   │  TCP :5432 (from EC2 SG only)
        ┌──────────▼───────────┐
        │  RDS PostgreSQL 15   │   Data subnets     10.0.21.0/24, 10.0.22.0/24
        │  (Multi-AZ)          │
        └──────────────────────┘
```

All tiers span two Availability Zones (`eu-north-1a` and `eu-north-1b`).

## What gets created

| File | Resources |
|------|-----------|
| [vpc.tf](vpc.tf) | VPC `10.0.0.0/16`, Internet Gateway, 2 public and 2 private subnets, public route table |
| [security.tf](security.tf) | Chained security groups: internet → ALB → EC2 → RDS |
| [load_balancer.tf](load_balancer.tf) | Internet-facing ALB, target group with health check on `/`, HTTP listener on port 80 |
| [compute.tf](compute.tf) | Launch template (Amazon Linux 2023, `t3.micro`) and an Auto Scaling Group (min 1, desired 2, max 3) in the private subnets |
| [database.tf](database.tf) | 2 isolated data subnets, DB subnet group, Multi-AZ RDS PostgreSQL 15 (`db.t3.micro`, 20 GB) |
| [outputs.tf](outputs.tf) | `alb_public_dns`, the URL to open in your browser |

### Security model

Each tier only accepts traffic from the tier directly in front of it:

- **ALB SG**: port 80 from `0.0.0.0/0`
- **EC2 SG**: port 80 from the ALB security group only
- **DB SG**: port 5432 from the EC2 security group only

The private and data subnets have no route to the internet. Because of that, the EC2 instances serve a static page with Python's built-in `http.server` instead of installing packages.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.x
- AWS credentials configured (for example with `aws configure`)

## Usage

1. Create a `secret.tfvars` file with the database password (this file is git-ignored):

   ```hcl
   db_password = "change-me-at-least-8-chars"
   ```

2. Deploy:

   ```bash
   terraform init
   terraform plan  -var-file="secret.tfvars"
   terraform apply -var-file="secret.tfvars"
   ```

3. Open the `alb_public_dns` output in your browser. You should see *"Hello from the Private Tier"*. The instances can take a few minutes to pass health checks.

4. Tear everything down when you're done to avoid charges:

   ```bash
   terraform destroy -var-file="secret.tfvars"
   ```

## Variables

| Name | Default | Description |
|------|---------|-------------|
| `aws_region` | `eu-north-1` | Deployment region |
| `db_username` | `db_admin_user` | RDS master username |
| `db_password` | none (required) | RDS master password, at least 8 characters, marked `sensitive` |

## Cost note

This is **not** fully free-tier. The Application Load Balancer and the Multi-AZ RDS deployment (which runs a standby instance) are billed by the hour. Run `terraform destroy` when you're finished.

## Known limitations

- The availability zones and AMI ID are hardcoded for `eu-north-1`, so changing `aws_region` alone won't work. The `aws_ami` data source in `compute.tf` is defined but not used yet.
- HTTP only, with no TLS certificate on the ALB.
- Terraform state is stored locally. A shared setup should use a remote backend such as S3 with locking.
- `skip_final_snapshot = true`, so database data is lost on destroy.
