# aws-account-vending-machine



ACCOUNT_NAME=$(uuid | tr -d "-") \
ACCOUNT_EMAIL=alexhatcher+$ACCOUNT_NAME@gmail.com \
ORGANIZATIONAL_UNIT_ID=ou-vw2z-8xc77syq \
./account.member.setup.sh $ACCOUNT_NAME $ACCOUNT_EMAIL $ORGANIZATIONAL_UNIT_ID



#TODO: 
service control policy for OU
#TODO: 
README
