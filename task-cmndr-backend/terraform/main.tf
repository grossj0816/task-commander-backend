terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "tc-terraform-state-storage-s3"
    key            = "app-task-cmndr-backend"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  subnets = ["Lambda Subnet 1", "Lambda Subnet 2"]
}


# -------------------- START NETWORKING --------------------------
data "aws_vpc" "dev_vpc" {
  filter {
    name   = "tag:Name"
    values = ["DEV-VPC"]
  }
}


data "aws_security_groups" "lambda_sg" {
  filter {
    name   = "group-name"
    values = ["DEV VPC Lambda SG"]
  }
}


data "aws_subnets" "lambda_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dev_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = local.subnets
  }
}
# ------------------- END NETWORKING ------------------------------


# ------------------- START PULLING SECRETS -----------------------
data "aws_secretsmanager_secret" "dev_db_secret" {
  name = "DEV_DB_SECRET"
}


data "aws_secretsmanager_secret_version" "secret_credentials" {
  secret_id = data.aws_secretsmanager_secret.dev_db_secret.id
}
# ------------------ END PULLING SECRETS ---------------------------


# IAM ROLE FOR LAMBDA ----------------------------
data "aws_iam_role" "iam_role_for_task_cmndr_lambda" {
  name = "iam_role_for_task_cmndr_lambdas"
}

resource "aws_s3_object" "task-cmndr-object" {
  bucket = "tu-api-lambda-deploys"
  key    = "task_cmndr_app/lambdas.zip"
  source = "../lambdas/lambdas.zip"
  etag   = filemd5("../lambdas/lambdas.zip")
}

# create task-cmnder-db tables ------------------------------------
# TODO: FILL OUT "SOURCE_ARN" VALUE WHEN I FINISH SRC CODE IN API-GW.TF
resource "aws_lambda_permission" "create_tables_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_tables_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.task-cmndr-api-gateway.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "create_tables_lambda" {
  name              = "aws/lambda/${aws_lambda_function.create_tables_lambda.function_name}"
  retention_in_days = 30
  skip_destroy      = false
}

resource "aws_lambda_function" "create_tables_lambda" {
  depends_on       = [aws_s3_object.task-cmndr-object]
  s3_bucket        = "tu-api-lambda-deploys"
  s3_key           = "task_cmndr_app/lambdas.zip"
  function_name    = "create-task-cmndr-db-tables"
  source_code_hash = filebase64sha256("../lambdas/lambdas.zip")
  role             = data.aws_iam_role.iam_role_for_task_cmndr_lambda.arn
  handler          = "db_tables.create_task_cmndr_db_tables"
  runtime          = "python3.12"
  architectures    = ["arm64"]
  timeout          = 240
  vpc_config {
    subnet_ids         = data.aws_subnets.lambda_subnets.ids
    security_group_ids = data.aws_security_groups.lambda_sg.ids
  }

  environment {
    variables = {
      HOST          = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["host"]
      DATABASE_NAME = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["dbname"]
      USERNAME      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["username"]
      PASSWORD      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["password"]
    }
  }
}


