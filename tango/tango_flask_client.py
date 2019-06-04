from flask import Flask, jsonify, request

import os

import logging
import json
import requests
from requests.auth import HTTPBasicAuth

import logging
import socket
from logging.handlers import SysLogHandler

# Set up logging
_logger = logging.getLogger()
_logger.setLevel(logging.INFO)

syslog = SysLogHandler()
formatter = logging.Formatter('%(asctime)s TANGOFLASKCLIENT: %(message)s', datefmt='%b %d %H:%M:%S')
syslog.setFormatter(formatter)
_logger.addHandler(syslog)
_logger.addHandler(logging.StreamHandler())


import tango_create_order


app = Flask(__name__)


@app.route('/pay_respondent', methods=['GET'])
def pay_respondent():
	success = False
	respondent_name = request.args.get('respondent_name')

	try:
		logging.info('Received request with info: ' + str(request.args))

		respondent_name = request.args.get('respondent_name')
		respondent_email = request.args.get('respondent_email')
		campaign_name = request.args.get('campaign')
		vendor = request.args.get('vendor')
		payout_amount_in_dollars = request.args.get('amount_in_dollars')
		client_api_key = request.args.get('key')

		if respondent_name == '':
			respondent_name = 'Friend'

		if client_api_key == tango_create_order.tango_cred.client_api_key:
			success = tango_create_order.CreateOrder(respondent_name, respondent_email, campaign_name, vendor, payout_amount_in_dollars)
		else:
			logging.info('Client key provided was %s not %s.' % (provided_key, tango_cred.client_api_key))

	except Exception as e:
		logging.info('Failed because ' + str(e))
	finally:
		return json.dumps({'success': str(success)})


if __name__ == '__main__':
	port = int(os.environ.get("PORT", 80))
	app.run(host='0.0.0.0', port=port, debug=True, threaded=True)
