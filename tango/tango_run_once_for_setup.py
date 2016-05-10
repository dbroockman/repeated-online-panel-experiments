"""These are functions you only need to run once to get the account set up."""

import json
import requests
from requests.auth import HTTPBasicAuth
import tango_credentials_sandbox as tango_credentials

def CreateAccount():
	"""Function I ran once to create a customer."""
	payload = {'customer': 'XXX', 'identifier': 'XXX', 'email': 'XXX'}
	r = requests.post('https://api.tangocard.com/raas/v1.1/accounts',
	             auth=HTTPBasicAuth(tango_credentials.platformid, tango_credentials.key), data = json.dumps(payload))
	print r.text

def RegisterCC():
	payload = {
		    "customer": "XXXX",
		    "account_identifier": "XXXX",
		    "client_ip": "127.0.0.1",
		    "credit_card": {
		            "number": "4111111111111111",
		            "security_code": "123",
		            "expiration": "2016-01",
		            "billing_address": {
		                "f_name": "FName",
		                "l_name": "LName",
		                "address": "Address",
		                "city": "XXXX",
		                "state": "XX",
		                "zip": "XXXXX",
		                "country": "USA",
		                "email": "test@example.com"
		            }
		    }
		}
	r = requests.post('https://sandbox.tangocard.com/raas/v1.1/cc_register',
	             auth=HTTPBasicAuth(platformid, key), data = json.dumps(payload))
	print r.text


def FundAccount():
	payload = {
	    "customer": "XXX",
	    "account_identifier": "TestAccount",
	    "amount": 50,
	    "client_ip": "127.0.0.1",
	    "cc_token": "XXXXX",
	    "security_code": "XXX"
	}
	r = requests.post('https://sandbox.tangocard.com/raas/v1.1/cc_fund',
	             auth=HTTPBasicAuth(tango_credentials.platformid, tango_credentials.tangoapikey),
	             data = json.dumps(payload))
	print r.text