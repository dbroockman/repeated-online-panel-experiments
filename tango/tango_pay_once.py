import tango_create_order


# respondent_name, respondent_email, campaign_name, vendor, payout_amount_in_dollars

if __name__ == '__main__':
	print tango_create_order.CreateOrder('test', 'test@test.com', 'test', 'test', 5)
