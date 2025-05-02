#!/usr/bin/env bash

# Utility to simplify executing commands in ECS Fargate containers via SSM.
# Automatically lists clusters, services, and tasks for user selection.

set -e # Exit immediately if a command exits with a non-zero status.
# set -o pipefail # Causes pipelines to fail on the first command that fails

# --- Configuration ---
DEFAULT_COMMAND="/bin/bash"

# --- Dependency Check ---
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed or not in PATH." >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH." >&2
    exit 1
fi

echo "Fetching ECS Clusters..."
# Get cluster ARNs and extract names
clusters_json=$(aws ecs list-clusters --output json)
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to list ECS clusters. Check AWS credentials and permissions." >&2
    exit 1
fi

cluster_names=($(echo "$clusters_json" | jq -r '.clusterArns[] | split("/") | .[-1]'))

if [ ${#cluster_names[@]} -eq 0 ]; then
    echo "No ECS clusters found in the current region or account."
    exit 1
fi

echo "Please select the ECS Cluster:"
PS3="Cluster number: "
select cluster_name in "${cluster_names[@]}"; do
    if [[ -n "$cluster_name" ]]; then
        echo "Selected cluster: $cluster_name"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

echo -e "\nFetching Services in cluster '$cluster_name'..."
# Get service ARNs and extract names
services_json=$(aws ecs list-services --cluster "$cluster_name" --output json)
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to list services in cluster '$cluster_name'." >&2
    exit 1
fi

service_names=($(echo "$services_json" | jq -r '.serviceArns[] | split("/") | .[-1]'))

if [ ${#service_names[@]} -eq 0 ]; then
    echo "No services found in cluster '$cluster_name'."
    exit 1
fi

echo "Please select the Service:"
PS3="Service number: "
select service_name in "${service_names[@]}"; do
    if [[ -n "$service_name" ]]; then
        echo "Selected service: $service_name"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

echo -e "\nFetching RUNNING Tasks for service '$service_name' in cluster '$cluster_name'..."
# Get running task ARNs
tasks_json=$(aws ecs list-tasks --cluster "$cluster_name" --service-name "$service_name" --desired-status RUNNING --output json)
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to list tasks for service '$service_name'." >&2
    exit 1
fi

task_arns=($(echo "$tasks_json" | jq -r '.taskArns[]'))

if [ ${#task_arns[@]} -eq 0 ]; then
    echo "No RUNNING tasks found for service '$service_name' in cluster '$cluster_name'."
    exit 1
fi

# Extract Task IDs (the last part of the ARN) for display
task_ids=()
for arn in "${task_arns[@]}"; do
    task_ids+=("$(basename "$arn")")
done

echo "Please select the Task ID to connect to:"
PS3="Task number: "
select task_id in "${task_ids[@]}"; do
    if [[ -n "$task_id" ]]; then
        # Find the full ARN corresponding to the selected ID
        for arn in "${task_arns[@]}"; do
            if [[ "$arn" == *"/$task_id" ]]; then
                selected_task_arn="$arn"
                break
            fi
        done
        echo "Selected task ID: $task_id (ARN: $selected_task_arn)"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

echo -e "\nFetching Task details for $task_id..."
# Describe the selected task to check for execute-command enablement and get container names
task_details_json=$(aws ecs describe-tasks --cluster "$cluster_name" --tasks "$selected_task_arn" --output json)
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to describe task '$task_id'." >&2
    exit 1
fi

# Check if execute-command is enabled
execute_enabled=$(echo "$task_details_json" | jq -r '.tasks[0].enableExecuteCommand')
if [[ "$execute_enabled" != "true" ]]; then
    echo "Error: Execute command is not enabled for task $task_id." >&2
    echo "Please update the service or task definition with 'enableExecuteCommand = true'." >&2
    exit 1
fi

# Get container names
container_names=($(echo "$task_details_json" | jq -r '.tasks[0].containers[].name'))

if [ ${#container_names[@]} -eq 0 ]; then
    echo "Error: No containers found in task $task_id." >&2
    exit 1
elif [ ${#container_names[@]} -eq 1 ]; then
    # Auto-select if only one container
    selected_container_name="${container_names[0]}"
    echo "Auto-selecting the only container: $selected_container_name"
else
    echo "Please select the Container within task $task_id:"
    PS3="Container number: "
    select container_choice in "${container_names[@]}"; do
        if [[ -n "$container_choice" ]]; then
            selected_container_name="$container_choice"
            echo "Selected container: $selected_container_name"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
fi

# --- Get Command ---
read -p "Enter command to execute [default: ${DEFAULT_COMMAND}]: " command_to_run
command_to_run=${command_to_run:-$DEFAULT_COMMAND} # Use default if empty

echo -e "\nExecuting command '$command_to_run' in container '$selected_container_name' of task '$task_id'..."

# --- Execute Command ---
aws ecs execute-command \
    --cluster "$cluster_name" \
    --task "$selected_task_arn" \
    --container "$selected_container_name" \
    --command "$command_to_run" \
    --interactive

exit_code=$?
echo -e "\nSession ended (Exit Code: $exit_code)."
exit $exit_code
