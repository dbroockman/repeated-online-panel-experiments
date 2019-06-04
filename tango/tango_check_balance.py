import json
import requests
from requests.auth import HTTPBasicAuth
import tango_cred_prod as tango_cred

for cred in ['platform_name', 'tango_key', 'customer_id']:
	assert getattr(tango_cred, cred)

account_ids = ['test1', 'test2', 'test3']

for account_id in account_ids:
	r = requests.get(	tango_cred.base_url + 'accounts/' + account_id,
						auth = HTTPBasicAuth(tango_cred.platform_name, tango_cred.tango_key))
	print r.json()