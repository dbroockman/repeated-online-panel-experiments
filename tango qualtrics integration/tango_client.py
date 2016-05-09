from flask import Flask, jsonify, request
import json
import requests
from requests.auth import HTTPBasicAuth
import tango_credentials_prod as tango_credentials
import logging
import socket
from logging.handlers import SysLogHandler


# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

syslog = SysLogHandler(address=('logging handler address here', XXXXX))
formatter = logging.Formatter('%(asctime)s TANGOCLIENT: %(message)s', datefmt='%b %d %H:%M:%S')
syslog.setFormatter(formatter)
logger.addHandler(syslog)
logger.addHandler(logging.StreamHandler())


for cred in ['platformid', 'tangoapikey', 'customer', 'account_identifier', 'client_api_key']:
	assert getattr(tango_credentials, cred)


# Workhorse functions
vendor_sku_map = {
	# Supported Vendors
	'amazon': 'AMZN-E-V-STD',
	'starbucks': 'SBUX-E-V-STD',
	'walmart': 'WAL-E-V-STD',
	'itunes': 'APPL-E-{AMT}-STD',
	'depot': 'HMDP1-E-V-STD',
	# Charities
	'habitat': 'HABT-D-V-STD',
	'parks': 'NTPF-D-V-STD',
	'water': 'CNWR-D-V-STD'
}

def Pay(vendor, payout_amount_in_cents, respondent_name, respondent_email):
	assert payout_amount_in_cents >= 100, 'Payout amount under $1.'
	assert payout_amount_in_cents <= 2000, 'Payout amount over $20.'

	payload = {
	    "customer": tango_credentials.customer, # master account level thing
	    "account_identifier": tango_credentials.account_identifier, # bucket of money
	    "campaign": "emailtemplate1", # this is about the email template
	    "recipient": {
	        "name": respondent_name,
	        "email": respondent_email
	    },
	    "sku": vendor_sku_map[vendor],
	    "reward_from": "XXX",
	    "reward_subject": "XXX.",
	    "reward_message": "XXX",
	    "send_reward": True
	}

	if vendor == 'itunes':
		payload['sku'] = payload['sku'].replace('{AMT}', str(payout_amount_in_cents))
	else:
		payload['amount'] = payout_amount_in_cents

	if vendor in ['habitat', 'parks', 'water']:
		payload['reward_subject'] = 'Thanks for donating.'


	logging.info('Attempting to make payout request: %s' % str(payload))

	r = requests.post(tango_credentials.url_base + 'orders',
	             auth = HTTPBasicAuth(tango_credentials.platformid,
	             	tango_credentials.tangoapikey),
	             data = json.dumps(payload))

	logging.info('Tango API response: %s' % r.status_code)
	logging.info(r.text)

	return r.json()['success']



app = Flask(__name__)

@app.route('/pay_respondent', methods=['GET'])
def pay_respondent():
	success = False
	
	try:
		logging.info('Received request with info: ' + str(request.args))

		respondent_name = request.args.get('respondent_name')
		respondent_email = request.args.get('respondent_email')
		vendor = request.args.get('vendor')
		amount_in_dollars = request.args.get('amount_in_dollars')
		provided_key = request.args.get('key')

		if provided_key == tango_credentials.client_api_key:
			success = Pay(vendor, int(amount_in_dollars) * 100, respondent_name, respondent_email)
		else:
			logging.info('API key provided was %s not %s.' % (provided_key, tango_credentials.client_api_key))

	except Exception as e:
		logging.info('Failed because ' + str(e))
	finally:
		return json.dumps({'success': str(success)})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=True, threaded=True)
