+++
title = 'Cung cấp EKS Cluster và Tự động hóa Deployment'
weight = 5
pre = "<b>5.</b> "
+++

## Tạo Cấu hình EKS Cluster

Chúng ta sẽ sử dụng `eksctl` để build cluster. Thực tiễn tốt nhất là định nghĩa cluster trong một file cấu hình, sau đó bạn có thể commit vào Git repository để kiểm soát phiên bản và tái tạo.

1. **Trong root directory của dự án, tạo thư mục mới có tên `k8s`.**

   ```bash
   mkdir k8s
   cd k8s
   ```

2. **Tạo file mới có tên `cluster.yaml`**

3. **Dán nội dung sau vào `cluster.yaml`.** Đọc các comment để hiểu từng dòng làm gì

   ```yaml
   # k8s/cluster.yaml
   apiVersion: eksctl.io/v1alpha5
   kind: ClusterConfig

   metadata:
     # Tên cluster của bạn
     name: workshop-cluster
     # AWS region nơi cluster sẽ được tạo
     region: us-east-2
     # Phiên bản Kubernetes của cluster
     version: "1.33"

   # Section này định nghĩa các Kubernetes worker node
   nodeGroups:
     - name: ng-1-workers # Tên cho node group
       instanceType: t3.medium # Instance type general-purpose mặc định.
       desiredCapacity: 2 # Bắt đầu với 2 node cho high availability
       minSize: 1 # Để tiết kiệm chi phí, bạn có thể scale down xuống 1 node khi không test tích cực
       maxSize: 3 # Giới hạn max size để ngăn chi phí vượt quá do tai nạn
       # Khuyến nghị: Sử dụng AWS Bottlerocket OS để bảo mật tốt hơn và footprint nhỏ hơn
       amiFamily: Bottlerocket
       # Khuyến nghị: Launch nodegroup trong private subnet
       privateNetworking: true

   accessConfig:
     authenticationMode: API_AND_CONFIG_MAP
     # Tạo EKS access entry để giúp GitHub Actions workflow có thể deploy vào cluster
     accessEntries:
       # QUAN TRỌNG: Thay thế <<AWS Account ID>> bằng AWS Account ID của bạn
       - principalARN: arn:aws:iam::<<AWS Account ID>>:role/WorkshopGitHubActionsRole
         accessPolicies:
           - policyARN: arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy
             accessScope:
               type: cluster
   ```

## Khởi chạy EKS Cluster

Bây giờ, thực thi lệnh để build cluster.

1. **Mở terminal** trong thư mục `secure-container-pipeline`.

2. **Chạy lệnh tạo:**

   ```bash
   eksctl create cluster -f k8s/cluster.yaml
   ```

3. **Hãy kiên nhẫn.** Quá trình này sẽ mất 15-20 phút. `eksctl` sẽ in ra rất nhiều thông tin khi nó cung cấp các tài nguyên trong AWS CloudFormation. Hãy đi uống cà phê.

4. **Xác nhận:** Khi hoàn tất, `eksctl` sẽ tự động cập nhật file `kubeconfig` local của bạn (`~/.kube/config`). Điều này có nghĩa `kubectl` bây giờ sẽ trỏ đến EKS cluster mới của bạn.

## Xác minh Quyền truy cập Cluster

Hãy đảm bảo bạn có thể giao tiếp với cluster mới.

1. **Chạy lệnh `kubectl` này:**

   ```bash
   kubectl get nodes
   ```

2. Bạn sẽ thấy output liệt kê hai worker node, tương tự như thế này:

   ```text
   NAME                                            STATUS   ROLES    AGE     VERSION
   ip-192-168-158-45.us-east-2.compute.internal    Ready    <none>   6m16s   v1.33.1-eks-b9364f6
   ip-192-168-173-179.us-east-2.compute.internal   Ready    <none>   6m21s   v1.33.1-eks-b9364f6
   ```

## Tạo Kubernetes Deployment Manifest

Chúng ta cần nói với Kubernetes cách chạy ứng dụng của chúng ta. Chúng ta sẽ làm điều này với hai file tài nguyên Kubernetes tiêu chuẩn: một Deployment (để quản lý các Pod ứng dụng) và một Service (để expose ứng dụng ra traffic).

1. **Trong root directory của dự án, tạo thư mục mới có tên `k8s`.**

   ```bash
   mkdir k8s
   cd k8s
   ```

2. **Tạo file `deployment.yaml`:**

   ```bash
   # Trong thư mục 'k8s'
   touch deployment.yaml
   ```

   Dán nội dung này vào k8s/deployment.yaml. Chú ý đặc biệt đến dòng ##IMAGE_TAG_PLACEHOLDER##; chúng ta sẽ thay thế điều này một cách động trong pipeline của chúng ta.

   ```yaml
   # k8s/deployment.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: workshop-app
     labels:
       app: workshop-app
   spec:
     replicas: 2 # Chạy hai instance cho availability
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
             # QUAN TRỌNG: Đây là placeholder. Pipeline của chúng ta sẽ thay thế nó.
             image: "IMAGE_PLACEHOLDER"
             ports:
               - containerPort: 8080
             # --- Security Context ---
             # Điều này thực thi các thực tiễn bảo mật tốt nhất ở cấp độ container.
             securityContext:
               # Ngăn container có được nhiều quyền hơn parent process.
               allowPrivilegeEscalation: false
               # Chạy container với read-only root filesystem.
               readOnlyRootFilesystem: true
               # Củng cố non-root user của Dockerfile.
               runAsNonRoot: true
               # Chỉ định user và group ID để chạy, khớp với Dockerfile.
               runAsUser: 1001
               runAsGroup: 1001
               # Drop tất cả Linux capability và chỉ thêm lại những gì cần thiết (không có trong trường hợp này).
               capabilities:
                 drop:
                   - "ALL"
         # Vị trí cho file tạm thời, vì root filesystem là read-only.
         volumes:
           - name: tmp
             emptyDir: {}
   ```

