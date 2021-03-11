#!/bin/bash
set -e 
ACCOUNT_ID=$1  
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
aws-nuke --config $ACCOUNT_ID.nuke.yml \
  --access-key-id $AWS_ACCESS_KEY_ID \
  --secret-access-key $AWS_SECRET_ACCESS_KEY \
  --session-token $AWS_SESSION_TOKEN \
  --force \
  --no-dry-run 
rm -f $ACCOUNT_ID.nuke.yml
#delete account alias
echo "deleting aws member account alias..."
aws iam delete-account-alias --account-alias aws-$ACCOUNT_ID --profile $ACCOUNT_ID
