#!/bin/bash
set -e 
ORGANIZATIONAL_UNIT_NAME=$1
AWS_REGION="us-east-2"
OU_SCP="aws.scp.json"
AWS_ACCOUNT_BASELINE_TEMPLATE="aws.cfn.yml"
echo "creating OU $ORGANIZATIONAL_UNIT_NAME..."
ROOT_ID=$(aws organizations list-roots --output json | jq -r .Roots[0].Id )
ORGANIZATIONAL_UNIT=$(aws organizations create-organizational-unit --parent-id $ROOT_ID --name $ORGANIZATIONAL_UNIT_NAME --output json)
ORGANIZATIONAL_UNIT_ID=$(echo $ORGANIZATIONAL_UNIT | jq -r .OrganizationalUnit.Id )
echo "creating OU with Id: $ORGANIZATIONAL_UNIT_ID"
POLICY=$(aws organizations create-policy --name $ORGANIZATIONAL_UNIT_NAME-service-control-policy --description "$ORGANIZATIONAL_UNIT_NAME Service Control Policy" --content file://$OU_SCP --type SERVICE_CONTROL_POLICY --output json)
POLICY_ARN=$(echo $POLICY | jq -r .Policy.PolicySummary.Arn)
POLICY_ID=$(echo $POLICY_ARN | cut -f 4 -d '/')
echo "creating OU policy with Id: $POLICY_ID"
aws organizations attach-policy --policy-id $POLICY_ID --target-id $ORGANIZATIONAL_UNIT_ID
OU_LIST=$(aws organizations list-organizational-units-for-parent --parent-id $ROOT_ID)
ORGANIZATIONAL_UNIT_ARN=$(echo $OU_LIST | jq -r "select(.OrganizationalUnits[] | .Name == \"$ORGANIZATIONAL_UNIT_NAME\") | .OrganizationalUnits[].Arn")
ORGANIZATIONAL_UNIT_ID=$(echo $ORGANIZATIONAL_UNIT_ARN | cut -f 3 -d '/')
echo "setting up AWS member accounts that are ACTIVE and CREATED by the Organization..."
ACCOUNTS=$(aws organizations list-accounts-for-parent --parent-id $ROOT_ID --output json | jq -r '.Accounts[] | select((.JoinedMethod=="CREATED") and (.Status=="ACTIVE")) | .Id')
for ACCOUNT_ID in $ACCOUNTS; do
    echo "moving aws member account $ACCOUNT_ID from root OU to OU named $ORGANIZATIONAL_UNIT_NAME ..."
    aws organizations move-account --account-id $ACCOUNT_ID --source-parent-id $ROOT_ID --destination-parent-id $ORGANIZATIONAL_UNIT_ID
    echo "running resource setup for aws member account with Id: $ACCOUNT_ID"
    IAM_USERNAME="administrator"
    IAM_PASSWORD=$(openssl rand -base64 14)
    echo "assuming aws member account admin role..."
    AWS_SESSION=$(aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT_ID:role/OrganizationAccountAccessRole --role-session-name aws-cli-session)
    aws configure set aws_access_key_id $(echo $AWS_SESSION | jq -r .Credentials.AccessKeyId ) --profile $ACCOUNT_ID
    aws configure set aws_secret_access_key $(echo $AWS_SESSION | jq -r .Credentials.SecretAccessKey )  --profile $ACCOUNT_ID
    aws configure set aws_session_token $(echo $AWS_SESSION | jq -r .Credentials.SessionToken ) --profile $ACCOUNT_ID
    aws configure set region $AWS_REGION --profile $ACCOUNT_ID 
    echo "creating aws member account alias..."
    aws iam create-account-alias --account-alias aws-$ACCOUNT_ID --profile $ACCOUNT_ID
    echo "deploying baseline resource stack for aws member account..."
    aws cloudformation deploy --stack-name AWS-ACCOUNT-BASELINE --template-file $AWS_ACCOUNT_BASELINE_TEMPLATE --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND --profile $ACCOUNT_ID --output json
    CFN_OUTPUTS=$(aws cloudformation describe-stacks --stack-name AWS-ACCOUNT-BASELINE --profile $ACCOUNT_ID --output json | jq .Stacks[0].Outputs)
    echo "creating aws member account iam admin user..."
    USER_CONFIRM=$(aws iam create-user --user-name $IAM_USERNAME --profile $ACCOUNT_ID)
    aws iam attach-user-policy --user-name $IAM_USERNAME --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --profile $ACCOUNT_ID 
    PROFILE_CONFIRM=$(aws iam create-login-profile --user-name $IAM_USERNAME --password $IAM_PASSWORD --profile $ACCOUNT_ID)
    ADMINISTRATOR_ACCESS_KEY=$(aws iam create-access-key --user-name $IAM_USERNAME --profile $ACCOUNT_ID ) 
    ADMINISTRATOR_ACCESS_KEY_ID=$(echo $ADMINISTRATOR_ACCESS_KEY | jq -r .AccessKey.AccessKeyId )
    ADMINISTRATOR_SECRET_ACCESS_KEY=$(echo $ADMINISTRATOR_ACCESS_KEY | jq -r .AccessKey.SecretAccessKey )
    #Output
    echo "{ \"LOGIN_URL\":\"https://aws-$ACCOUNT_ID.signin.aws.amazon.com/console\", \
    \"IAM_USERNAME\":\"$IAM_USERNAME\", \
    \"IAM_PASSWORD\":\"$IAM_PASSWORD\", \
    \"ADMINISTRATOR_ACCESS_KEY_ID\":\"$ADMINISTRATOR_ACCESS_KEY_ID\", \
    \"ADMINISTRATOR_SECRET_ACCESS_KEY\":\"$ADMINISTRATOR_SECRET_ACCESS_KEY\", \
    \"CFN_OUTPUT\":\"$CFN_OUTPUTS\" }" | jq . > $ACCOUNT_ID.aws.json
done
echo "done."