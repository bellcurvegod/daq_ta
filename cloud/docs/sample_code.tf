# AWS IoT Core - MQTT Protocol for Data Transmission
resource "aws_iot_topic_rule" "weather_data_ingestion" {
  name        = "weather_data_ingestion"
  sql         = "SELECT * FROM 'weather/station/data'"

  dynamodbv2 {
    role_arn   = aws_iam_role.iot_dynamodb_role.arn
    table_name = aws_dynamodb_table.weather_data.name
  }

  s3 {
    role_arn    = aws_iam_role.iot_s3_role.arn
    bucket_name = aws_s3_bucket.weather_logs.bucket
    key         = "weather_data_${timestamp()}.json"
  }

  sns {
    role_arn    = aws_iam_role.iot_sns_role.arn
    target_arn  = aws_sns_topic.weather_alerts.arn
    message_format = "JSON"
  }
}

# AWS SNS for Extreme Weather Alerts 
resource "aws_sns_topic" "weather_alerts" {
  name = "weather-alerts"
}

resource "aws_sns_topic_subscription" "weather_alert_email" {
  topic_arn = aws_sns_topic.weather_alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"
}

### DynamoDB Table for Weather Data ###
resource "aws_dynamodb_table" "weather_data" {
  name         = "WeatherData"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "timestamp"

  attribute {
    name = "timestamp"
    type = "S"
  }
}

# S3 Weather Log Bucket 
resource "aws_s3_bucket" "weather_logs" {
  bucket = "weather-data-logs"
}

# ECS Fargate Cluster for weather-streaming
resource "aws_ecs_task_definition" "weather-streaming" {
  family                   = "weather-streaming"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "weather-streaming"
      image     = "your-docker-repo/weather-streaming:latest"
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        { name = "SNS_TOPIC_ARN", value = aws_sns_topic.weather_alerts.arn }
      ]
    }
  ])
}

### IAM Role for AWS IoT to DynamoDB ###
resource "aws_iam_role" "iot_dynamodb_role" {
  name = "IoTDynamoDBRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "iot.amazonaws.com"
      }
    }]
  })

  inline_policy {
    name = "IoTDynamoDBPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["dynamodb:PutItem"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.weather_data.arn
      }]
    })
  }
}

