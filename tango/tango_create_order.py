import logging
import json
import requests
from requests.auth import HTTPBasicAuth

import tango_cred_prod as tango_cred
for cred in ['platform_name', 'tango_key', 'customer_id', 'client_api_key']:
	assert getattr(tango_cred, cred)

import logging
import socket
from logging.handlers import SysLogHandler

# Set up logging
_logger = logging.getLogger()
_logger.setLevel(logging.INFO)

syslog = SysLogHandler()
formatter = logging.Formatter('%(asctime)s TANGOORDERMAKER: %(message)s', datefmt='%b %d %H:%M:%S')
syslog.setFormatter(formatter)


_vendor_utid_map = {
	'amazon': 'U666425',
	'itunes5': 'U689567',
	'starbucks': 'U761382',
	'walmart': 'U640032',
	'depot': 'U231646',
	'habitat': 'U866942',
	'parks': 'U178631',
	'water': 'U160469'
}

_donation_utids = ['habitat', 'parks', 'water']


_campaigns = {
	'test': {
		'account_id': 'testaccount',
		'message': 'Thanks for taking the survey.',
		'tango_campaign_name': 'test',
		'firstName': 'Test'
	}
}


def CreateOrder(respondent_name, respondent_email, campaign_name, vendor, payout_amount_in_dollars):
	assert campaign_name in _campaigns, 'Campaign not found.'
	campaign = _campaigns[campaign_name]

	assert vendor in _vendor_utid_map, 'Vendor not found.'

	if vendor in _donation_utids:
		item_description = 'Donation'
	else:
		item_description = 'Gift card'

	payload = {	"accountIdentifier": campaign['account_id'],
				"amount": payout_amount_in_dollars,
				"campaign": campaign['tango_campaign_name'],
				"customerIdentifier": tango_cred.customer_id,
				"emailSubject": "Your $%s %s" % (str(payout_amount_in_dollars), item_description),
				"message": "Thanks for taking the survey.",
				"recipient": {
					"email": respondent_email,
					"firstName": respondent_name},
				"sender": {
				    "email": "XX@XX.XX",
				    "firstName": campaign['firstName'],
				    "lastName": ""
				},
				"sendEmail": "true",
				"utid": _vendor_utid_map[vendor]}

	logging.info('Attempting to make payout request: %s' % str(payload))
	r = requests.post(tango_cred.base_url + 'orders',
						auth = HTTPBasicAuth(tango_cred.platform_name, tango_cred.tango_key),
						data = json.dumps(payload),
						headers = {'Content-Type': 'application/json'})
	logging.info('Tango API response: %s' % r.status_code)
	logging.info(r.text)
	return r.status_code == 201


if __name__ == '__main__':
	print CreateOrder('Test Person', 'XX@XX.com', 'test', 'starbucks', 5)
