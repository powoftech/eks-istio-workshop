+++
title = 'Prerequisites'
weight = 2
pre = "<b>2.</b> "
+++

Before starting this workshop, you'll need to install and configure several essential tools that will help you interact with AWS services and Kubernetes clusters. These tools form the foundation for working with containers and AWS resources, especially Amazon EKS.

## AWS CLI

The AWS Command Line Interface (CLI) is a unified tool that allows you to manage AWS services from your terminal. You'll use it to configure your AWS credentials, create and manage AWS resources, and interact with various AWS services throughout this workshop.

**Installation:** Download and install the AWS CLI from the [official AWS documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

**Configuration:** After installation, run `aws configure` to set up your access keys, default region, and output format.

## kubectl

kubectl is the Kubernetes command-line tool that allows you to run commands against Kubernetes clusters. You'll use it to deploy applications, inspect and manage cluster resources, and view logs in your EKS cluster.

**Installation:** Follow the [Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) to install kubectl for your operating system.

**Verification:** Run `kubectl version --client` to verify the installation.

## eksctl

eksctl is a command-line tool for creating and managing Kubernetes clusters on Amazon EKS. It simplifies the process of creating EKS clusters and worker nodes, handling much of the underlying AWS infrastructure setup automatically.

**Installation:** Download eksctl from the [official GitHub releases](https://github.com/eksctl-io/eksctl/releases) or use your package manager.

**Verification:** Run `eksctl version` to confirm the installation.

## Helm

Helm is a package manager for Kubernetes that helps you manage Kubernetes applications. You'll use Helm to install and configure Kyverno, Falo and other applications on your EKS cluster using pre-configured charts.

**Installation:** Install Helm following the [official Helm documentation](https://helm.sh/docs/intro/install/).

**Verification:** Run `helm version` to verify the installation.

## Docker

Docker is a containerization platform that allows you to build, package, and run applications in containers. You'll use Docker to build container images for your applications and understand how containerized workloads operate in Kubernetes environments.

**Installation:** Download and install Docker Desktop from the [official Docker website](https://docs.docker.com/get-started/get-docker/) or use your system's package manager for Docker Engine.

**Verification:** Run `docker --version` to confirm the installation and `docker run hello-world` to test that Docker can pull and run containers.

---

**Note:** Ensure all tools are added to your system's PATH and are accessible from your terminal before proceeding.
