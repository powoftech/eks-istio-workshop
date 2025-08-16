+++
title = 'Install and Configure Kyverno as a Cluster Gatekeeper'
weight = 6
pre = "<b>6.</b> "
+++

Our goal here is to make the cluster self-defending. The pipeline we built is great, but it doesn't stop someone with kubectl access from manually deploying an insecure container. We will now install a gatekeeper--an admission controller--to enforce our rules on every single workload that tries to run on the cluster.

Our tool for this is **Kyverno**. It's powerful, Kubernetes-native, and the policies are just simple YAML, making it perfect for our project.

## Install Kyverno using Helm

Helm is the best way to install and manage complex applications like Kyverno on Kubernetes.

1. **Open your terminal**, ensuring your `kubectl` context is pointing to your `workshop-cluster`.
2. **Add the Kyverno Helm repository:**

   ```bash
   helm repo add kyverno https://kyverno.github.io/kyverno/
   ```

3. **Update your Helm repositories** to fetch the new chart information:

   ```bash
   helm repo update
   ```

4. **Install Kyverno** into its own dedicated namespace. This is a best practice for cluster-wide tools.

   ```bash
   helm install kyverno kyverno/kyverno -n kyverno --create-namespace
   ```

5. **Verify the installation.** It might take a minute for all the Kyverno pods to be ready.

   ```bash
   kubectl get pods -n kyverno
   ```

   You should see several pods, including the admission controller, background controller, and cleanup controller, all in a Running state.

## Create Your First Security Policies

Now for the powerful part. We'll define our security rules as `ClusterPolicy` resources. These are cluster-wide rules.

1. **In your project's k8s directory, create a new file named `policy-disallow-latest-tag.yaml`:**

   ```bash
   # In the k8s directory
   touch policy-disallow-latest-tag.yaml
   ```

   Paste the following policy. This is a fundamental best practice: it prevents ambiguous deployments and forces the use of specific, immutable tags (like the Git SHA we use in our pipeline).

   ```yaml
   # k8s/policy-disallow-latest-tag.yaml
   apiVersion: kyverno.io/v1
   kind: ClusterPolicy
   metadata:
     name: disallow-latest-tag
   spec:
     # This rule applies to all Pods, Deployments, StatefulSets, etc.
     validationFailureAction: Enforce
     background: true
     rules:
       - name: require-not-latest-tag
         match:
           any:
             - resources:
                 kinds:
                   - Pod
         validate:
           message: "Using the 'latest' image tag is a security risk and is not allowed. Please use a specific image tag."
           pattern:
             spec:
               containers:
                 # This pattern says "the image field of ANY container MUST NOT end with :latest"
                 - image: "!*:latest"
   ```

   {{% notice info %}}
   `validationFailureAction: Enforce` is the key. It tells Kyverno to **block** any API request that violates this rule. The alternative, `Audit`, would only log the violation. We want to be strict.
   {{% /notice %}}

2. **Create a second policy file named `policy-require-non-root.yaml`:**

   ```bash
   # In the k8s directory
   touch policy-require-non-root.yaml
   ```

   Paste this policy. It enforces that containers cannot run as the root user, which drastically reduces the blast radius if a container is compromised. This turns the best practice from our `Dockerfile` into a non-negotiable cluster-wide rule.

   ```yaml
   # k8s/policy-require-non-root.yaml
   apiVersion: kyverno.io/v1
   kind: ClusterPolicy
   metadata:
     name: require-non-root-user
   spec:
     validationFailureAction: Enforce
     background: true
     rules:
       - name: check-for-non-root
         match:
           any:
             - resources:
                 kinds:
                   - Pod
         exclude:
           any:
             # Exclude Falco and Starboard namespace
             - resources:
                 namespaces:
                   - falco
                   - falco-system
                   - starboard
                   - starboard-system
                   - starboard-operator
             # Exclude pods with privileged system labels
             - resources:
                 selector:
                   matchLabels:
                     app.kubernetes.io/name: falco
             # Exclude system namespaces that commonly need root
             - resources:
                 namespaces:
                   - kube-system
                   - istio-system
                   - monitoring
         validate:
           message: "Containers must not run as root. Set spec.securityContext.runAsNonRoot to true at pod or container level."
           anyPattern:
             # Pattern 1: Pod-level security context with runAsNonRoot: true
             - spec:
                 securityContext:
                   runAsNonRoot: true
             # Pattern 2: All containers have runAsNonRoot: true in their security context
             - spec:
                 containers:
                   - securityContext:
                       runAsNonRoot: true
   ```

## Apply and Test the Policies

1. **Apply the policies** to your cluster using `kubectl`:

   ```bash
   kubectl apply -f k8s/policy-disallow-latest-tag.yaml
   kubectl apply -f k8s/policy-require-non-root.yaml
   ```

2. **Test the "disallow-latest-tag" policy.** Now, try to manually create a pod using the `latest` tag. This simulates what a developer might do, bypassing your CI/CD pipeline.

   ```bash
   kubectl run test-pod --image=nginx:latest
   ```

   **The request will be rejected!** You will receive an error message directly from the Kubernetes API server, containing the custom message from your policy:

   ```text
   Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

   resource Pod/default/test-pod was blocked due to the following policies

   disallow-latest-tag:
     require-not-latest-tag: 'validation error: Using the ''latest'' image tag is a security
       risk and is not allowed. Please use a specific image tag. rule require-not-latest-tag
       failed at path /spec/containers/0/image/'
   ```

3. **Test the "require-non-root" policy.** Now try to run a default container, which typically runs as root.

   ```bash
   cat <<EOF | kubectl apply -f -
   apiVersion: v1
   kind: Pod
   metadata:
     name: test-root-pod
     namespace: default
   spec:
     containers:
     - name: nginx
       image: nginx:1.21
       # This pod should be BLOCKED by the policy since it doesn't specify runAsNonRoot
   EOF
   ```

   This will also be **rejected** with a clear message explaining that containers must be configured to run as non-root.

4. **Clean up the failed test pods** (they won't have been created, but `kubectl run` may create a deployment object):

   ```bash
   kubectl delete pod test-root-pod-blocked --ignore-not-found
   ```

5. **Commit your new policy files** to your Git repository.

   ```bash
   git add .
   git commit -m "feat: Implement Kyverno admission control policies"
   git push origin main
   ```
