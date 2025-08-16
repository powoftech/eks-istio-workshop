+++
title = 'Yêu cầu tiên quyết'
weight = 2
pre = "<b>2.</b> "
+++

Trước khi bắt đầu workshop này, bạn cần cài đặt và cấu hình một số công cụ thiết yếu giúp bạn tương tác với các dịch vụ AWS và các cluster Kubernetes. Những công cụ này tạo nền tảng để làm việc với container và tài nguyên AWS, đặc biệt là Amazon EKS.

## AWS CLI

AWS Command Line Interface (CLI) là một công cụ thống nhất cho phép bạn quản lý các dịch vụ AWS từ terminal. Bạn sẽ sử dụng nó để cấu hình thông tin xác thực AWS, tạo và quản lý tài nguyên AWS, và tương tác với các dịch vụ AWS khác nhau trong suốt workshop này.

**Cài đặt:** Tải xuống và cài đặt AWS CLI từ [tài liệu chính thức của AWS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

**Cấu hình:** Sau khi cài đặt, chạy `aws configure` để thiết lập access key, region mặc định và định dạng đầu ra.

## kubectl

kubectl là công cụ dòng lệnh của Kubernetes cho phép bạn chạy các lệnh với cluster Kubernetes. Bạn sẽ sử dụng nó để triển khai ứng dụng, kiểm tra và quản lý tài nguyên cluster, và xem log trong cluster EKS của mình.

**Cài đặt:** Làm theo [tài liệu Kubernetes](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) để cài đặt kubectl cho hệ điều hành của bạn.

**Xác minh:** Chạy `kubectl version --client` để xác minh việc cài đặt.

## eksctl

eksctl là một công cụ dòng lệnh để tạo và quản lý cluster Kubernetes trên Amazon EKS. Nó đơn giản hóa quá trình tạo cluster EKS và worker node, tự động xử lý phần lớn việc thiết lập hạ tầng AWS bên dưới.

**Cài đặt:** Tải xuống eksctl từ [GitHub releases chính thức](https://github.com/eksctl-io/eksctl/releases) hoặc sử dụng trình quản lý gói của bạn.

**Xác minh:** Chạy `eksctl version` để xác nhận việc cài đặt.

## Helm

Helm là trình quản lý gói cho Kubernetes giúp bạn quản lý các ứng dụng Kubernetes. Bạn sẽ sử dụng Helm để cài đặt và cấu hình Kyverno, Falco và các ứng dụng khác trên cluster EKS của mình bằng cách sử dụng các chart đã được cấu hình sẵn.

**Cài đặt:** Cài đặt Helm theo [tài liệu Helm chính thức](https://helm.sh/docs/intro/install/).

**Xác minh:** Chạy `helm version` để xác minh việc cài đặt.

## Docker

Docker là một nền tảng container hóa cho phép bạn xây dựng, đóng gói và chạy ứng dụng trong container. Bạn sẽ sử dụng Docker để xây dựng container image cho ứng dụng của mình và hiểu cách các workload được container hóa hoạt động trong môi trường Kubernetes.

**Cài đặt:** Tải xuống và cài đặt Docker Desktop từ [trang web Docker chính thức](https://docs.docker.com/get-docker/) hoặc sử dụng trình quản lý gói của hệ thống cho Docker Engine.

**Xác minh:** Chạy `docker --version` để xác nhận việc cài đặt và `docker run hello-world` để kiểm tra rằng Docker có thể pull và chạy container.

---

**Lưu ý:** Đảm bảo tất cả các công cụ đã được thêm vào PATH của hệ thống và có thể truy cập từ terminal trước khi tiếp tục.
