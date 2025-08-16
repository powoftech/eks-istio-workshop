+++
title = 'Dọn dẹp tài nguyên'
weight = 8
pre = "<b>8.</b> "
+++

## Tổng quan

Sau khi hoàn thành workshop, hoặc nếu bạn gặp bất kỳ lỗi deployment nào, bạn nên dọn dẹp tài nguyên AWS để tránh phí không cần thiết. Hướng dẫn này cung cấp hướng dẫn từng bước để xóa đúng cách tất cả tài nguyên đã deploy.

## Quy trình Dọn dẹp

Thực hiện các bước này theo thứ tự được chỉ định để đảm bảo tất cả tài nguyên được xóa đúng cách:

### Bước 1: Xóa EKS Cluster

Trong thư mục dự án `secure-container-pipeline`, chạy lệnh `eksctl` sau:

```bash
eksctl delete cluster -f k8s/cluster.yaml --wait --disable-nodegroup-eviction --force --parallel 4
```

### Bước 2: Xóa ECR Repository

Chạy lệnh AWS CLI trong terminal:

```bash
aws ecr delete-repository \
--repository-name workshop-app \
--region us-east-2 # Sử dụng cùng region với cluster của bạn
```

### Bước 3: Xóa IAM _Role_ và _Identity provider_

- **Trong AWS Console, đi đến IAM <kbd>&rarr;</kbd> Roles.**
  - Chọn role `WorkshopGitHubActionsRole`.
  - Click **Delete**.
  - Nhập tên role để xác nhận xóa.
  - Click **Delete**.
- **Đi đến IAM <kbd>&rarr;</kbd> Roles**
  - Chọn provider `token.actions.githubusercontent.com`.
  - Click **Delete**.
  - Gõ `confirm` để xác nhận xóa.
  - Click **Delete**.
