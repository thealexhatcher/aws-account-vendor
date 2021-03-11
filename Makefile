SHELL := /bin/bash

ACCOUNT_ID?= "111111111111"
ACCOUNT_EMAIL?= "email@example.com"
ACCOUNT_NAME?= "11111111111111111111111111111111"
ORGANIZATIONAL_UNIT_NAME?= "guest"

org:
	aws organizations create-organization

ou-setup:
	./ou.setup.sh $(ORGANIZATIONAL_UNIT_NAME)
ou-nuke:
	./ou.nuke.sh $(ORGANIZATIONAL_UNIT_NAME)

account:
	./account.create.sh $(ACCOUNT_NAME) $(ACCOUNT_EMAIL)
account-setup:
	./account.setup.sh $(ACCOUNT_ID) $(ORGANIZATIONAL_UNIT_NAME)
account-nuke:
	./account.nuke.sh $(ACCOUNT_ID) $(ORGANIZATIONAL_UNIT_NAME)
