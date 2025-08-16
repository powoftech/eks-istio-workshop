+++
title = 'Giới thiệu'
weight = 1
pre = "<b>1.</b> "
+++

Chào mừng bạn đến với workshop AWS toàn diện này, nơi bạn sẽ học cách xây dựng, bảo mật và giám sát các ứng dụng container hóa sử dụng các công nghệ cloud-native hiện đại. Workshop thực hành này sẽ hướng dẫn bạn tạo một pipeline DevSecOps hoàn chỉnh cho các ứng dụng Kubernetes.

## Amazon Elastic Container Registry (ECR)

Amazon Elastic Container Registry (ECR) là một registry Docker container được quản lý hoàn toàn, giúp các nhà phát triển dễ dàng lưu trữ, quản lý và triển khai các Docker container image. ECR được tích hợp với Amazon EKS và Amazon ECS, đơn giản hóa quy trình từ phát triển đến sản xuất.

**Tính năng chính:**

- **Quản lý hoàn toàn**: Không cần quản lý hoặc bảo trì hạ tầng
- **Bảo mật**: Các image được mã hóa khi lưu trữ và truyền tải, với tính năng quét lỗ hổng bảo mật
- **Tính khả dụng cao**: Được xây dựng trên Amazon S3 với độ bền 99.999999999% (11 số 9)
- **Tích hợp**: Hoạt động liền mạch với các dịch vụ AWS và IAM để kiểm soát truy cập chi tiết
- **Hiệu quả chi phí**: Chỉ trả tiền cho dung lượng lưu trữ bạn sử dụng mà không có phí trả trước

Trong workshop này, bạn sẽ sử dụng ECR để lưu trữ các image ứng dụng container hóa và tích hợp với pipeline CI/CD.

## Amazon Elastic Kubernetes Service (EKS)

Amazon Elastic Kubernetes Service (EKS) là một dịch vụ Kubernetes được quản lý hoàn toàn, giúp bạn dễ dàng chạy Kubernetes trên AWS mà không cần cài đặt, vận hành và bảo trì control plane hoặc node Kubernetes của riêng mình.

**Lợi ích chính:**

- **Control Plane được quản lý hoàn toàn**: AWS quản lý control plane Kubernetes, bao gồm tính khả dụng cao và các bản vá bảo mật
- **Bảo mật theo mặc định**: Tích hợp với AWS IAM, VPC và security groups
- **Tính khả dụng cao**: Control plane chạy trên nhiều Availability Zone
- **Tương thích Kubernetes**: Cập nhật thường xuyên để hỗ trợ các phiên bản Kubernetes mới nhất
- **Tích hợp**: Hoạt động với các dịch vụ AWS như ECR, ALB, EBS, EFS và CloudWatch

Trong workshop này, bạn sẽ cung cấp một EKS cluster để triển khai và quản lý các ứng dụng container hóa với khả năng bảo mật và giám sát nâng cao.

## GitHub Actions

GitHub Actions là một nền tảng CI/CD mạnh mẽ cho phép bạn tự động hóa các quy trình phát triển phần mềm trực tiếp từ repository GitHub của mình. Nó cho phép bạn build, test và deploy code ngay từ GitHub.

**Khả năng chính:**

- **Tự động hóa quy trình**: Tự động hóa các quy trình build, test và deployment
- **Điều khiển bằng sự kiện**: Kích hoạt workflow dựa trên các sự kiện GitHub như push, pull request hoặc release
- **Marketplace**: Truy cập hàng nghìn action được xây dựng sẵn từ cộng đồng
- **Matrix Builds**: Test trên nhiều hệ điều hành và phiên bản cùng lúc
- **Quản lý Secrets**: Lưu trữ và sử dụng thông tin nhạy cảm một cách an toàn trong workflow

Trong workshop này, bạn sẽ tạo các GitHub Actions workflow để tự động build, scan và deploy ứng dụng lên EKS.

## Kyverno Policy Engine

Kyverno là một policy engine được thiết kế cho Kubernetes, cho phép bạn quản lý các cluster policy dưới dạng code. Nó cung cấp cách tiếp cận declarative để quản lý policy mà không cần học ngôn ngữ mới.

**Tính năng chính:**

- **Policy dựa trên YAML**: Viết policy sử dụng cú pháp YAML quen thuộc của Kubernetes
- **Validation**: Thực thi các quy tắc cho cấu hình resource
- **Mutation**: Tự động sửa đổi resource để tuân thủ các tiêu chuẩn
- **Generation**: Tạo thêm resource dựa trên các quy tắc policy
- **Reporting**: Tạo báo cáo vi phạm policy

Trong workshop này, bạn sẽ sử dụng Kyverno như một cluster gatekeeper để thực thi các policy bảo mật và quy tắc quản trị.

## Falco Runtime Security

Falco là một công cụ bảo mật runtime mã nguồn mở phát hiện hành vi ứng dụng bất thường và cảnh báo về các mối đe dọa trong thời gian thực. Nó hoạt động như một camera an ninh cho các Kubernetes cluster của bạn.

**Khả năng bảo mật:**

- **Phát hiện mối đe dọa Runtime**: Giám sát các kernel call và phát hiện hoạt động đáng ngờ
- **Hiểu biết về Kubernetes**: Hiểu được context và resource của Kubernetes
- **Quy tắc linh hoạt**: Định nghĩa quy tắc tùy chỉnh cho yêu cầu bảo mật cụ thể
- **Đầu ra đa dạng**: Gửi cảnh báo đến nhiều đích khác nhau (Slack, PagerDuty, v.v.)
- **Cloud-Native**: Được thiết kế đặc biệt cho môi trường container hóa

Trong workshop này, bạn sẽ triển khai Falco để giám sát ứng dụng và phát hiện các mối đe dọa bảo mật tiềm ẩn trong thời gian thực.
