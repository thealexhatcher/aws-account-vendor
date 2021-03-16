# aws-account-vendor

## create new aws organization

make org 

## create new aws accounts

make account

single account create example:
example: make account ACCOUNT_EMAIL=alexhatcher@gmail.com ACCOUNT_NAME=alexhatcher

multiple unique account create example:
UUID=$(uuid | tr -d "-") && make account ACCOUNT_EMAIL=alexhatcher+$UUID@gmail.com ACCOUNT_NAME=$UUID

## setup ou with new aws accounts

make ou-setup

## remove resources from aws accounts

make ou-nuke


TODO: README