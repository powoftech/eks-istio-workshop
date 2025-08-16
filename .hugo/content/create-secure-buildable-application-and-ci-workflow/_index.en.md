+++
title = 'Create a Secure, Buildable Application and a CI Workflow'
weight = 4
pre = "<b>4.</b> "
+++

## Create the Sample Application and Dockerfile

First, we need something to build. We'll create a very simple Node.js "Hello World" application and a security-conscious Dockerfile.

1. **In your `secure-container-pipeline` project directory, create a new folder named `app`.**

   ```bash
   mkdir app
   cd app
   ```

2. **Create the Node.js application file `app.js`:**

   ```bash
   # In the 'app' directory
   touch app.js
   ```

   Paste this simple server code into `app/app.js`:

   ```javascript
   // app/app.js
   const http = require("http");
   const port = 8080;

   const server = http.createServer((req, res) => {
     res.statusCode = 200;
     res.setHeader("Content-Type", "text/plain");
     res.end("Hello, FCJ-ers!\n");
   });

   server.listen(port, () => {
     console.log(`Server running on port ${port}`);
   });
   ```

3. **Create the `Dockerfile`:**

   ```Dockerfile
   # app/Dockerfile
   # Stage 1: Use a specific, slim base image to reduce attack surface.
   FROM node:22-slim AS base

   # Create a dedicated, non-root user and group for the application.
   # This is a critical security measure.
   RUN addgroup --system --gid 1001 nodejs
   RUN adduser --system --uid 1001 appuser

   WORKDIR /home/appuser/app

   # Copy only the necessary file and set correct permissions.
   COPY --chown=appuser:nodejs app.js .

   # Switch to the non-root user. Any subsequent commands run as this user.
   USER appuser

   # Expose the port the app runs on.
   EXPOSE 8080

   # Command to run the application.
   CMD [ "node", "app.js" ]
   ```

4. **Go back to the root of your project directory:**

   ```bash
   cd ..
   ```

## Create the ECR Repository

Let's create the secure container registry where we'll store our Docker images.

1. **Run this AWS CLI command** in your terminal:

   ```bash
   aws ecr create-repository \
   --repository-name workshop-app \
   --image-scanning-configuration scanOnPush=true \
   --region us-east-2 # Use the same region as your cluster
   ```

   {{% notice info %}}
   The `--image-scanning-configuration scanOnPush=true` flag is our first deliberate security control. We've instructed AWS to automatically scan every new image we push to this repository for known vulnerabilities (CVEs). This is a foundational piece of our secure pipeline.
   {{% /notice %}}

## Set Up Secure Access from GitHub Actions to AWS (OIDC)

We need to grant GitHub the permission to push images to our ECR repository. We will use the modern, secure, passwordless method: OIDC (OpenID Connect).

1. **In the AWS Console, go to IAM <kbd>&rarr;</kbd> Identity providers.**
   - Click **Add provider**.
   - Select **OpenID Connect**.
   - For **Provider URL**, enter `https://token.actions.githubusercontent.com`.
   - For **Audience**, enter `sts.amazonaws.com`.
   - Click **Add provider**.
2. **Create the IAM Role for GitHub Actions**.
   - Go to **IAM <kbd>&rarr;</kbd> Roles <kbd>&rarr;</kbd> Create role**.
   - For **Trusted entity type**, select **Web identity**.
   - From the **Identity provider** dropdown, select the `token.actions.githubusercontent.com` provider you just created.
   - For **Audience**, select `sts.amazonaws.com`.
   - For **GitHub organization/repository**, enter your details. For a personal project, you can be specific:
     - Organization: `your-github-username`
     - Repository: `secure-container-pipeline`
     - (Optional but recommended) Branch: `main` or `master`
   - Click **Next**.
   - On the **Add permissions** screen, find and attach the `AmazonEC2ContainerRegistryPowerUser` policy. This gives just enough permission to log in and push images to ECR.
   - Click **Next**.
   - Give the role a name, like `WorkshopGitHubActionsRole` _(Remember the role name. You will use this role to deploy to the EKS cluster later)_
   - Create the role.
   - **CRITICAL**: Click on the new role you just created and copy its ARN. It will look like `arn:aws:iam::<<AWS Account ID>>:role/WorkshopGitHubActionsRole`. You will need this for the next step.

## Create the GitHub Actions CI Workflow

This is the heart of our automated build and scan process.

1. **Create the workflow directory structure:**

   ```bash
   mkdir -p .github/workflows
   ```

2. **Create the workflow file `ci.yml`:**

   ```bash
   touch .github/workflows/ci.yml
   ```

3. **Paste the following YAML into `.github/workflows/ci.yml`.** Replace the placeholder with your actual Role ARN.

   ```yaml
   # .github/workflows/ci.yml
   name: CI Workflow for EKS Workshop

   # This workflow runs on any push to the main branch
   on:
     push:
       branches: [main]
     # Allows you to run this workflow manually from the Actions tab
     workflow_dispatch:

   env:
     AWS_REGION: us-east-2 # Your AWS region
     ECR_REPOSITORY: workshop-app # Your ECR repository name
     EKS_CLUSTER_NAME: workshop-cluster # Your EKS cluster name

   jobs:
     build-scan-push:
       name: Build, Scan & Push
       runs-on: ubuntu-latest
       outputs:
         image: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ steps.image-def.outputs.tag }}
       permissions:
         # Required for OIDC connection to AWS
         id-token: write
         contents: read

       steps:
         - name: Checkout repository
           uses: actions/checkout@v5

         - name: Configure AWS credentials
           uses: aws-actions/configure-aws-credentials@v4
           with:
             role-to-assume: arn:aws:iam::<<AWS Account ID>>:role/WorkshopGitHubActionsRole # <-- PASTE YOUR ROLE ARN HERE
             aws-region: ${{ env.AWS_REGION }}

         - name: Login to Amazon ECR
           id: login-ecr
           uses: aws-actions/amazon-ecr-login@v2

         - name: Define image tag
           id: image-def
           run: echo "tag=${{ github.sha }}" >> $GITHUB_OUTPUT

         - name: Build, tag, and push image to Amazon ECR
           id: build-image
           env:
             ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
             IMAGE_TAG: ${{ steps.image-def.outputs.tag }}
           run: |
             docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG -f app/Dockerfile ./app
             docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

         - name: Security Scan with Trivy
           uses: aquasecurity/trivy-action@master
           with:
             image-ref: "${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ steps.image-def.outputs.tag }}"
             format: "table"
             # Fail the build if Trivy finds any HIGH or CRITICAL severity vulnerabilities
             exit-code: "1"
             ignore-unfixed: true
             vuln-type: "os,library"
             severity: "CRITICAL,HIGH"
   ```

4. **Commit and push to trigger the workflow**

   - **Add all your new files to Git, commit them, and push:**

     ```bash
     git add .
     git commit -m "feat: Add sample app, Dockerfile, and initial CI workflow"
     git push origin main
     ```

   - **Observe the magic!** Go to your GitHub repository, click on the **Actions** tab. You will see your workflow running. Click on it to see the logs for each step. It will:
     - Check out the code.
     - Securely connect to AWS.
     - Log in to ECR.
     - Build and push your Docker image.
     - **Crucially, it will then run Trivy to scan the image you just pushed.**
