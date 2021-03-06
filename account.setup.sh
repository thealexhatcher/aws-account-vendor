#!/bin/bash
set -e 
ACCOUNT_NAME=$1
ACCOUNT_ID=$2
ORGANIZATIONAL_UNIT_ID=$3

echo "moving aws member account to ou..."
ROOT_ID=$(aws organizations list-roots | jq -r .Roots[0].Id )
# Move AWS Member Accout to OU
aws organizations move-account --account-id $ACCOUNT_ID --source-parent-id $ROOT_ID --destination-parent-id $ORGANIZATIONAL_UNIT_ID
sleep 20
echo "done."
#assume AWS Member Account admin role
echo "assuming aws member account admin role..."
AWS_SESSION=$(aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT_ID:role/OrganizationAccountAccessRole --role-session-name aws-cli-session)
aws configure set aws_access_key_id $(echo $AWS_SESSION | jq -r .Credentials.AccessKeyId ) --profile $ACCOUNT_ID
aws configure set aws_secret_access_key $(echo $AWS_SESSION | jq -r .Credentials.SecretAccessKey )  --profile $ACCOUNT_ID
aws configure set aws_session_token $(echo $AWS_SESSION | jq -r .Credentials.SessionToken ) --profile $ACCOUNT_ID
aws configure set aws_default_region "us-east-1" --profile $ACCOUNT_ID 
echo "done."
#create account alias
echo "creating aws member account alias..."
aws iam create-account-alias --account-alias $ACCOUNT_NAME --profile $ACCOUNT_ID
echo "done."
###
# Show Results
###

echo "ACCOUNT_ID: $ACCOUNT_ID"


