terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.99.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.7.1"
    }
  }
  required_version = ">= 1.12.1"
}

provider "aws" {
  region = var.aws_region
}

locals {
  project_prefix = "tf-apigw-oa"
}

data "aws_iam_policy_document" "lambda_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "hello" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/hello"
  output_path = "${path.module}/lambda/hello/index.zip"
}

data "archive_file" "uppercase" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/uppercase"
  output_path = "${path.module}/lambda/uppercase/index.zip"
}

resource "aws_lambda_function" "hello" {
  function_name    = "${local.project_prefix}-hello"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda_exec.arn
  filename         = data.archive_file.hello.output_path
  source_code_hash = filebase64sha256(data.archive_file.hello.output_path)
}

resource "aws_lambda_function" "uppercase" {
  function_name    = "${local.project_prefix}-uppercase"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda_exec.arn
  filename         = data.archive_file.uppercase.output_path
  source_code_hash = filebase64sha256(data.archive_file.uppercase.output_path)
}

resource "aws_api_gateway_rest_api" "api" {
  name = local.project_prefix
  body = data.template_file.openapi.rendered
}

data "template_file" "openapi" {
  template = file("${path.module}/openapi.yaml")
  vars = {
    lambda_hello_invoke_arn     = aws_lambda_function.hello.invoke_arn
    lambda_uppercase_invoke_arn = aws_lambda_function.uppercase.invoke_arn
    cognito_user_pool_arn       = aws_cognito_user_pool.main.arn
  }
}

resource "aws_api_gateway_deployment" "latest" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    openapi = data.template_file.openapi.rendered
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "latest" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "latest"
  deployment_id = aws_api_gateway_deployment.latest.id
}

resource "aws_lambda_permission" "apigw_hello" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_uppercase" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.uppercase.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_cognito_user_pool" "main" {
  name = local.project_prefix
}

resource "aws_cognito_user_pool_client" "main" {
  name         = local.project_prefix
  user_pool_id = aws_cognito_user_pool.main.id

  # ALLOW_USER_PASSWORD_AUTHよりも、よりセキュアな認証フローを使用した方が良い
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}
