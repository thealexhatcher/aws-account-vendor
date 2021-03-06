SHELL := /bin/bash

ACCOUNT_ID?="111111111111"
ACCOUNT_EMAIL?= "email@example.com"
ACCOUNT_NAME?= "11111111111111111111111111111111"
ORGANIZATIONAL_UNIT_ID?= "ou-1111-11111111"

account-baseline: 
	./account.baseline.sh $(ACCOUNT_ID)
account:
	/account.setup.sh $(ACCOUNT_NAME) $(ACCOUNT_EMAIL) $(ORGANIZATIONAL_UNIT_ID)
account-baseline-all:

destroy:
	./account.nuke.sh $(ACCOUNT_ID)
destroy-all:
	./account.nuke.all.sh $(ORGANIZATIONAL_UNIT_ID)

