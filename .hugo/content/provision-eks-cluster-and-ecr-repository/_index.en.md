+++
title = 'Provision the EKS Cluster and Automate Deployment'
weight = 5
pre = "<b>5.</b> "
+++

## Create the EKS Cluster Configuration

We will use `eksctl` to build the cluster. The best practice is to define the cluster in a configuration file, which you can then commit to your Git repository for version control and reproducibility.

1. **In the root of your project directory, create a new folder named `k8s`.**

   ```bash
   mkdir k8s
   cd k8s
   ```

2. **Create a new file named `cluster.yaml`**

3. **Paste the following content into `cluster.yaml`.** Read the comments to understand what each line does

   ```yaml
   # k8s/cluster.yaml
   apiVersion: eksctl.io/v1alpha5
   kind: ClusterConfig

   metadata:
     # The name of your cluster
     name: workshop-cluster
     # The AWS region where the cluster will be created
     region: us-east-2
     # The Kubernetes version of your cluster
     version: "1.33"

   # This section defines the Kubernetes worker nodes
   nodeGroups:
     - name: ng-1-workers # Name for the node group
       instanceType: t3.medium # A default general-purpose instance type.
       desiredCapacity: 2 # Start with 2 nodes for high availability
       minSize: 1 # For cost savings, you can scale down to 1 node when not actively testing
       maxSize: 3 # Limit max size to prevent accidental cost overruns
       # Recommended: Use AWS's Bottlerocket OS for better security and smaller footprint
       amiFamily: Bottlerocket
       # Recommend: Launch nodegroup in private subnets
       privateNetworking: true

   accessConfig:
     authenticationMode: API_AND_CONFIG_MAP
     # Create an EKS access entry to help GitHub Actions workflow can deploy to the cluster
     accessEntries:
       # IMPORTANT: Repalce <<AWS Account ID>> with your AWS Account ID
       - principalARN: arn:aws:iam::<<AWS Account ID>>:role/WorkshopGitHubActionsRole
         accessPolicies:
           - policyARN: arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy
             accessScope:
               type: cluster
   ```

## Launch the EKS Cluster

Now, execute the command to build the cluster.

1. **Open your terminal** in the `secure-container-pipeline` directory.

2. **Run the creation command:**

   ```bash
   eksctl create cluster -f k8s/cluster.yaml
   ```

3. **Be patient.** This process will take 15-20 minutes. `eksctl` will print out a lot of information as it provisions the resources in AWS CloudFormation. Go grab a coffee.

4. **Confirmation:** Once it's finished, `eksctl` will automatically update your local `kubeconfig` file (`~/.kube/config`). This means `kubectl` will now point to your new EKS cluster.

## Verify Cluster Access

Let's make sure you can talk to your new cluster.

1. **Run this `kubectl` command:**

   ```bash
   kubectl get nodes
   ```

2. You should see an output listing your two worker nodes, similar to this:

   ```text
   NAME                                            STATUS   ROLES    AGE     VERSION
   ip-192-168-158-45.us-east-2.compute.internal    Ready    <none>   6m16s   v1.33.1-eks-b9364f6
   ip-192-168-173-179.us-east-2.compute.internal   Ready    <none>   6m21s   v1.33.1-eks-b9364f6
   ```

## Create Kubernetes Deployment Manifests

We need to tell Kubernetes how to run our application. We'll do this with two standard Kubernetes resource files: a Deployment (to manage the application Pods) and a Service (to expose the application to traffic).

1. **In the root of your project directory, create a new folder named `k8s`.**

   ```bash
   mkdir k8s
   cd k8s
   ```

2. **Create the `deployment.yaml` file:**

   ```bash
   # In the 'k8s' directory
   touch deployment.yaml
   ```

   Paste this content into k8s/deployment.yaml. Pay close attention to the ##IMAGE_TAG_PLACEHOLDER## line; we will replace this dynamically in our pipeline.

   ```yaml
   # k8s/deployment.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: workshop-app
     labels:
       app: workshop-app
   spec:
     replicas: 2 # Run two instances for availability
     selector:
       matchLabels:
         app: workshop-app
     template:
       metadata:
         labels:
           app: workshop-app
       spec:
         containers:
           - name: workshop-app
             # IMPORTANT: This is a placeholder. Our pipeline will replace it.
             image: "IMAGE_PLACEHOLDER"
             ports:
               - containerPort: 8080
             # --- Security Context ---
             # This enforces security best practices at the container level.
             securityContext:
               # Prevents the container from gaining more privileges than its parent process.
               allowPrivilegeEscalation: false
               # Runs the container with a read-only root filesystem.
               readOnlyRootFilesystem: true
               # Reinforcing our Dockerfile's non-root user.
               runAsNonRoot: true
               # Specifies the user and group IDs to run as, matching our Dockerfile.
               runAsUser: 1001
               runAsGroup: 1001
               # Drops all Linux capabilities and only adds back what's necessary (none in this case).
               capabilities:
                 drop:
                   - "ALL"
         # Location for temporary files, as the root filesystem is read-only.
         volumes:
           - name: tmp
             emptyDir: {}
   ```

