import json
import requests
from requests.auth import HTTPBasicAuth
import tango_credentials_prod as tango_credentials


for cred in ['platformid', 'tangoapikey', 'customer', 'account_identifier', 'client_api_key']:
	assert getattr(tango_credentials, cred)


r = requests.get(tango_credentials.url_base + 'accounts/%s/%s' % (tango_credentials.customer,tango_credentials.account_identifier),
             auth = HTTPBasicAuth(tango_credentials.platformid,
             	tango_credentials.tangoapikey))

print 'Tango API response: %s' % r.status_code
print r.text
print r.json()['account']['available_balance'] / 100