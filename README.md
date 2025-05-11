# ECS Exec Utility

A command-line utility that simplifies executing commands in AWS ECS Fargate containers using AWS's execute-command functionality.

## Features

- Interactive selection of ECS clusters, services, tasks, and containers
- Automatic discovery of available resources in your AWS environment
- Command history and tab completion in the shell session
- Support for custom commands with a default fallback to `/bin/bash`
- Dependency checking to ensure required tools are available

## Prerequisites

- AWS CLI v2 (configured with appropriate permissions)
- jq
- A bash-compatible shell
- AWS ECS service with `enableExecuteCommand` enabled

## Installation

### Quick Install (Recommended)

Install directly from GitHub to your user's bin directory:

```bash
curl -sSL https://raw.githubusercontent.com/cyqlelabs/ecs-exec/main/install.sh | bash
```

This will:
1. Download and install the utility to `~/.local/bin/ecs-exec`
2. Make it executable
3. Check for required dependencies
4. Provide instructions if the directory is not in your PATH

### Manual Installation

If you prefer manual installation:

1. Clone this repository or download the script files
2. Make the script executable: `chmod +x ecs-exec.sh`
3. Move the script to a directory in your PATH:
   ```bash
   mkdir -p ~/.local/bin
   cp ecs-exec.sh ~/.local/bin/ecs-exec
   ```
4. Make sure `~/.local/bin` is in your PATH

## Usage

Simply run the command with no arguments:

```bash
ecs-exec
```

The utility will:

1. List available ECS clusters for selection
2. List services within the selected cluster
3. List running tasks for the selected service
4. List containers within the selected task (auto-selects if only one exists)
5. Prompt for the command to execute (defaults to `/bin/bash`)
6. Open an interactive session in the selected container

### Example Session

```
$ ecs-exec
Fetching ECS Clusters...
Please select the ECS Cluster:
1) my-production-cluster
2) my-staging-cluster
Cluster number: 1
Selected cluster: my-production-cluster

Fetching Services in cluster 'my-production-cluster'...
Please select the Service:
1) api-service
2) worker-service
3) frontend-service
Service number: 1
Selected service: api-service

Fetching RUNNING Tasks for service 'api-service' in cluster 'my-production-cluster'...
Please select the Task ID to connect to:
1) 1a2b3c4d5e6f7g8h9i0j
2) 2b3c4d5e6f7g8h9i0j1k
Task number: 1
Selected task ID: 1a2b3c4d5e6f7g8h9i0j (ARN: arn:aws:ecs:us-west-2:123456789012:task/my-production-cluster/1a2b3c4d5e6f7g8h9i0j)

Fetching Task details for 1a2b3c4d5e6f7g8h9i0j...
Auto-selecting the only container: api-container
Enter command to execute [default: /bin/bash]: 

Executing command '/bin/bash' in container 'api-container' of task '1a2b3c4d5e6f7g8h9i0j'...

The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.
Starting session with SessionId: ecs-execute-command-0abcdef1234567890

root@ip-10-0-52-33:/# ls
app  bin  boot  dev  etc  home  lib  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var

root@ip-10-0-52-33:/# exit
exit

Session ended (Exit Code: 0).
```

## AWS Permissions Required

The user or role executing this utility needs at least the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:ListClusters",
                "ecs:ListServices",
                "ecs:ListTasks",
                "ecs:DescribeTasks"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:ExecuteCommand"
            ],
            "Resource": "arn:aws:ecs:*:*:task/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession"
            ],
            "Resource": "arn:aws:ecs:*:*:task/*"
        }
    ]
}
```

## Troubleshooting

### Execute Command is Not Enabled

If you receive an error stating that execute command is not enabled for a task, make sure that:

1. Your ECS service has `enableExecuteCommand` set to `true`
2. Your task definition includes the `AWS_USE_FIPS` and `ECS_EXEC_SIDECAR` environment variables
3. Your task has the correct IAM roles with SSM permissions

See [AWS Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html) for more details.

### Permissions Issues

If you encounter permission issues, ensure your AWS CLI is configured with credentials that have the necessary permissions outlined above.

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Feel free to submit a pull request or open an issue for bugs and feature requests.