3. **Create the `service.yaml` file:**

   ```bash
   # In the 'k8s' directory
   touch service.yaml
   ```

   Paste this content into `k8s/service.yaml`. This will create a `LoadBalancer` service, which automatically provisions an AWS Network Load Balancer to expose your application to the internet.

   ```yaml
   # k8s/service.yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: workshop-app-service
   spec:
     selector:
       app: workshop-app
     # This type creates an external AWS Load Balancer
     type: LoadBalancer
     ports:
       - protocol: TCP
         port: 80 # The port the load balancer listens on
         targetPort: 8080 # The port the container listens on
   ```

4. **Go back to the root of your project directory:**

   ```bash
   cd ..
   ```

## Update the IAM Role for Deployment Permissions

Our `WorkshopGitHubActionsRole` can push to ECR, but it can't talk to our EKS cluster yet. We need to grant it permission.

1. **In the AWS Console, go to IAM <kbd>&rarr;</kbd> Roles <kbd>&rarr;</kbd>.**

   - Select `WorkshopGitHubActionsRole` role.
   - In **Permissions** tab, **Permissions policies** section, select **Add permissions <kbd>&rarr;</kbd> Create inline policy**.
   - For **Policy editor**, select **JSON**, paste the following policy and replace the AWS account ID:

     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Sid": "Statement1",
           "Effect": "Allow",
           "Action": "eks:DescribeCluster",
           "Resource": "arn:aws:eks:us-east-2:<<AWS Account ID>>:cluster/workshop-cluster"
         }
       ]
     }
     ```

   - Click **Next**.
   - Give the policy a name, like `DescribeWorkshopEKSCluster`.
   - Create the policy.

## Update the GitHub Actions Workflow to Deploy

Now, we'll add a new `deploy` job to our `ci.yml` file.

1. **Open `.github/workflows/ci.yml`.**
2. **Add the new `deploy` job** to the end of the file. The complete, updated file should look like this:

    ```yaml
    # .github/workflows/ci.yml

    # ... (other params omitted) ...

    jobs:
      build-scan-push:
        # ... (the build-scan-push job remains exactly the same as before) ...

      # ---- NEW DEPLOY JOB ----
      deploy:
        # This job will only run if the 'build-scan-push' job succeeds
        name: Deploy to EKS
        needs: build-scan-push
        runs-on: ubuntu-latest
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

          - name: Set up Kubeconfig for EKS
            run: aws eks update-kubeconfig --name ${{ env.EKS_CLUSTER_NAME }} --region ${{ env.AWS_REGION }}

          - name: Substitute image tag in Kubernetes manifest
            run: |
              sed -i 's|IMAGE_PLACEHOLDER|${{ needs.build-scan-push.outputs.image }}|' k8s/deployment.yaml

          - name: Deploy to EKS cluster
            run: |
              echo "--- Applying deployment.yaml ---"
              cat k8s/deployment.yaml
              kubectl apply -f k8s/deployment.yaml

              echo "--- Applying service.yaml ---"
              kubectl apply -f k8s/service.yaml
    ```

    **Key Changes:**

    - A new `deploy` job is added.
    - `needs: build-scan-push` ensures deployment only happens after a successful build and scan.
    - The `sed` command is a crucial step that finds our `IMAGE_PLACEHOLDER` and replaces it with the actual, unique image URI from the build step.
    - `kubectl apply` sends our configuration to the EKS cluster.

3. **Commit, push, and verify deployment:**

   - **Commit your changes:**

      ```bash
      git add .
      git commit -m "feat: Add k8s manifests and deploy job to CI workflow"
      git push origin main
      ```

   - **Watch the pipeline:** Go to the **Actions** tab in GitHub. You'll see the full pipeline run. This time, after "Build, Scan & Push" completes, the "Deploy to EKS" job will start.
   - **Verify in your terminal:** Once the pipeline succeeds, check the status of your deployment.
      - Check the pods:

         ```bash
         kubectl get pods -l app=workshop-app
         ```

         You should see two pods with a `Running` status.
      - Check the service and get the Load Balancer URL:

         ```bash
         kubectl get service workshop-app-service
         ```

         It will take a minute or two for AWS to provision the load balancer. The `EXTERNAL-IP` will change from `<pending>` to a long DNS name.
   - **Test the application!** Copy the `EXTERNAL-IP` DNS name and paste it into your web browser. You should see the message: `Hello, FCJ-ers!`
