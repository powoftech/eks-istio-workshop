+++
title = "Container Registry Security with Vulnerability Scanning and Policy Enforcement"
weight = 1
chapter = true
+++

## Workshop description

This comprehensive AWS workshop teaches you to build, secure, and monitor containerized applications using modern cloud-native technologies and DevSecOps practices. You'll create a complete end-to-end secure container pipeline that encompasses vulnerability scanning, policy enforcement, and runtime threat detection.

Throughout this hands-on workshop, you'll:

- **Build a secure CI/CD pipeline** using GitHub Actions that automatically builds, scans, and deploys containerized applications
- **Implement container vulnerability scanning** with Amazon ECR's integrated security features
- **Deploy policy enforcement** using Kyverno as a Kubernetes admission controller to prevent insecure workloads
- **Set up runtime threat detection** with Falco to monitor and alert on suspicious container behavior
- **Provision and manage** Amazon EKS clusters with security best practices
- **Apply DevSecOps principles** by integrating security into every stage of the development lifecycle

By the end of this workshop, you'll have a production-ready, security-first container deployment pipeline that automatically prevents vulnerable images from reaching production and detects threats in real-time.

## Intended audience

This workshop is designed for:

- **DevOps Engineers** looking to implement security controls in their container pipelines
- **Security Engineers** wanting to learn cloud-native security tools and practices
- **Platform Engineers** building secure Kubernetes platforms for development teams
- **Software Developers** interested in understanding container security and secure deployment practices
- **Cloud Architects** designing secure containerized solutions on AWS
- **Site Reliability Engineers (SREs)** implementing security monitoring and policy enforcement

## Assumed knowledge

Participants should have:

- **Basic containerization experience** with Docker (building images, running containers)
- **Fundamental Kubernetes knowledge** (pods, deployments, services, namespaces)
- **AWS foundational understanding** (basic familiarity with AWS services and concepts)
- **Command-line proficiency** in Linux/Unix environments
- **Git and GitHub experience** for version control and basic CI/CD concepts
- **YAML syntax familiarity** for Kubernetes manifests and configuration files

Previous experience with EKS, security tools, or policy engines is helpful but not required as the workshop provides step-by-step guidance.

## Time to complete the workshop

**Total Duration:** 3-4 hours

**Module Breakdown:**

- Setup and Prerequisites: 30 minutes
- Project Repository Creation: 20 minutes  
- Application and CI Workflow: 45 minutes
- EKS Cluster Provisioning: 30 minutes
- Kyverno Policy Engine Setup: 45 minutes
- Falco Runtime Security: 30 minutes
- Testing and Validation: 30 minutes
- Clean-up: 15 minutes

The workshop is designed to be completed in a single session, with natural break points after each major module. All infrastructure provisioning and deployments are included in the timing estimates.
