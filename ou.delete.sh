#!/bin/bash
set -e 

ORGANIZATIONAL_UNIT_NAME=$1

ROOT_ID=$(aws organizations list-roots --output json | jq -r .Roots[0].Id )
OU_LIST=$(aws organizations list-organizational-units-for-parent --parent-id $ROOT_ID --output json)
ORGANIZATIONAL_UNIT_ARN=$(echo $OU_LIST | jq -r '.OrganizationalUnits[] | select(.Name=="'$ORGANIZATIONAL_UNIT_NAME'") | .Arn')
echo $ORGANIZATIONAL_UNIT_ARN
ORGANIZATIONAL_UNIT_ID=$(echo $ORGANIZATIONAL_UNIT_ARN | cut -f 3 -d '/')
echo $ORGANIZATIONAL_UNIT_ID
OU_POLICIES=$(aws organizations list-policies-for-target --filter SERVICE_CONTROL_POLICY --target-id $ORGANIZATIONAL_UNIT_ID --output json)
echo $OU_POLICIES
POLICY_ID=$(echo $OU_POLICIES | jq -r '.Policies[] | select( .Name=="'$ORGANIZATIONAL_UNIT_NAME'-service-control-policy") | .Id')
echo $POLICY_ID

aws organizations detach-policy --policy-id $POLICY_ID --target-id $ORGANIZATIONAL_UNIT_ID --output json
aws organizations delete-policy --policy-id $POLICY_ID --output json
aws organizations delete-organizational-unit --organizational-unit-id $ORGANIZATIONAL_UNIT_ID --output json
