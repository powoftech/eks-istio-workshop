+++
title = 'Clean up resources'
weight = 8
pre = "<b>8.</b> "
+++

## Overview

After completing the workshop, or if you encounter any deployment failures, you should clean up your AWS resources to prevent unnecessary charges. This guide provides step-by-step instructions for properly removing all deployed resources.

## Cleanup Process

Follow these steps in the specified order to ensure all resources are properly deleted:

### Step 1: Delete EKS Cluster

In your `secure-container-pipeline` project directory, run the following `eksctl` command:

```bash
eksctl delete cluster -f k8s/cluster.yaml --wait --disable-nodegroup-eviction --force --parallel 4
```

### Step 2: Delete ECR Repository

Run the AWS CLI command in your terminal:

```bash
aws ecr delete-repository \
--repository-name workshop-app \
--region us-east-2 # Use the same region as your cluster
```

### Step 3: Delete IAM _Role_ and _Identity provider_

- **In the AWS Console, go to IAM <kbd>&rarr;</kbd> Roles.**
  - Select `WorkshopGitHubActionsRole` role.
  - Click **Delete**.
  - Enter the role name to confirm deletion.
  - Click **Delete**.
- **Go to IAM <kbd>&rarr;</kbd> Roles**
  - Select `token.actions.githubusercontent.com` provider.
  - Click **Delete**.
  - Type `confirm` to confirm removal.
  - Click **Delete**.
