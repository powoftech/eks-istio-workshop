# Network Design

> AWS Region: United States (Ohio) - `us-east-2`

> EKS version: `1.33`

- **VPC CIDR:** 10.0.0.0/16
- **Availability Zones:** 3 (us-east-2a, us-east-2b, us-east-2c)

## Subnets

- **Private Subnet 1 (AZ a):** 10.0.0.0/19
- **Private Subnet 2 (AZ b):** 10.0.32.0/19
- **Private Subnet 3 (AZ c):** 10.0.64.0/19

- **Public Subnet 1 (AZ a):** 10.0.128.0/20
- **Public Subnet 2 (AZ b):** 10.0.144.0/20
- **Public Subnet 3 (AZ c):** 10.0.160.0/20
