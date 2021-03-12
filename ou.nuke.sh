#!/bin/bash
set -e 
ORGANIZATIONAL_UNIT_NAME=$1
ROOT_ID=$(aws organizations list-roots | jq -r .Roots[0].Id )
OU_LIST=$(aws organizations list-organizational-units-for-parent --parent-id $ROOT_ID)
ORGANIZATIONAL_UNIT_ARN=$(echo $OU_LIST | jq -r "select(.OrganizationalUnits[] | .Name == \"$ORGANIZATIONAL_UNIT_NAME\") | .OrganizationalUnits[].Arn")
ORGANIZATIONAL_UNIT_ID=$(echo $ORGANIZATIONAL_UNIT_ARN | cut -f 3 -d '/')
ACCOUNTS=$(aws organizations list-accounts-for-parent --parent-id $ORGANIZATIONAL_UNIT_ID | jq -r '.Accounts[] | select(.Status=="ACTIVE") | .Id')
for ACCOUNT_ID in $ACCOUNTS; do
    echo "nuking resources for aws member account with Id: $ACCOUNT_ID"
    #assume member account admin role
    AWS_SESSION=$(aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT_ID:role/OrganizationAccountAccessRole --role-session-name aws-account-vendor --output json)
    AWS_ACCESS_KEY_ID=$(echo $AWS_SESSION | jq -r .Credentials.AccessKeyId )
    AWS_SECRET_ACCESS_KEY=$(echo $AWS_SESSION | jq -r .Credentials.SecretAccessKey )
    AWS_SESSION_TOKEN=$(echo $AWS_SESSION | jq -r .Credentials.SessionToken )
    #Nuke Account Resources
cat << EOF > $ACCOUNT_ID.nuke.yml
---
regions:
  - "us-east-1"
  - "us-east-2"
  - "global"
account-blacklist:
  - 999999999999
accounts: 
  "$ACCOUNT_ID": 
    filters:
      IAMRole:
        - "OrganizationAccountAccessRole"
      IAMRolePolicy:
        - "OrganizationAccountAccessRole -> AdministratorAccess"
EOF
    aws-nuke --config $ACCOUNT_ID.nuke.yml --access-key-id $AWS_ACCESS_KEY_ID --secret-access-key $AWS_SECRET_ACCESS_KEY --session-token $AWS_SESSION_TOKEN --force --no-dry-run 
    rm -f $ACCOUNT_ID.nuke.yml
    rm -f $ACCOUNT_ID.aws.json
    #delete account alias
    echo "deleting aws member account alias..."
    aws iam delete-account-alias --account-alias aws-$ACCOUNT_ID --profile $ACCOUNT_ID
    echo "moving aws member account $ACCOUNT_ID from OU named $ORGANIZATIONAL_UNIT_NAME to root OU..."
    aws organizations move-account --account-id $ACCOUNT_ID --source-parent-id $ORGANIZATIONAL_UNIT_ID --destination-parent-id $ROOT_ID
done
echo "deleting OU $ORGANIZATIONAL_UNIT_NAME..."
OU_LIST=$(aws organizations list-organizational-units-for-parent --parent-id $ROOT_ID --output json)
ORGANIZATIONAL_UNIT_ARN=$(echo $OU_LIST | jq -r '.OrganizationalUnits[] | select(.Name=="'$ORGANIZATIONAL_UNIT_NAME'") | .Arn')
ORGANIZATIONAL_UNIT_ID=$(echo $ORGANIZATIONAL_UNIT_ARN | cut -f 3 -d '/')
echo "deleting OU with Id: $ORGANIZATIONAL_UNIT_ID"
OU_POLICIES=$(aws organizations list-policies-for-target --filter SERVICE_CONTROL_POLICY --target-id $ORGANIZATIONAL_UNIT_ID --output json)
POLICY_ID=$(echo $OU_POLICIES | jq -r '.Policies[] | select( .Name=="'$ORGANIZATIONAL_UNIT_NAME'-service-control-policy") | .Id')
echo "deleting OU policy with Id: $POLICY_ID"
aws organizations detach-policy --policy-id $POLICY_ID --target-id $ORGANIZATIONAL_UNIT_ID --output json
aws organizations delete-policy --policy-id $POLICY_ID --output json
aws organizations delete-organizational-unit --organizational-unit-id $ORGANIZATIONAL_UNIT_ID --output json
echo "done."