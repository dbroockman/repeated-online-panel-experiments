"""These are functions you only need to run once to get the account set up."""

import json
import requests
from requests.auth import HTTPBasicAuth
import tango_cred_prod as tango_cred


def CreateCustomer():
	payload = {	'customerIdentifier': tango_cred.customer_id, 
				'displayName': tango_cred.customer_id}
	r = requests.post(tango_cred.base_url + 'customers',
						auth = HTTPBasicAuth(tango_cred.platform_name, tango_cred.tango_key),
						data = json.dumps(payload))
	print r.text


def ViewCustomers():
	print 'Attempting to view customers.'
	r = requests.get(tango_cred.base_url + 'customers',
						auth = HTTPBasicAuth(tango_cred.platform_name, tango_cred.tango_key))
	print r.text

# ViewCustomers()


def CreateAccount(account_id, contact_email, display_name):
	print 'Attempting to create account.'
	payload = {	"accountIdentifier": account_id,
				"contactEmail": contact_email,
				"displayName": display_name}
	r = requests.post(tango_cred.base_url + 'customers/' + tango_cred.customer_id + '/accounts',
						auth = HTTPBasicAuth(tango_cred.platform_name, tango_cred.tango_key),
						data = json.dumps(payload),
						headers = {'Content-Type': 'application/json'})
	print r.text

CreateAccount('xx', 'xx@xx.edu', 'xx')


def ViewAccounts():
	print 'Attempting to view accounts.'
	r = requests.get(tango_cred.base_url + 'accounts',
						auth = HTTPBasicAuth(tango_cred.platform_name, tango_cred.tango_key))
	print r.text

ViewAccounts()

def ViewCatalog():
	print 'Attempting to view catalog.'
	#Displays all customers on a platform - not really necessary in practice
	r = requests.get(	tango_cred.base_url + 'catalogs?verbose=false',
						auth = HTTPBasicAuth(tango_cred.platform_name, tango_cred.tango_key))
	print r.text

ViewCatalog()



