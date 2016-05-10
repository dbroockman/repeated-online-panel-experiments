import csv
import requests
import json
from twilio.rest import TwilioRestClient 

TWILIO_ACCOUNT_SID = "XXX"
TWILIO_AUTH_TOKEN = "XXX"
client = TwilioRestClient(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN) 

def SendInvite(name, spanish, to_phone, email, post_incentive):
	if spanish:
		body = ('Hola %s, Acabo de enviar su invitacion a la XXX a %s. '
			'Si usted tiene un minuto, le enviare otros $%s para completarlo. Gracias! - XXX' % (name, email, post_incentive))
	else:
		body = ('Hi %s, I just sent your invitation to XXX to %s. '
			'If you have a minute, I will send you another $%s for completing it. Thank you! - XXX' % (name, email, post_incentive))
	print 'Sending %s to %s' % (body, to_phone)
	response = client.messages.create(
		to=to_phone, 
		from_="+XXX", 
		body=body,  
	)
	print response


fname = 'XXX.csv'

print 'Reading from file %s' % fname

with open(fname, 'rbU') as csvfile:
	r = csv.DictReader(csvfile, delimiter=',')
	for row in r:
		try:
			SendInvite(row['name'],
				row['spanish'] == 'ES',
				row['phone'],
				row['enteredemail'],
				row['post_incentive'])
		except:
			print 'Failed on: '
			print row
