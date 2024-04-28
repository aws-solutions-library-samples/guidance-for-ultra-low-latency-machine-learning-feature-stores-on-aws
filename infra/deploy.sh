#!/bin/bash
set -ux

export EC_FS_STACK="elastic-cache-feature-store-stack"

echo $EC_FS_STACK

# 2) 
echo "Checking if the stack exist"
if ! aws cloudformation describe-stacks --stack-name $EC_FS_STACK  --region "us-west-2" | grep 'StackName' ; then
        aws cloudformation create-stack \
                --stack-name $EC_FS_STACK \
                --template-body file://template.yaml \
                --capabilities CAPABILITY_NAMED_IAM \
                --region 'us-west-2' \
                --parameters ParameterKey=pAdminPassword,ParameterValue="thisISyourPassword1"
else
        aws cloudformation update-stack \
                --stack-name $EC_FS_STACK \
                --template-body file://template.yaml \
                --capabilities CAPABILITY_NAMED_IAM \
                --region 'us-west-2' \
                --parameters ParameterKey=pAdminPassword,ParameterValue="thisISyourPassword1"
fi

sleep 10s

aws s3api put-object --bucket "demo-feast-project-aws-test-bucket" \
        --key "zipcode_table/table.parquet" \
        --body "../data/zipcode_table.parquet"


aws s3api put-object --bucket "demo-feast-project-aws-test-bucket" \
        --key "credit_history/table.parquet" \
        --body "../data/credit_history.parquet"

aws s3api put-object --bucket "demo-feast-project-aws-test-bucket" \
        --key "loan_features/table.parquet" \
        --body "../data/loan_table.parquet"