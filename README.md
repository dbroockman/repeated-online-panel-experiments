# repeated-online-panel-experiments

This guide keeps a running list of the vendors, notes about them, and other tricks of the trade for running repeated online panel experiments.

# Vendors

## All-In-One Vendors

[Civiqs](https://www.civiqs.com/research) administers a one-stop shop.

## Particular Pieces

### Survey Platform

For academic work, we prefer Qualtircs. Qualtrics has a service called Blast Reward that sends out gift cards to respondents. Many universities don't subscribe to this feature so one must integrate with Tango manually (see below). However, Qualtrics can replace Tango in that case.

SurveyGizmo is a far cheaper alternative that may be preferable for practitioners. It is more difficult to program in our experience but workable.

### Tango Card - Incentives

Tango Card is a service that sends gift cards to respondents via an API. A POST request is issued to the Tango API and the respodent gets the gift card. There are no fees. However, one's Tango account must be loaded with funds in advance. We recommend university researchers begin this process far in advance, as onboarding Tango with one's university and then getting the university to transfer funds can both take weeks.

The Tango API accepts a POST request, but Qualtrics and SurveyGizmo are only capable of placing GET requests. A simple go-between is available [here](TBD) in this repository.

### Brite Verify - Email Verification

In our experience respondents often mistype their email addresses

![](https://raw.githubusercontent.com/dbroockman/repeated-online-panel-experiments/master/briteverify/in%20qualtrics%20setup.png)

http://briteverify.com

Set up as below: insert image here.

### Twilio - Text Messages

TKTK code.

### Google and Bing - Online Ads

TKTK screenshots.

### Recruitment Letters

TKTK.

# Creatives

## Recruitment Letters

TKTK.

## Website

Here's an example of a live website: http://stanfordopinions.org/.

## Survey Questions

Survey questions usually fall into one of four buckets.

- Outcome measures
- Things might predict opinion change useful for modeling
- Filler questions unrelated to politics
- Ancillary non-experimental outcomes of independent interest

# Data Cleaning Code

TKTK.

# Academic studies

## BK Science 2016
## BKS

# Other Resources

ROP power calc. Insert code for that?