3. **Tạo file `service.yaml`:**

   ```bash
   # Trong thư mục 'k8s'
   touch service.yaml
   ```

   Dán nội dung này vào `k8s/service.yaml`. Điều này sẽ tạo một service `LoadBalancer`, tự động cung cấp AWS Network Load Balancer để expose ứng dụng của bạn ra internet.

   ```yaml
   # k8s/service.yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: workshop-app-service
   spec:
     selector:
       app: workshop-app
     # Type này tạo external AWS Load Balancer
     type: LoadBalancer
     ports:
       - protocol: TCP
         port: 80 # Port mà load balancer lắng nghe
         targetPort: 8080 # Port mà container lắng nghe
   ```

4. **Quay lại root directory của dự án:**

   ```bash
   cd ..
   ```

## Cập nhật IAM Role cho Quyền Deployment

`WorkshopGitHubActionsRole` của chúng ta có thể push vào ECR, nhưng nó chưa thể giao tiếp với EKS cluster. Chúng ta cần cấp quyền cho nó.

1. **Trong AWS Console, đi đến IAM <kbd>&rarr;</kbd> Roles <kbd>&rarr;</kbd>.**

   - Chọn role `WorkshopGitHubActionsRole`.
   - Trong tab **Permissions**, section **Permissions policies**, chọn **Add permissions <kbd>&rarr;</kbd> Create inline policy**.
   - Với **Policy editor**, chọn **JSON**, dán policy sau và thay thế AWS account ID:

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
   - Đặt tên cho policy, như `DescribeWorkshopEKSCluster`.
   - Tạo policy.

## Cập nhật GitHub Actions Workflow để Deploy

Bây giờ, chúng ta sẽ thêm job `deploy` mới vào file `ci.yml`.

1. **Mở `.github/workflows/ci.yml`.**
2. **Thêm job `deploy` mới** vào cuối file. File hoàn chỉnh, cập nhật sẽ giống như thế này:

    ```yaml
    # .github/workflows/ci.yml

    # ... (các tham số khác được bỏ qua) ...

    jobs:
      build-scan-push:
        # ... (job build-scan-push vẫn giữ nguyên như trước) ...

      # ---- JOB DEPLOY MỚI ----
      deploy:
        # Job này chỉ chạy nếu job 'build-scan-push' thành công
        name: Deploy to EKS
        needs: build-scan-push
        runs-on: ubuntu-latest
        permissions:
          # Bắt buộc cho kết nối OIDC đến AWS
          id-token: write
          contents: read

        steps:
          - name: Checkout repository
            uses: actions/checkout@v5

          - name: Configure AWS credentials
            uses: aws-actions/configure-aws-credentials@v4
            with:
              role-to-assume: arn:aws:iam::<<AWS Account ID>>:role/WorkshopGitHubActionsRole # <-- DÁN ROLE ARN CỦA BẠN VÀO ĐÂY
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

    **Thay đổi Chính:**

    - Job `deploy` mới được thêm vào.
    - `needs: build-scan-push` đảm bảo deployment chỉ xảy ra sau khi build và scan thành công.
    - Lệnh `sed` là bước quan trọng tìm `IMAGE_PLACEHOLDER` và thay thế nó bằng image URI thực tế, unique từ bước build.
    - `kubectl apply` gửi cấu hình của chúng ta đến EKS cluster.

3. **Commit, push và xác minh deployment:**

   - **Commit thay đổi của bạn:**

      ```bash
      git add .
      git commit -m "feat: Add k8s manifests and deploy job to CI workflow"
      git push origin main
      ```

   - **Theo dõi pipeline:** Đi đến tab **Actions** trong GitHub. Bạn sẽ thấy pipeline đầy đủ chạy. Lần này, sau khi "Build, Scan & Push" hoàn tất, job "Deploy to EKS" sẽ bắt đầu.
   - **Xác minh trong terminal:** Khi pipeline thành công, kiểm tra trạng thái deployment của bạn.
      - Kiểm tra pod:

         ```bash
         kubectl get pods -l app=workshop-app
         ```

         Bạn sẽ thấy hai pod với trạng thái `Running`.
      - Kiểm tra service và lấy Load Balancer URL:

         ```bash
         kubectl get service workshop-app-service
         ```

         Sẽ mất một hoặc hai phút để AWS cung cấp load balancer. `EXTERNAL-IP` sẽ thay đổi từ `<pending>` thành một DNS name dài.
   - **Test ứng dụng!** Copy DNS name `EXTERNAL-IP` và dán vào trình duyệt web. Bạn sẽ thấy thông báo: `Hello, FCJ-ers!`
