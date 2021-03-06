#!/bin/bash
set -e 

ORGANIZATIONAL_UNIT_ID=$1

ACCOUNTS=$(aws organizations list-accounts-for-parent --parent-id $ORGANIZATIONAL_UNIT_ID)
for row in $(echo "${ACCOUNTS}" | jq -r '.Accounts[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }
    ACCOUNT_ID=$(_jq '.Id')
    echo "ACCOUNT_ID: $ACCOUNT_ID"
    sh ./account.nuke.sh $ACCOUNT_ID
done




