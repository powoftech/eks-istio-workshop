+++
title = 'Introduction'
weight = 1
pre = "<b>1.</b> "
+++

Welcome to this comprehensive AWS workshop where you'll learn to build, secure, and monitor containerized applications using modern cloud-native technologies. This hands-on workshop will guide you through creating a complete DevSecOps pipeline for Kubernetes applications.

## Amazon Elastic Container Registry (ECR)

Amazon Elastic Container Registry (ECR) is a fully managed Docker container registry that makes it easy for developers to store, manage, and deploy Docker container images. ECR is integrated with Amazon EKS and Amazon ECS, simplifying your development to production workflow.

**Key Features:**

- **Fully Managed**: No infrastructure to manage or maintain
- **Secure**: Images are encrypted at rest and in transit, with vulnerability scanning
- **Highly Available**: Built on Amazon S3 for 99.999999999% (11 9's) durability
- **Integrated**: Works seamlessly with AWS services and IAM for fine-grained access control
- **Cost-Effective**: Pay only for the storage you use with no upfront fees

In this workshop, you'll use ECR to store your containerized application images and integrate it with your CI/CD pipeline.

## Amazon Elastic Kubernetes Service (EKS)

Amazon Elastic Kubernetes Service (EKS) is a fully managed Kubernetes service that makes it easy to run Kubernetes on AWS without needing to install, operate, and maintain your own Kubernetes control plane or nodes.

**Key Benefits:**

- **Fully Managed Control Plane**: AWS manages the Kubernetes control plane, including high availability and security patches
- **Secure by Default**: Integrated with AWS IAM, VPC, and security groups
- **Highly Available**: Control plane runs across multiple Availability Zones
- **Kubernetes Compatibility**: Regular updates to support the latest Kubernetes versions
- **Integration**: Works with AWS services like ECR, ALB, EBS, EFS, and CloudWatch

In this workshop, you'll provision an EKS cluster to deploy and manage your containerized applications with advanced security and monitoring capabilities.

## GitHub Actions

GitHub Actions is a powerful CI/CD platform that allows you to automate your software development workflows directly from your GitHub repository. It enables you to build, test, and deploy your code right from GitHub.

**Key Capabilities:**

- **Workflow Automation**: Automate build, test, and deployment processes
- **Event-Driven**: Trigger workflows on GitHub events like push, pull request, or release
- **Marketplace**: Access thousands of pre-built actions from the community
- **Matrix Builds**: Test across multiple operating systems and versions simultaneously
- **Secrets Management**: Securely store and use sensitive information in workflows

In this workshop, you'll create GitHub Actions workflows to automatically build, scan, and deploy your applications to EKS.

## Kyverno Policy Engine

Kyverno is a policy engine designed for Kubernetes that allows you to manage cluster policies as code. It provides a declarative approach to policy management without requiring a new language.

**Key Features:**

- **YAML-Based Policies**: Write policies using familiar Kubernetes YAML syntax
- **Validation**: Enforce rules for resource configurations
- **Mutation**: Automatically modify resources to comply with standards
- **Generation**: Create additional resources based on policy rules
- **Reporting**: Generate policy violation reports

In this workshop, you'll use Kyverno as a cluster gatekeeper to enforce security policies and governance rules.

## Falco Runtime Security

Falco is an open-source runtime security tool that detects unexpected application behavior and alerts on threats at runtime. It acts as a security camera for your Kubernetes clusters.

**Security Capabilities:**

- **Runtime Threat Detection**: Monitor kernel calls and detect suspicious activities
- **Kubernetes-Aware**: Understand Kubernetes contexts and resources
- **Flexible Rules**: Define custom rules for your specific security requirements
- **Multiple Outputs**: Send alerts to various destinations (Slack, PagerDuty, etc.)
- **Cloud-Native**: Designed specifically for containerized environments

In this workshop, you'll deploy Falco to monitor your applications and detect potential security threats in real-time.
