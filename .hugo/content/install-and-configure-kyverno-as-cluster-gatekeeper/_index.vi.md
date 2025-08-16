+++
title = 'Cài đặt và Cấu hình Kyverno như Cluster Gatekeeper'
weight = 6
pre = "<b>6.</b> "
+++

Mục tiêu của chúng ta ở đây là làm cho cluster tự bảo vệ. Pipeline mà chúng ta đã xây dựng rất tốt, nhưng nó không ngăn chặn ai đó có quyền truy cập kubectl deploy thủ công một container không an toàn. Bây giờ chúng ta sẽ cài đặt một gatekeeper--một admission controller--để thực thi các quy tắc của chúng ta trên mọi workload cố gắng chạy trên cluster.

Công cụ của chúng ta cho việc này là **Kyverno**. Nó mạnh mẽ, native với Kubernetes, và các policy chỉ là YAML đơn giản, làm cho nó hoàn hảo cho dự án của chúng ta.

## Cài đặt Kyverno sử dụng Helm

Helm là cách tốt nhất để cài đặt và quản lý các ứng dụng phức tạp như Kyverno trên Kubernetes.

1. **Mở terminal**, đảm bảo context `kubectl` của bạn đang trỏ đến `workshop-cluster`.
2. **Thêm Kyverno Helm repository:**

   ```bash
   helm repo add kyverno https://kyverno.github.io/kyverno/
   ```

3. **Cập nhật Helm repository** để lấy thông tin chart mới:

   ```bash
   helm repo update
   ```

4. **Cài đặt Kyverno** vào namespace chuyên dụng riêng. Đây là thực tiễn tốt nhất cho các công cụ cluster-wide.

   ```bash
   helm install kyverno kyverno/kyverno -n kyverno --create-namespace
   ```

5. **Xác minh cài đặt.** Có thể mất một phút để tất cả pod Kyverno sẵn sàng.

   ```bash
   kubectl get pods -n kyverno
   ```

   Bạn sẽ thấy một số pod, bao gồm admission controller, background controller và cleanup controller, tất cả ở trạng thái Running.

## Tạo Policy Bảo mật Đầu tiên

Bây giờ đến phần mạnh mẽ. Chúng ta sẽ định nghĩa các quy tắc bảo mật như tài nguyên `ClusterPolicy`. Đây là các quy tắc cluster-wide.

1. **Trong thư mục k8s của dự án, tạo file mới có tên `policy-disallow-latest-tag.yaml`:**

   ```bash
   # Trong thư mục k8s
   touch policy-disallow-latest-tag.yaml
   ```

   Dán policy sau. Đây là thực tiễn tốt nhất cơ bản: nó ngăn chặn deployment mơ hồ và buộc sử dụng tag cụ thể, không thể thay đổi (như Git SHA chúng ta sử dụng trong pipeline).

   ```yaml
   # k8s/policy-disallow-latest-tag.yaml
   apiVersion: kyverno.io/v1
   kind: ClusterPolicy
   metadata:
     name: disallow-latest-tag
   spec:
     # Rule này áp dụng cho tất cả Pod, Deployment, StatefulSet, v.v.
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
           message: "Sử dụng image tag 'latest' là rủi ro bảo mật và không được phép. Vui lòng sử dụng image tag cụ thể."
           pattern:
             spec:
               containers:
                 # Pattern này nói "trường image của BẤT KỲ container nào KHÔNG ĐƯỢC kết thúc bằng :latest"
                 - image: "!*:latest"
   ```

   {{% notice info %}}
   `validationFailureAction: Enforce` là chìa khóa. Nó nói với Kyverno **chặn** bất kỳ API request nào vi phạm quy tắc này. Thay thế, `Audit`, sẽ chỉ log vi phạm. Chúng ta muốn nghiêm ngặt.
   {{% /notice %}}

2. **Tạo file policy thứ hai có tên `policy-require-non-root.yaml`:**

   ```bash
   # Trong thư mục k8s
   touch policy-require-non-root.yaml
   ```

   Dán policy này. Nó thực thi rằng container không thể chạy như root user, điều này giảm đáng kể bán kính nổ nếu container bị tấn công. Điều này biến thực tiễn tốt nhất từ `Dockerfile` của chúng ta thành quy tắc cluster-wide không thể thương lượng.

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
             # Loại trừ Falco và Starboard namespace
             - resources:
                 namespaces:
                   - falco
                   - falco-system
                   - starboard
                   - starboard-system
                   - starboard-operator
             # Loại trừ pod với privileged system label
             - resources:
                 selector:
                   matchLabels:
                     app.kubernetes.io/name: falco
             # Loại trừ system namespace thường cần root
             - resources:
                 namespaces:
                   - kube-system
                   - istio-system
                   - monitoring
         validate:
           message: "Container không được chạy với quyền root. Đặt spec.securityContext.runAsNonRoot thành true ở cấp độ pod hoặc container."
           anyPattern:
             # Pattern 1: Security context cấp độ Pod với runAsNonRoot: true
             - spec:
                 securityContext:
                   runAsNonRoot: true
             # Pattern 2: Tất cả container có runAsNonRoot: true trong security context
             - spec:
                 containers:
                   - securityContext:
                       runAsNonRoot: true
   ```

## Apply và Test Policy

1. **Apply policy** vào cluster sử dụng `kubectl`:

   ```bash
   kubectl apply -f k8s/policy-disallow-latest-tag.yaml
   kubectl apply -f k8s/policy-require-non-root.yaml
   ```

2. **Test policy "disallow-latest-tag".** Bây giờ, thử tạo pod thủ công sử dụng tag `latest`. Điều này mô phỏng những gì developer có thể làm, bỏ qua CI/CD pipeline của bạn.

   ```bash
   kubectl run test-pod --image=nginx:latest
   ```

   **Request sẽ bị từ chối!** Bạn sẽ nhận được thông báo lỗi trực tiếp từ Kubernetes API server, chứa custom message từ policy của bạn:

   ```text
   Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

   resource Pod/default/test-pod was blocked due to the following policies

   disallow-latest-tag:
     require-not-latest-tag: 'validation error: Sử dụng image tag ''latest'' là rủi ro bảo mật và không được phép. Vui lòng sử dụng image tag cụ thể. rule require-not-latest-tag
       failed at path /spec/containers/0/image/'
   ```

3. **Test policy "require-non-root".** Bây giờ thử chạy container mặc định, thường chạy với quyền root.

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
       # Pod này sẽ bị CHẶN bởi policy vì nó không chỉ định runAsNonRoot
   EOF
   ```

   Điều này cũng sẽ bị **từ chối** với thông báo rõ ràng giải thích rằng container phải được cấu hình để chạy như non-root.

4. **Dọn dẹp test pod thất bại** (chúng sẽ không được tạo, nhưng `kubectl run` có thể tạo deployment object):

   ```bash
   kubectl delete pod test-root-pod-blocked --ignore-not-found
   ```

5. **Commit file policy mới** vào Git repository của bạn.

   ```bash
   git add .
   git commit -m "feat: Implement Kyverno admission control policies"
   git push origin main
   ```
