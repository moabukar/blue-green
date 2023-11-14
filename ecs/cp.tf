resource "aws_codepipeline" "codepipeline" {
  name     = "app-pipeline"
  role_arn = var.codepipeline_role
  tags     = {
    Environment = var.env
  }

  artifact_store {
    location = var.artifacts_bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      namespace = "SourceVariables"

      configuration = {
        ConnectionArn    = "${var.codestart_connection_arn}"
        FullRepositoryId = "${var.repo_name}"
        BranchName       = "${var.repo_branch_name}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      category = "Build"
      configuration = {
        "EnvironmentVariables" = jsonencode(
          [
            {
              name  = "AWS_ACCOUNT_ID"
              type  = "PLAINTEXT"
              value = var.account_id
            },
            {
              name  = "AWS_REGION"
              type  = "PLAINTEXT"
              value = var.region
            }
          ]
        )
        "ProjectName" = "apps-codebuild"
      }
      input_artifacts = [
        "SourceArtifact",
      ]
      namespace = "BuildVariables"
      name = "Build"
      output_artifacts = [
        "BuildArtifact",
      ]
      owner     = "AWS"
      provider  = "CodeBuild"
      run_order = 1
      version   = "1"
    }
  }

   stage {
    name = "Deploy"

    action {
      name = "Deploy"
      category = "Deploy"
      owner = "AWS"
      provider = "CodeDeploy"
      input_artifacts = ["BuildArtifact"]
      namespace = "DeployVariables"
      version = "1"

      configuration = {
        ApplicationName = "Enter_applicationname"
        DeploymentGroupName = "Enter_deploymentgroup"
      }
    }
  }
}
