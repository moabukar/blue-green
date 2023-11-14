resource "aws_codebuild_project" "code_build_project" {
  badge_enabled  = false
  build_timeout  = 60
  name           = "app-codebuild"
  queued_timeout = 480
  service_role   = var.codebuild_service_role
  tags = {
    Environment = var.env
  }

  artifacts {
    encryption_disabled    = false
    name                   = "app-codebuild"
    override_artifact_name = false
    packaging              = "NONE"
    type                   = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  source {
    #buildspec           = "NO_SOURCE"
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"
  }
}
