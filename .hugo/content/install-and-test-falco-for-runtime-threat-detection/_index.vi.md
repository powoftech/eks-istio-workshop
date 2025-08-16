+++
title = 'Cài đặt và Test Falco cho Phát hiện Mối đe dọa Runtime'
weight = 7
pre = "<b>7.</b> "
+++

Chúng ta sẽ tập trung trước tiên vào phần bảo mật runtime. Nhiệm vụ của chúng ta là phát hiện và cảnh báo về hoạt động đáng ngờ trong các container đang chạy theo thời gian thực.

Công cụ của chúng ta cho việc này là **Falco**, tiêu chuẩn open-source CNCF cho phát hiện mối đe dọa runtime cloud-native. Nó hoạt động như một camera bảo mật theo dõi system call và cảnh báo bạn khi container làm điều gì đó không nên làm.

## Cài đặt Falco sử dụng Helm

Giống như với Kyverno, Helm là cách đơn giản nhất để deploy Falco và các thành phần của nó.

1. **Mở terminal** và đảm bảo bạn đã kết nối với EKS cluster.
2. **Thêm Falco Security Helm repository:**

   ```bash
   helm repo add falcosecurity https://falcosecurity.github.io/charts
   ```

3. **Cập nhật Helm repository:**

   ```bash
   helm repo update
   ```

4. **Cài đặt Falco** vào namespace `falco` riêng. Falco hoạt động bằng cách deploy DaemonSet, có nghĩa là nó sẽ chạy một Falco pod trên mỗi worker node để giám sát tất cả hoạt động trên node đó.

   ```bash
   helm install --replace falco --namespace falco --create-namespace --set tty=true falcosecurity/falco
   ```

5. **Xác minh cài đặt.** Có thể mất một hoặc hai phút để pod khởi động.

   ```bash
   kubectl get pods -n falco
   ```

## Quan sát Log của Falco

Hành vi mặc định của Falco là xuất cảnh báo vào log. Hãy xem chúng để thấy hoạt động bình thường trông như thế nào và chuẩn bị để xem cảnh báo.

1. **Tail log từ tất cả Falco pod.** Flag `-f` sẽ "follow" log, streaming chúng đến terminal theo thời gian thực.

```bash
kubectl logs -n falco -l app.kubernetes.io/name=falco -f
```

## Kích hoạt Cảnh báo Bảo mật

Bây giờ chúng ta sẽ mô phỏng pattern tấn công phổ biến: kẻ tấn công có quyền truy cập vào container đang chạy và cố gắng leo thang đặc quyền hoặc cài đặt công cụ độc hại bằng cách spawn shell.

1. **Mở cửa sổ terminal hoặc tab MỚI.** Đừng đóng cái đang tail Falco log.
2. **Tìm một trong những application pod đang chạy:**

   ```bash
   kubectl get pods -l app=workshop-app
   ```

   Copy tên đầy đủ của một pod (ví dụ: `workshop-app-5f4b6c8b9d-abcde`).

3. **"Shell" vào container đang chạy.** Lệnh exec này cung cấp cho bạn interactive shell bên trong container.

   ```bash
   kubectl exec -it <your-app-pod-name> -- /bin/sh
   ```

   Terminal prompt sẽ thay đổi, chỉ ra rằng bạn hiện đang ở bên trong container (ví dụ: `$` hoặc `#`).

## Chứng kiến Phát hiện Thời gian Thực

**Ngay lập tức chuyển lại cửa sổ terminal đầu tiên** (cái có Falco log).

Trong vài giây sau khi thực thi lệnh `exec`, bạn sẽ thấy log entry mới định dạng JSON từ Falco. Nó sẽ trông tương tự như thế này:

```text
08:29:42.827362021: Notice A shell was spawned in a container with an attached terminal | evt_type=execve user=appuser user_uid=1001 user_loginuid=-1 process=sh proc_exepath=/usr/bin/dash parent=containerd-shim command=sh terminal=34816 exe_flags=EXE_LOWER_LAYER container_id=c2d197da82de container_name=workshop-app container_image_repository=593793056386.dkr.ecr.us-east-2.amazonaws.com/workshop-app container_image_tag=9fb43f1fb58cae94f85f5a8ba31c105b43b26068 k8s_pod_name=workshop-app-77d986f5b6-76tvd k8s_ns_name=default
```

{{% notice info %}}
**"Notice"**: Đây là mức độ nghiêm trọng mặc định cho rule này.
{{% /notice %}}

Bây giờ, hãy kích hoạt cảnh báo nghiêm trọng hơn.

1. **Quay lại terminal nơi bạn đang ở bên trong container.**
2. **Thoát container.**

   ```bash
   exit
   ```

3. **Tạm thời xóa Kyverno `require-non-root-user` policy.**

   ```bash
   kubectl delete clusterpolicy require-non-root-user
   ```

4. **Hãy tạo `nginx` deployment:**

   ```bash
   kubectl create deployment nginx --image=nginx
   ```

5. **Thực thi lệnh sẽ kích hoạt rule:**

   ```bash
   kubectl exec -it $(kubectl get pods --selector=app=nginx -o name) -- cat /etc/shadow
   ```

6. **Chuyển lại Falco log. Bạn sẽ thấy cảnh báo khác, nghiêm trọng hơn:**

   Bạn sẽ thấy log cho tất cả Falco pod được deploy trên hệ thống. Falco pod tương ứng với node mà `nginx` deployment đang chạy đã phát hiện sự kiện, và bạn sẽ có thể đọc dòng như:

   ```text
   08:58:14.478370676: Warning Sensitive file opened for reading by non-trusted program | file=/etc/shadow gparent=systemd ggparent=<NA> gggparent=<NA> evt_type=openat user=root user_uid=0 user_loginuid=-1 process=cat proc_exepath=/usr/bin/cat parent=containerd-shim command=cat /etc/shadow terminal=34816 container_id=4c908449279e container_name=nginx container_image_repository=docker.io/library/nginx container_image_tag=latest k8s_pod_name=nginx-5869d7778c-kfdjf k8s_ns_name=default
   ```

7. **Dọn dẹp và roll back:** Bạn có thể dừng tail Falco log bằng cách nhấn `Ctrl+C` trong cửa sổ đó. Bạn cũng nên re-apply Kyverno `require-non-root-user` policy.

   ```bash
   kubectl delete deployment nginx
   kubectl apply -f k8s/policy-require-non-root.yaml
   ```
