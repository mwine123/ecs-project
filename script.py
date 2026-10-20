import subprocess
from getpass import getpass
import sys

command = input("Enter command to run: ")

if command == "validate":
    print("Validating CloudFormation template...")

    subprocess.run([
        "aws", "cloudformation", "validate-template",
        "--template-body", "file://ecs-project.yaml",
        "--region", "us-east-1",
        "--no-cli-pager"
    ], check=True)

elif command == "create":
    print("Creating CloudFormation stack...")

    DB_PASSWORD = getpass("Enter database password: ")

    subprocess.run([
        "aws", "cloudformation", "create-stack",
        "--stack-name", "ecs",
        "--template-body", "file://ecs-project.yaml",
        "--parameters",
        f"ParameterKey=DBPassword,ParameterValue={DB_PASSWORD}",
        "--capabilities", "CAPABILITY_IAM",
        "--region", "us-east-1",
        "--no-cli-pager"
    ], check=True)

    subprocess.run([
        "aws", "cloudformation", "wait", "stack-create-complete",
        "--stack-name", "ecs",
        "--region", "us-east-1"
    ], check=True)

elif command == "update":
    print("Updating CloudFormation stack...")

    subprocess.run([
        "aws", "cloudformation", "update-stack",
        "--stack-name", "ecs",
        "--template-body", "file://ecs-project.yaml",
        "--parameters", "ParameterKey=DBPassword,UsePreviousValue=true",
        "--capabilities", "CAPABILITY_IAM",
        "--region", "us-east-1",
        "--no-cli-pager"
    ], check=True)

    subprocess.run([
        "aws", "cloudformation", "wait", "stack-update-complete",
        "--stack-name", "ecs",
        "--region", "us-east-1"
    ], check=True)

elif command == "delete":
    print("Deleting CloudFormation stack...")

    confirm = input("Are you sure you want to delete the stack? (yes/no): ")

    if confirm.lower() == "yes":
        subprocess.run([
            "aws", "cloudformation", "delete-stack",
            "--stack-name", "ecs",
            "--region", "us-east-1",
            "--no-cli-pager"
        ], check=True)

        subprocess.run([
            "aws", "cloudformation", "wait", "stack-delete-complete",
            "--stack-name", "ecs",
            "--region", "us-east-1"
        ], check=True)

    else:
        print("Stack deletion cancelled.")

else:
    print("Unknown command")
    sys.exit(1)
