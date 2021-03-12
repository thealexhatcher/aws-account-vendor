SHELL := /bin/bash

ACCOUNT_EMAIL?= "email@example.com"
ACCOUNT_NAME?= "11111111111111111111111111111111"
ORGANIZATIONAL_UNIT_NAME?= "guest"

account:
	aws organizations create-account --email $(ACCOUNT_EMAIL) --account-name $(ACCOUNT_NAME) --role-name OrganizationAccountAccessRole --iam-user-access-to-billing DENY --output json
org:
	aws organizations create-organization
ou-setup:
	./ou.setup.sh $(ORGANIZATIONAL_UNIT_NAME)
ou-nuke:
	./ou.nuke.sh $(ORGANIZATIONAL_UNIT_NAME)




