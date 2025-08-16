+++
title = 'Install and Test Falco for Runtime Threat Detection'
weight = 7
pre = "<b>7.</b> "
+++

We will focus first on the runtime security piece. Our mission is to detect and alert on suspicious activity within our running containers in real-time.

Our tool for this is **Falco**, the CNCF open-source standard for cloud-native runtime threat detection. It acts like a security camera that watches system calls and alerts you when a container does something it shouldn't.

## Install Falco using Helm

Just like with Kyverno, Helm is the most straightforward way to deploy Falco and its components.

1. **Open your terminal** and ensure you're connected to your EKS cluster.
2. **Add the Falco Security Helm repository:**

   ```bash
   helm repo add falcosecurity https://falcosecurity.github.io/charts
   ```

3. **Update your Helm repositories:**

   ```bash
   helm repo update
   ```

4. **Install Falco** into its own `falco` namespace. Falco works by deploying a DaemonSet, which means it will run one Falco pod on each of your worker nodes to monitor all activity on that node.

   ```bash
   helm install --replace falco --namespace falco --create-namespace --set tty=true falcosecurity/falco
   ```

5. **Verify the installation.** It may take a minute or two for the pods to start.

   ```bash
   kubectl get pods -n falco
   ```

## Observe Falco's Logs

Falco's default behavior is to output its alerts to its logs. Let's watch them to see what normal activity looks like and to prepare to see an alert.

1. **Tail the logs from all Falco pods.** The `-f` flag will "follow" the logs, streaming them to your terminal in real-time.

```bash
kubectl logs -n falco -l app.kubernetes.io/name=falco -f
```

## Trigger a Security Alert

We will now simulate a common attack pattern: an attacker gains access to a running container and tries to escalate privileges or install malicious tools by spawning a shell.

1. **Open a NEW terminal window or tab.** Don't close the one tailing the Falco logs.
2. **Find one of your running application pods:**

   ```bash
   kubectl get pods -l app=workshop-app
   ```

   Copy the full name of one of the pods (e.g., `workshop-app-5f4b6c8b9d-abcde`).

3. **"Shell" into the running container.** This exec command gives you an interactive shell inside the container.

   ```bash
   kubectl exec -it <your-app-pod-name> -- /bin/sh
   ```

   Your terminal prompt will change, indicating you are now inside the container (e.g., `$` or `#`).

## Witness the Real-Time Detection

**Immediately switch back to your first terminal window** (the one with the Falco logs).

Within seconds of executing the `exec` command, you will see a new JSON-formatted log entry from Falco. It will look similar to this:

```text
08:29:42.827362021: Notice A shell was spawned in a container with an attached terminal | evt_type=execve user=appuser user_uid=1001 user_loginuid=-1 process=sh proc_exepath=/usr/bin/dash parent=containerd-shim command=sh terminal=34816 exe_flags=EXE_LOWER_LAYER container_id=c2d197da82de container_name=workshop-app container_image_repository=593793056386.dkr.ecr.us-east-2.amazonaws.com/workshop-app container_image_tag=9fb43f1fb58cae94f85f5a8ba31c105b43b26068 k8s_pod_name=workshop-app-77d986f5b6-76tvd k8s_ns_name=default
```

{{% notice info %}}
**"Notice"**: This is the default severity level for this rule.
{{% /notice %}}

Now, let's trigger a higher-severity alert.

1. **Go back to the terminal where you are inside the container.**
2. **Exit the container.**

   ```bash
   exit
   ```

3. **Temporarily delete Kyverno `require-non-root-user` policy.**

   ```bash
   kubectl delete clusterpolicy require-non-root-user
   ```

4. **Let's create a `nginx` deployment:**

   ```bash
   kubectl create deployment nginx --image=nginx
   ```

5. **Execute a command that would trigger a rule:**

   ```bash
   kubectl exec -it $(kubectl get pods --selector=app=nginx -o name) -- cat /etc/shadow
   ```

6. **Switch back to the Falco logs. You will see another, more severe alert:**

   You will see logs for all the Falco pods deployed on the system. The Falco pod corresponding to the node in which our `nginx` deployment is running has detected the event, and you'll be able to read a line like:

   ```text
   08:58:14.478370676: Warning Sensitive file opened for reading by non-trusted program | file=/etc/shadow gparent=systemd ggparent=<NA> gggparent=<NA> evt_type=openat user=root user_uid=0 user_loginuid=-1 process=cat proc_exepath=/usr/bin/cat parent=containerd-shim command=cat /etc/shadow terminal=34816 container_id=4c908449279e container_name=nginx container_image_repository=docker.io/library/nginx container_image_tag=latest k8s_pod_name=nginx-5869d7778c-kfdjf k8s_ns_name=default
   ```

7. **Clean up and roll back:** You can stop tailing the Falco logs by pressing `Ctrl+C` in that window. You should also re-apply Kyverno `require-non-root-user` policy.

   ```bash
   kubectl delete deployment nginx
   kubectl apply -f k8s/policy-require-non-root.yaml
   ```
