# Network Design

> AWS Region: United States (Ohio) - `us-east-2`
>
> EKS version: `1.33`

- **VPC CIDR:** 10.0.0.0/16
- **Availability Zones:** 3 (us-east-2a, us-east-2b, us-east-2c)

## Subnets

### Private

- **Private Subnet 1 (AZ a):** 10.0.0.0/20
- **Private Subnet 2 (AZ b):** 10.0.16.0/20
- **Private Subnet 3 (AZ c):** 10.0.32.0/20

### Public

- **Public Subnet 1 (AZ a):** 10.0.48.0/24
- **Public Subnet 2 (AZ b):** 10.0.49.0/24
- **Public Subnet 3 (AZ c):** 10.0.50.0/24

### Intra

- **Intra Subnet 1 (AZ a):** 10.0.52.0/24
- **Intra Subnet 2 (AZ b):** 10.0.53.0/24
- **Intra Subnet 3 (AZ c):** 10.0.54.0/24
