#!/bin/bash
set -e 
ACCOUNT_NAME=$1  
ACCOUNT_EMAIL=$2 
###
# AWS Member Account Create
###
echo "creating aws member account.."
ACCOUNT_REQUEST=$(aws organizations create-account --email $ACCOUNT_EMAIL --account-name $ACCOUNT_NAME --role-name OrganizationAccountAccessRole --iam-user-access-to-billing DENY --output json)
while [ "$ACCOUNT_REQUEST_STATUS" != "SUCCEEDED" ]
do
    ACCOUNT_REQUEST_ID=$(echo $ACCOUNT_REQUEST | jq -r .CreateAccountStatus.Id )
    ACCOUNT_REQUEST=$(aws organizations describe-create-account-status --create-account-request-id $ACCOUNT_REQUEST_ID --output json)
    ACCOUNT_REQUEST_STATUS=$(echo $ACCOUNT_REQUEST | jq -r .CreateAccountStatus.State )
done
ACCOUNT_ID=$(echo $ACCOUNT_REQUEST | jq -r .CreateAccountStatus.AccountId )
sleep 20
echo "{\"ACCOUNT_ID\":\"$ACCOUNT_ID\"}"
