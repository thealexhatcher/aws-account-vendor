#!/bin/bash
set -e 

ORGANIZATIONAL_UNIT_NAME=$1

ROOT_ID=$(aws organizations list-roots | jq -r .Roots[0].Id )
OU_LIST=$(aws organizations list-organizational-units-for-parent --parent-id $ROOT_ID)
ORGANIZATIONAL_UNIT_ARN=$(echo $OU_LIST | jq -r "select(.OrganizationalUnits[] | .Name == \"$ORGANIZATIONAL_UNIT_NAME\") | .OrganizationalUnits[].Arn")
ORGANIZATIONAL_UNIT_ID=$(echo $ORGANIZATIONAL_UNIT_ARN | cut -f 3 -d '/')
ACCOUNTS=$(aws organizations list-accounts-for-parent --parent-id $ORGANIZATIONAL_UNIT_ID)
for row in $(echo "${ACCOUNTS}" | jq -r '.Accounts[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }
    ACCOUNT_ID=$(_jq '.Id')
    echo "ACCOUNT_ID: $ACCOUNT_ID"
    sh ./account.nuke.sh $ACCOUNT_ID
done

##TODO:: Move all accounts to root

#echo "moving aws member account to root ou..."
#ROOT_ID=$(aws organizations list-roots | jq -r .Roots[0].Id )
#OU_LIST=$(aws organizations list-organizational-units-for-parent --parent-id $ROOT_ID)
#ORGANIZATIONAL_UNIT_ARN=$(echo $OU_LIST | jq -r "select(.OrganizationalUnits[] | .Name == \"$ORGANIZATIONAL_UNIT_NAME\") | .OrganizationalUnits[].Arn")
#ORGANIZATIONAL_UNIT_ID=$(echo $ORGANIZATIONAL_UNIT_ARN | cut -f 3 -d '/')
# Move AWS Member Accout to root OU
#aws organizations move-account --account-id $ACCOUNT_ID --source-parent-id $ORGANIZATIONAL_UNIT_ID --destination-parent-id $ROOT_ID
#echo "done."

#TODO:: Delete OU