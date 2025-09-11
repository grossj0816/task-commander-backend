resource "aws_api_gateway_rest_api" "task-cmndr-api-gateway" {
  name        = "task-cmndr-api-gateway"
  description = "AWS Rest API for Task Commander App."

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Queries a JSON iam policy doc result from what we described from the data source
data "aws_iam_policy_document" "gateway_policy" {
  statement {
    effect  = "Allow"
    actions = ["execute-api:Invoke"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = ["execute-api:/*"]
  }
}


resource "aws_api_gateway_rest_api_policy" "policy" {
  rest_api_id = aws_api_gateway_rest_api.task-cmndr-api-gateway.id
  policy      = data.aws_iam_policy_document.gateway_policy.json
}

# ENDPOINT RESOURCES -----------------------------------------------
resource "aws_api_gateway_resource" "create_task_cmndr_db_tables" {
  rest_api_id = aws_api_gateway_rest_api.task-cmndr-api-gateway.id
  parent_id   = aws_api_gateway_rest_api.task-cmndr-api-gateway.root_resource_id
  path_part   = "cr_tables"
}


# ENDPOINT MODULES --------------------------------------------------
module "create_task_cmndr_db_tables" {
  source          = "./gw-method-and-intg-resources"
  apigateway      = aws_api_gateway_rest_api.task-cmndr-api-gateway
  resource        = aws_api_gateway_resource.create_task_cmndr_db_tables
  lambda_function = aws_lambda_function.create_tables_lambda
  authorization   = "NONE"
  httpmethod      = "GET"
}

# DEPLOYMENT & STAGE CODE BLOCKS -------------------------------------
resource "aws_api_gateway_deployment" "task-cmndr-backend-deployment" {
  rest_api_id = aws_api_gateway_rest_api.task-cmndr-api-gateway.id
  depends_on  = [module.create_task_cmndr_db_tables]
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_stage" "r" {
  stage_name    = "r"
  rest_api_id   = aws_api_gateway_rest_api.task-cmndr-api-gateway.id
  deployment_id = aws_api_gateway_deployment.task-cmndr-backend-deployment.id
  depends_on    = [aws_api_gateway_rest_api.task-cmndr-api-gateway]
}