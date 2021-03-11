#!/bin/bash
set -e 

ORGANIZATIONAL_UNIT_NAME=$1

ROOT_ID=$(aws organizations list-roots --output json | jq -r .Roots[0].Id )
ORGANIZATIONAL_UNIT=$(aws organizations create-organizational-unit --parent-id $ROOT_ID --name $ORGANIZATIONAL_UNIT_NAME --output json)
ORGANIZATIONAL_UNIT_ID=$(echo $ORGANIZATIONAL_UNIT | jq -r .OrganizationalUnit.Id )
POLICY=$(aws organizations create-policy --name $ORGANIZATIONAL_UNIT_NAME-service-control-policy --description "$ORGANIZATIONAL_UNIT_NAME Service Control Policy" --content file://ou.guest.create.scp.json --type SERVICE_CONTROL_POLICY --output json)
POLICY_ARN=$(echo $POLICY | jq -r .Policy.PolicySummary.Arn)
POLICY_ID=$(echo $POLICY_ARN | cut -f 4 -d '/')
aws organizations attach-policy --policy-id $POLICY_ID --target-id $ORGANIZATIONAL_UNIT_ID

echo "{\"ORGANIZATIONAL_UNIT_ID\":\"$ORGANIZATIONAL_UNIT_ID\",\"POLICY_ID\":\"$POLICY_ID\"}"
