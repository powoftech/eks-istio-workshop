+++
title = 'Tạo Ứng dụng Có thể Build Bảo mật và CI Workflow'
weight = 4
pre = "<b>4.</b> "
+++

## Tạo Ứng dụng Mẫu và Dockerfile

Trước tiên, chúng ta cần một thứ gì đó để build. Chúng ta sẽ tạo một ứng dụng Node.js "Hello World" rất đơn giản và một Dockerfile có ý thức bảo mật.

1. **Trong thư mục dự án `secure-container-pipeline` của bạn, tạo một thư mục mới có tên `app`.**

   ```bash
   mkdir app
   cd app
   ```

2. **Tạo file ứng dụng Node.js `app.js`:**

   ```bash
   # Trong thư mục 'app'
   touch app.js
   ```

   Dán đoạn code server đơn giản này vào `app/app.js`:

   ```javascript
   // app/app.js
   const http = require("http");
   const port = 8080;

   const server = http.createServer((req, res) => {
     res.statusCode = 200;
     res.setHeader("Content-Type", "text/plain");
     res.end("Hello, FCJ-ers!\n");
   });

   server.listen(port, () => {
     console.log(`Server running on port ${port}`);
   });
   ```

3. **Tạo `Dockerfile`:**

   ```Dockerfile
   # app/Dockerfile
   # Stage 1: Sử dụng base image cụ thể, slim để giảm bề mặt tấn công.
   FROM node:22-slim AS base

   # Tạo một user và group chuyên dụng, không phải root cho ứng dụng.
   # Đây là một biện pháp bảo mật quan trọng.
   RUN addgroup --system --gid 1001 nodejs
   RUN adduser --system --uid 1001 appuser

   WORKDIR /home/appuser/app

   # Chỉ copy file cần thiết và đặt quyền chính xác.
   COPY --chown=appuser:nodejs app.js .

   # Chuyển sang user không phải root. Mọi lệnh tiếp theo chạy với user này.
   USER appuser

   # Expose port mà app chạy.
   EXPOSE 8080

   # Lệnh để chạy ứng dụng.
   CMD [ "node", "app.js" ]
   ```

4. **Quay lại root directory của dự án:**

   ```bash
   cd ..
   ```

## Tạo ECR Repository

Hãy tạo container registry bảo mật nơi chúng ta sẽ lưu trữ các Docker image.

1. **Chạy lệnh AWS CLI này** trong terminal của bạn:

   ```bash
   aws ecr create-repository \
   --repository-name workshop-app \
   --image-scanning-configuration scanOnPush=true \
   --region us-east-2 # Sử dụng cùng region với cluster của bạn
   ```

   {{% notice info %}}
   Flag `--image-scanning-configuration scanOnPush=true` là kiểm soát bảo mật có chủ ý đầu tiên của chúng ta. Chúng ta đã hướng dẫn AWS tự động quét mọi image mới mà chúng ta push vào repository này để tìm các lỗ hổng đã biết (CVE). Đây là một phần nền tảng của pipeline bảo mật của chúng ta.
   {{% /notice %}}

## Thiết lập Quyền truy cập Bảo mật từ GitHub Actions đến AWS (OIDC)

Chúng ta cần cấp quyền cho GitHub để push image vào ECR repository của chúng ta. Chúng ta sẽ sử dụng phương pháp hiện đại, bảo mật, không cần mật khẩu: OIDC (OpenID Connect).

1. **Trong AWS Console, đi đến IAM <kbd>&rarr;</kbd> Identity providers.**
   - Click **Add provider**.
   - Chọn **OpenID Connect**.
   - Với **Provider URL**, nhập `https://token.actions.githubusercontent.com`.
   - Với **Audience**, nhập `sts.amazonaws.com`.
   - Click **Add provider**.
