#!/bin/bash
set -e 

ACCOUNT_ID=$1
IAM_USERNAME="administrator"
IAM_PASSWORD=$(openssl rand -base64 14)

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
aws iam create-account-alias --account-alias aws-$ACCOUNT_ID --profile $ACCOUNT_ID
echo "done."
#create member account iam admin user 
USER_CONFIRM=$(aws iam create-user --user-name $IAM_USERNAME --profile $ACCOUNT_ID)
aws iam attach-user-policy --user-name $IAM_USERNAME --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --profile $ACCOUNT_ID 
PROFILE_CONFIRM=$(aws iam create-login-profile --user-name $IAM_USERNAME --password $IAM_PASSWORD --profile $ACCOUNT_ID)
ADMINISTRATOR_ACCESS_KEY=$(aws iam create-access-key --user-name $IAM_USERNAME --profile $ACCOUNT_ID ) 
ADMINISTRATOR_ACCESS_KEY_ID=$(echo $ADMINISTRATOR_ACCESS_KEY | jq -r .AccessKey.AccessKeyId )
ADMINISTRATOR_SECRET_ACCESS_KEY=$(echo $ADMINISTRATOR_ACCESS_KEY | jq -r .AccessKey.SecretAccessKey )
#deploy baseline account baseline stack
aws cloudformation deploy \
    --stack-name ACCOUNT_BASELINE \
    --template-file account.baseline.cfn.yml \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --profile $ACCOUNT_ID 
#Output
echo "{ \
    \"IAM_USERNAME\":\"$IAM_USERNAME\", \
    \"IAM_PASSWORD\":\"$IAM_PASSWORD\", \
    \"ADMINISTRATOR_ACCESS_KEY_ID\":\"$ADMINISTRATOR_ACCESS_KEY_ID\", \
    \"ADMINISTRATOR_SECRET_ACCESS_KEY\":\"$ADMINISTRATOR_SECRET_ACCESS_KEY\" \
}"


