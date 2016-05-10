# repeated-online-panel-experiments

This guide keeps a running list of the vendors, notes about them, and other practices for running repeated online panel experiments. [Testing Theories of Attitude Change With Online Panel Field Experiments](http://papers.ssrn.com/sol3/papers.cfm?abstract_id=2742869) describes the design and an application study. This repository assumes knowledge of that paper.

# Vendors

## All-In-One Vendors

[Civiqs](https://www.civiqs.com/research) administers a one-stop shop.

## Particular Pieces

### Survey Platform

For academic work, we prefer [Qualtircs](https://www.qualtrics.com). Most universities have a subscription.

[SurveyGizmo](https://www.surveygizmo.com) is a far cheaper alternative that may be preferable for practitioners. It is more difficult to program in our experience but workable.

### Tango Card - Incentives

Tango Card is a service that sends gift cards to respondents via email. A POST request is issued to the Tango API and the respodent gets the gift card. There are no fees. However, one's Tango account must be loaded with funds in advance. We recommend university researchers begin this process far in advance, as onboarding Tango with one's university and then getting the university to transfer funds can both take weeks.

The Tango API accepts a POST request, but Qualtrics and SurveyGizmo are only capable of placing GET requests. A simple go-between is available [here](https://github.com/dbroockman/repeated-online-panel-experiments/tree/master/tango%20qualtrics%20integration) in this repository. We set up a server that runs this go-between microservice.

Qualtrics does have a service called [Blast Rewards](https://www.qualtrics.com/innovation-exchange/tango-card/) that sends out gift cards to respondents using Tango. We are not familiar with how this works, but it may be easier than using the go-between.

### Brite Verify - Email Verification

We ask respondents for their email addresses and ask them to complete follow up surveys with solicitations sent to these email addresses. In our experience respondents often mistype their email addresses in the survey. We need them to correct these typos so that we can get a valid email. To detect these typos, we use the [BriteVerify](http://briteverify.com) API. It can be integrated directly into Qualtrics. An example is available [here](https://github.com/dbroockman/repeated-online-panel-experiments/tree/master/briteverify) in this repository.

### Twilio - Text Messages

We have sometimes given respondents the option of being texted when a follow-up survey is available. If they give their cell number and asked to be texted, we use a script available [here](https://github.com/dbroockman/repeated-online-panel-experiments/blob/master/twilio/invite_to_post_with_sms.py) to send text message with [Twilio](https://www.twilio.com).

### Google and Bing - Online Ads

Many respondents Google the name of the survey or Google the URL but do not enter the URL into their browser bars. Buying ads on Google and Bing allows one to redirect respondents to the survey. In our experience over 10% of respondents enter the survey via this mechanism.

### Mail firm

We prefer [Snap Pack Mail](http://snappackmail.com).

# Creatives

## Recruitment Letters

An example recruitment letter is available [here](https://github.com/dbroockman/repeated-online-panel-experiments/tree/master/recruitment%20letters). There are also [specs](https://github.com/dbroockman/repeated-online-panel-experiments/blob/master/recruitment%20letters/specs.txt) to give mail firms for cheaper rates.

## Website

Here's an example of a live website: http://stanfordopinions.org/.

## Survey Questions

Survey questions usually fall into one of four buckets.

- Outcome measures
- Things might predict opinion change useful for modeling
- Filler questions unrelated to politics
- Ancillary non-experimental outcomes of independent interest

## Re-Survey Solicitation Emails

We ask respondents for their email addresses and ask them to complete follow up surveys with solicitations sent to these email addresses. Examples of these solicitaitons are available [here](https://github.com/dbroockman/repeated-online-panel-experiments/tree/master/qualtrics%20examples).

# Other Resources

## Academic studies

- [Testing Theories of Attitude Change With Online Panel Field Experiments](http://papers.ssrn.com/sol3/papers.cfm?abstract_id=2742869) describes the design and an application study. This repository assumes knowledge of that paper.
- [Durably reducing transphobia](http://stanford.edu/~dbroock/published%20paper%20PDFs/broockman_kalla_transphobia_canvassing_experiment.pdf) was the first published experiment using the design.

## Power Calculator

The power calculator available [here](http://experiments.berkeley.edu) allows one to . We plan to open source the code for that webpage here soon.
