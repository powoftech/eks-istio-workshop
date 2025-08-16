+++
title = "Bảo mật Container Registry với Quét Lỗ hổng và Thực thi Chính sách"
weight = 1
chapter = true
+++

## Mô tả workshop

Workshop AWS toàn diện này sẽ dạy bạn cách xây dựng, bảo mật và giám sát các ứng dụng container hóa bằng các công nghệ cloud-native hiện đại và thực tiễn DevSecOps. Bạn sẽ tạo ra một pipeline container bảo mật hoàn chỉnh từ đầu đến cuối bao gồm quét lỗ hổng, thực thi chính sách và phát hiện mối đe dọa runtime.

Trong suốt workshop thực hành này, bạn sẽ:

- **Xây dựng pipeline CI/CD bảo mật** sử dụng GitHub Actions để tự động build, quét và triển khai các ứng dụng container hóa
- **Triển khai quét lỗ hổng container** với các tính năng bảo mật tích hợp của Amazon ECR
- **Triển khai thực thi chính sách** sử dụng Kyverno như một admission controller của Kubernetes để ngăn chặn các workload không an toàn
- **Thiết lập phát hiện mối đe dọa runtime** với Falco để giám sát và cảnh báo về hành vi đáng ngờ của container
- **Cung cấp và quản lý** các cluster Amazon EKS với các thực tiễn bảo mật tốt nhất
- **Áp dụng các nguyên tắc DevSecOps** bằng cách tích hợp bảo mật vào mọi giai đoạn của vòng đời phát triển

Khi kết thúc workshop này, bạn sẽ có một pipeline triển khai container sẵn sàng cho production, ưu tiên bảo mật, tự động ngăn chặn các image có lỗ hổng đến production và phát hiện mối đe dọa trong thời gian thực.

## Đối tượng mục tiêu

Workshop này được thiết kế cho:

- **Kỹ sư DevOps** muốn triển khai các kiểm soát bảo mật trong pipeline container của họ
- **Kỹ sư Bảo mật** muốn học các công cụ và thực tiễn bảo mật cloud-native
- **Kỹ sư Platform** xây dựng các nền tảng Kubernetes bảo mật cho các nhóm phát triển
- **Nhà phát triển Phần mềm** quan tâm đến việc hiểu bảo mật container và thực tiễn triển khai bảo mật
- **Kiến trúc sư Cloud** thiết kế các giải pháp container hóa bảo mật trên AWS
- **Kỹ sư Độ tin cậy Site (SRE)** triển khai giám sát bảo mật và thực thi chính sách

## Kiến thức giả định

Người tham gia nên có:

- **Kinh nghiệm container hóa cơ bản** với Docker (build image, chạy container)
- **Kiến thức Kubernetes cơ bản** (pod, deployment, service, namespace)
- **Hiểu biết cơ bản về AWS** (quen thuộc cơ bản với các dịch vụ và khái niệm AWS)
- **Thành thạo dòng lệnh** trong môi trường Linux/Unix
- **Kinh nghiệm Git và GitHub** cho version control và khái niệm CI/CD cơ bản
- **Quen thuộc với cú pháp YAML** cho Kubernetes manifest và file cấu hình

Kinh nghiệm trước đây với EKS, công cụ bảo mật hoặc policy engine sẽ hữu ích nhưng không bắt buộc vì workshop cung cấp hướng dẫn từng bước.

## Thời gian hoàn thành workshop

**Tổng thời gian:** 3-4 giờ

**Phân chia module:**

- Thiết lập và Điều kiện tiên quyết: 30 phút
- Tạo Repository Dự án: 20 phút
- Ứng dụng và CI Workflow: 45 phút
- Cung cấp EKS Cluster: 30 phút
- Thiết lập Kyverno Policy Engine: 45 phút
- Bảo mật Runtime Falco: 30 phút
- Kiểm tra và Xác thực: 30 phút
- Dọn dẹp: 15 phút

Workshop được thiết kế để hoàn thành trong một phiên làm việc, với các điểm nghỉ tự nhiên sau mỗi module chính. Tất cả việc cung cấp cơ sở hạ tầng và triển khai đều được bao gồm trong ước tính thời gian.
