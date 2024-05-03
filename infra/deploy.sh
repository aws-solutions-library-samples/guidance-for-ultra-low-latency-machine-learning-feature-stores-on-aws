#!/bin/bash
set -ux

# 1) CONFIG
# read the configuration file to load variables into this shell script
source config

export FEAST_BUCKET_NAME="${PROJECT_NAME}-bucket"

# 2) 
echo "Checking if the stack exist"
if ! aws cloudformation describe-stacks --stack-name $EC_FS_STACK  --region "us-west-2" | grep 'StackName' ; then
        aws cloudformation create-stack \
                --stack-name $EC_FS_STACK \
                --template-body file://template.yaml \
                --capabilities CAPABILITY_NAMED_IAM \
                --region 'us-west-2' \
                --parameters \
                        ParameterKey=pAdminPassword,ParameterValue="thisISyourPassword1" \
                        ParameterKey=pProjectName,ParameterValue=$PROJECT_NAME \
                        ParameterKey=pRedshiftSubnetGroup,ParameterValue=$SUBNET_ID

else
        aws cloudformation update-stack \
                --stack-name $EC_FS_STACK \
                --template-body file://template.yaml \
                --capabilities CAPABILITY_NAMED_IAM \
                --region 'us-west-2' \
                --parameters \
                        ParameterKey=pAdminPassword,ParameterValue="thisISyourPassword1" \
                        ParameterKey=pProjectName,ParameterValue=$PROJECT_NAME \
                        ParameterKey=pRedshiftSubnetGroup,ParameterValue=$SUBNET_ID
fi

sleep 60s

aws s3api put-object --bucket $FEAST_BUCKET_NAME \
        --key "zipcode_table/table.parquet" \
        --body "../data/zipcode_table.parquet"


aws s3api put-object --bucket $FEAST_BUCKET_NAME \
        --key "credit_history/table.parquet" \
        --body "../data/credit_history.parquet"

aws s3api put-object --bucket $FEAST_BUCKET_NAME \
        --key "loan_features/table.parquet" \
        --body "../data/loan_table.parquet"