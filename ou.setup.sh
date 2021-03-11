#!/bin/bash
set -e 
ORGANIZATIONAL_UNIT_NAME=$1
echo "creating OU $ORGANIZATIONAL_UNIT_NAME..."
ROOT_ID=$(aws organizations list-roots --output json | jq -r .Roots[0].Id )
ORGANIZATIONAL_UNIT=$(aws organizations create-organizational-unit --parent-id $ROOT_ID --name $ORGANIZATIONAL_UNIT_NAME --output json)
ORGANIZATIONAL_UNIT_ID=$(echo $ORGANIZATIONAL_UNIT | jq -r .OrganizationalUnit.Id )
echo "creating OU with Id: $ORGANIZATIONAL_UNIT_ID"
POLICY=$(aws organizations create-policy --name $ORGANIZATIONAL_UNIT_NAME-service-control-policy --description "$ORGANIZATIONAL_UNIT_NAME Service Control Policy" --content file://ou.scp.json --type SERVICE_CONTROL_POLICY --output json)
POLICY_ARN=$(echo $POLICY | jq -r .Policy.PolicySummary.Arn)
POLICY_ID=$(echo $POLICY_ARN | cut -f 4 -d '/')
echo "creating OU policy with Id: $POLICY_ID"
aws organizations attach-policy --policy-id $POLICY_ID --target-id $ORGANIZATIONAL_UNIT_ID
OU_LIST=$(aws organizations list-organizational-units-for-parent --parent-id $ROOT_ID)
ORGANIZATIONAL_UNIT_ARN=$(echo $OU_LIST | jq -r "select(.OrganizationalUnits[] | .Name == \"$ORGANIZATIONAL_UNIT_NAME\") | .OrganizationalUnits[].Arn")
ORGANIZATIONAL_UNIT_ID=$(echo $ORGANIZATIONAL_UNIT_ARN | cut -f 3 -d '/')
#Select Created Member Accounts that are Active from the Root OU
ACCOUNTS=$(aws organizations list-accounts-for-parent --parent-id $ROOT_ID --output json | jq -r '.Accounts[] | select((.JoinedMethod=="CREATED") and (.Status=="ACTIVE")) | .Id')
for ACCOUNT_ID in $ACCOUNTS; do
    echo "moving aws member account $ACCOUNT_ID from root OU to OU named $ORGANIZATIONAL_UNIT_NAME ..."
    aws organizations move-account --account-id $ACCOUNT_ID --source-parent-id $ROOT_ID --destination-parent-id $ORGANIZATIONAL_UNIT_ID
    echo "running resource setup for aws member account with Id: $ACCOUNT_ID"
    sh ./account.setup.sh $ACCOUNT_ID
done
echo "done."