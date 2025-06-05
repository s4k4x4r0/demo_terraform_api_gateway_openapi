# API Gateway + Terraform + OpenAPI デモプロジェクト

API Gateway の REST API を OpenAPI テンプレートで定義し、Terraform でデプロイするデモプロジェクト。
Cognito User Pool を認証に使用する。

## 構成

- API Gateway (REST API)
- Lambda (Node.js)
- OpenAPI テンプレート (templatefile で変数注入)
- Terraform
- DevContainer (VSCode)

## デモ手順

1. Lambda ディレクトリで zip を作成

   ```sh
   cd lambda
   zip hello.zip index.js
   cd ..
   ```

2. Terraform 初期化・デプロイ

   ```sh
   terraform init
   terraform apply
   ```

3. ユーザー作成

   ```sh
   username=<user_name>
   password=<password>

   cognito_user_pool_id=$(terraform output -raw cognito_user_pool_id)
   aws cognito-idp admin-create-user --user-pool-id $cognito_user_pool_id --username $username
   aws cognito-idp admin-set-user-password --user-pool-id $cognito_user_pool_id --username $username --password $password --permanent
   ```

4. トークン取得

   ```sh
   cognito_user_pool_client_id=$(terraform output -raw cognito_user_pool_client_id)
   idToken=$(aws cognito-idp initiate-auth --auth-flow USER_PASSWORD_AUTH --auth-parameters "USERNAME=$username,PASSWORD=$password" --client-id $cognito_user_pool_client_id | jq -r '.AuthenticationResult.IdToken')
   ```

5. 出力された `api_endpoint` にアクセスし、`/hello` でレスポンスを確認

   ```sh
   api_endpoint=$(terraform output -raw api_endpoint)
   curl $api_endpoint/hello -H "Authorization: Bearer $idToken"
   # => { "message": "Hello from Lambda!" }
   ```