2. **Tạo IAM Role cho GitHub Actions**.
   - Đi đến **IAM <kbd>&rarr;</kbd> Roles <kbd>&rarr;</kbd> Create role**.
   - Với **Trusted entity type**, chọn **Web identity**.
   - Từ dropdown **Identity provider**, chọn provider `token.actions.githubusercontent.com` mà bạn vừa tạo.
   - Với **Audience**, chọn `sts.amazonaws.com`.
   - Với **GitHub organization/repository**, nhập thông tin chi tiết của bạn. Với dự án cá nhân, bạn có thể cụ thể:
     - Organization: `your-github-username`
     - Repository: `secure-container-pipeline`
     - (Tùy chọn nhưng khuyến nghị) Branch: `main` hoặc `master`
   - Click **Next**.
   - Trên màn hình **Add permissions**, tìm và attach policy `AmazonEC2ContainerRegistryPowerUser`. Điều này cung cấp đủ quyền để đăng nhập và push image vào ECR.
   - Click **Next**.
   - Đặt tên cho role, như `WorkshopGitHubActionsRole` _(Nhớ tên role. Bạn sẽ sử dụng role này để deploy vào EKS cluster sau)_
   - Tạo role.
   - **QUAN TRỌNG**: Click vào role mới mà bạn vừa tạo và copy ARN của nó. Nó sẽ giống như `arn:aws:iam::<<AWS Account ID>>:role/WorkshopGitHubActionsRole`. Bạn sẽ cần điều này cho bước tiếp theo.

## Tạo GitHub Actions CI Workflow

Đây là trung tâm của quá trình build và scan tự động của chúng ta.

1. **Tạo cấu trúc thư mục workflow:**

   ```bash
   mkdir -p .github/workflows
   ```

2. **Tạo file workflow `ci.yml`:**

   ```bash
   touch .github/workflows/ci.yml
   ```

3. **Dán YAML sau vào `.github/workflows/ci.yml`.** Thay thế placeholder bằng Role ARN thực tế của bạn.

   ```yaml
   # .github/workflows/ci.yml
   name: CI Workflow for EKS Workshop

   # Workflow này chạy trên mọi push vào branch main
   on:
     push:
       branches: [main]
     # Cho phép bạn chạy workflow này thủ công từ tab Actions
     workflow_dispatch:

   env:
     AWS_REGION: us-east-2 # AWS region của bạn
     ECR_REPOSITORY: workshop-app # Tên ECR repository của bạn
     EKS_CLUSTER_NAME: workshop-cluster # Tên EKS cluster của bạn

   jobs:
     build-scan-push:
       name: Build, Scan & Push
       runs-on: ubuntu-latest
       outputs:
         image: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ steps.image-def.outputs.tag }}
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

         - name: Login to Amazon ECR
           id: login-ecr
           uses: aws-actions/amazon-ecr-login@v2

         - name: Define image tag
           id: image-def
           run: echo "tag=${{ github.sha }}" >> $GITHUB_OUTPUT

         - name: Build, tag, and push image to Amazon ECR
           id: build-image
           env:
             ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
             IMAGE_TAG: ${{ steps.image-def.outputs.tag }}
           run: |
             docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG -f app/Dockerfile ./app
             docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

         - name: Security Scan with Trivy
           uses: aquasecurity/trivy-action@master
           with:
             image-ref: "${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ steps.image-def.outputs.tag }}"
             format: "table"
             # Fail build nếu Trivy tìm thấy bất kỳ lỗ hổng nào với mức độ nghiêm trọng HIGH hoặc CRITICAL
             exit-code: "1"
             ignore-unfixed: true
             vuln-type: "os,library"
             severity: "CRITICAL,HIGH"
   ```

4. **Commit và push để kích hoạt workflow**

   - **Thêm tất cả file mới vào Git, commit chúng và push:**

     ```bash
     git add .
     git commit -m "feat: Add sample app, Dockerfile, and initial CI workflow"
     git push origin main
     ```

   - **Quan sát phép màu!** Đi đến GitHub repository của bạn, click vào tab **Actions**. Bạn sẽ thấy workflow của mình đang chạy. Click vào nó để xem log cho từng bước. Nó sẽ:
     - Check out code.
     - Kết nối an toàn đến AWS.
     - Đăng nhập vào ECR.
     - Build và push Docker image của bạn.
     - **Quan trọng, sau đó nó sẽ chạy Trivy để quét image mà bạn vừa push.**
