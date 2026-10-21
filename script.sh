#!/bin/bash

STACK_NAME="ecs"
TEMPLATE_FILE="ecs-project.yaml"
REGION="us-east-1"

command="$1"

if [ "$command" = "validate" ]; then
    echo "Validating CloudFormation template..."

    aws cloudformation validate-template \
        --template-body "file://$TEMPLATE_FILE" \
        --region "$REGION" \
        --no-cli-pager

    if [ "$?" -eq 0 ]; then
        echo "Template validation successful."
    else
        echo "Template validation failed."
        exit 1
    fi

elif [ "$command" = "create" ]; then
    echo "Validating CloudFormation template..."

    aws cloudformation validate-template \
        --template-body "file://$TEMPLATE_FILE" \
        --region "$REGION" \
        --no-cli-pager || exit 1

    read -r -s -p "Enter database password: " DB_PASSWORD

    echo "Creating CloudFormation stack..."

    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE" \
        --parameters "ParameterKey=DBPassword,ParameterValue=$DB_PASSWORD" \
        --capabilities CAPABILITY_IAM \
        --region "$REGION" \
        --no-cli-pager

    result=$?
    unset DB_PASSWORD

    if [ "$result" -eq 0 ]; then
        echo "Waiting for stack creation to complete..."

        aws cloudformation wait stack-create-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"

        if [ "$?" -eq 0 ]; then
            echo "Stack created successfully!"
        else
            echo "Stack creation did not complete successfully."
            exit 1
        fi
    else
        echo "Stack creation request failed."
        exit 1
    fi

elif [ "$command" = "update" ]; then
    echo "Validating CloudFormation template..."

    aws cloudformation validate-template \
        --template-body "file://$TEMPLATE_FILE" \
        --region "$REGION" \
        --no-cli-pager || exit 1

    echo "Updating CloudFormation stack..."

    aws cloudformation update-stack \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE" \
        --parameters "ParameterKey=DBPassword,UsePreviousValue=true" \
        --capabilities CAPABILITY_IAM \
        --region "$REGION" \
        --no-cli-pager

    if [ "$?" -eq 0 ]; then
        echo "Waiting for stack update to complete..."

        aws cloudformation wait stack-update-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"

        if [ "$?" -eq 0 ]; then
            echo "Stack updated successfully!"
        else
            echo "Stack update did not complete successfully."
            exit 1
        fi
    else
        echo "Stack update request failed."
        exit 1
    fi

elif [ "$command" = "delete" ]; then
    echo "Deleting CloudFormation stack..."

    aws cloudformation delete-stack \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --no-cli-pager

    if [ "$?" -eq 0 ]; then
        echo "Waiting for stack deletion to complete..."

        aws cloudformation wait stack-delete-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"

        if [ "$?" -eq 0 ]; then
            echo "Stack deleted successfully!"
        else
            echo "Stack deletion did not complete successfully."
            exit 1
        fi
    else
        echo "Stack deletion request failed."
        exit 1
    fi

else
    echo "Usage: ./deploy.sh {validate|create|update|delete}"
    exit 1
fi
