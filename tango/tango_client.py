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
	# Supported Vendors at #1
	'amazon': 'AMZN-E-V-STD',
	'target': 'TRGT-E-V-STD',
	# Supported Vendors at $5
	'starbucks': 'SBUX-E-V-STD',
	'walmart': 'WAL-E-V-STD',
	'itunes': 'APPL-E-{AMT}-STD',
	'depot': 'HMDP1-E-V-STD',
	'bestbuy': 'BSTB1-E-V-STD',
	'chipotle': 'CHIP-E-{AMT}-STD',
	'cvs': 'CVSP-E-V-STD',
	'dominos': 'DOMINOS1-E-V-STD',
	'ihop': 'IHOP1-E-V-STD',
	'tgif': 'TGIFRIDAYS1-E-V-STD',
	# Charities
	'habitat': 'HABT-D-V-STD',
	'parks': 'NTPF-D-V-STD',
	'water': 'CNWR-D-V-STD',
	# Tango card
	'tangocard': 'TNGO-E-V-STD'
}

campaigns = {
	'Campaign1': {
		'account_identifier': 'Campaign1',
		'reward_from': 'Stanford-Berkeley Opinion Survey',
		'reward_subject': 'Your Gift Card from Stanford and UC Berkeley is here.',
		'reward_message': 'Thank you for completing this wave of the Stanford-Berkeley Opinion Study!',
		'campaign': 'Campaign1'
	},
	'Campaign2': {
		'account_identifier': 'Campaign2',
		'reward_from': 'Stanford-Berkeley Opinion Survey',
		'reward_subject': 'Your Gift Card from Stanford and UC Berkeley is here.',
		'reward_message': 'Thank you for completing this wave of the Stanford-Berkeley Opinion Survey!',
		'campaign': 'Campaign2'
	}
}

def Pay(vendor, payout_amount_in_cents, respondent_name, respondent_email, campaign):
		assert campaign in campaigns.keys(), '%s is not a supported campaign.' % campaign
	assert vendor in vendor_sku_map.keys(), '%s is not a supported vendor.' % vendor
	assert payout_amount_in_cents > 0, 'Payout amount zero or less.'
	assert payout_amount_in_cents <= 2000, 'Payout amount over $20.'

	if vendor not in ['amazon', 'target', 'habitat', 'parks', 'water', 'tangocard']:
		assert payout_amount_in_cents >= 500, '%s does not allow payouts under $5.' % vendor

	payload = {
	    "customer": tango_credentials.customer, # master account level thing
	    "recipient": {
	        "name": respondent_name,
	        "email": respondent_email
	    },
	    "sku": vendor_sku_map[vendor],
	    "send_reward": True
	}

	for k, v in campaigns[campaign].iteritems():
		payload[k] = v

	if qturl:
		payload['reward_message'] = payload['reward_message'].replace('{qturl}', qturl)
	if post_incentive:
		payload['reward_message'] = payload['reward_message'].replace('{post_incentive}', post_incentive)

	if vendor in ['itunes', 'chipotle']:
		payload['sku'] = payload['sku'].replace('{AMT}', str(payout_amount_in_cents))
	else:
		payload['amount'] = payout_amount_in_cents

	if vendor in ['habitat', 'parks', 'water']:
		payload['reward_subject'] = 'Thank you for donating.'

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
		campaign = request.args.get('campaign')

		if provided_key == tango_credentials.client_api_key:
			success = Pay(vendor, int(amount_in_dollars) * 100, respondent_name, respondent_email, campaign)
		else:
			logging.info('API key provided was %s not %s.' % (provided_key, tango_credentials.client_api_key))

	except Exception as e:
		logging.info('Failed because ' + str(e))
	finally:
		return json.dumps({'success': str(success)})


if __name__ == '__main__':
	port = int(os.environ.get("PORT", 80))
    app.run(host='0.0.0.0', port=port, debug=True, threaded=True)
