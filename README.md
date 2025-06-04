# API Gateway + Terraform + OpenAPI デモプロジェクト

FIXME: 概要を後で書く

## 構成

- API Gateway (REST API)
- Lambda (Node.js)
- OpenAPI テンプレート (templatefile で変数注入)
- Terraform
- DevContainer (VSCode)

## セットアップ手順

1. Lambda ディレクトリで zip を作成

   ```sh
   cd lambda
   zip hello.zip index.js
   mv hello.zip ..
   cd ..
   ```

2. Terraform 初期化・デプロイ

   ```sh
   terraform init
   terraform apply
   ```

3. 出力された `api_endpoint` にアクセスし、`/hello` でレスポンスを確認

   ```sh
   curl <api_endpoint>/hello
   # => { "message": "Hello from Lambda!" }
   ```
