# Playground for testing blue-green deployments on AWS via different methods

- ECS via CodeDeployment
- ALB

```bash

aws ecs describe-task-definition — task-definition “$ecs_task_def_name” — query taskDefinition > task-definition.json

```

Deploy:

```bash
aws deploy create-deployment --cli-input-yaml file://appspec.yaml

```
