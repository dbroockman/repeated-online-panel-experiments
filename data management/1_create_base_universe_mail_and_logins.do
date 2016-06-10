insheet data.csv, comma clear

set seed 583313
set sortseed 951193

local ctd = subinstr(c(current_date)," ","_",.) + "_" + subinstr(c(current_time),":","_",.)

// Zip codes as strings for mail
destring mzip5 mzip4, replace
gen mzip5s = string(mzip5,"%05.0f")
gen mzip4s = string(mzip4,"%04.0f")
drop mzip5 mzip4
rename mzip5s mzip5
rename mzip4s mzip4
replace mzip4 = trim(mzip4)
replace mzip4 = "" if mzip4 == "."
replace mzip4 = "" if mzip4 == "0000"

// Voter turnout binary flags.
foreach var of varlist general15 - special00 mayoral11 - recall11{
	replace `var' = "1" if `var' != ""
	replace `var' = "0" if `var' == ""
	destring `var', replace
}

//Seed Yourself
local new = _N + 1
set obs `new'
local josh = `new'
*
replace firstname = "Josh" if _n==`josh'
replace lastname = "Kalla" if _n==`josh'
replace maddress = "123 Fake Street" if _n==`josh'
replace mcity = "Berkeley" if _n==`josh'
replace mstate = "CA" if _n==`josh'
replace mzip5 = "94705" if _n==`josh'
replace id = "-10" if _n==`josh'
*


***** Household-level cleaning. *****
egen hh_id = group(maddress mcity mstate mzip5)

drop if mzip5 == "00000"
drop if maddress == ""

// Some people missing zip4s their householders have. Messes up reshape below.
preserve
keep hh_id mzip4
drop if mzip4 == ""
duplicates drop hh_id, force
tempfile z4s
save `z4s'
restore
merge m:1 hh_id using `z4s', nogen update replace

//Drop households with duplicate first names within households. These may be
//duplicate people and will cause canvasser confusion anyway.
duplicates t hh_id firstname, gen(dupe)
drop if dupe > 0
drop dupe


//Fix up names
foreach namevar in firstname lastname{
	replace `namevar' = trim(`namevar')
	replace `namevar' = subinstr(`namevar',"  "," ",.)
	replace `namevar' = "" if `namevar' == " "
}
replace middlename = middlename + "." if strlen(middlename) == 1

foreach var in firstname middlename lastname mcity {
	replace `var' = proper(`var')
}



//Drop likely duplicate voter records
gen namestart = substr(firstname, 1, 3)
duplicates drop hh_id namestart age, force
drop namestart


// Randomly drop people 5-N in hhs of 5 or more.
gen random = runiform()
sort hh_id random
bysort hh_id: egen hh_seq=seq()
bysort hh_id: egen hh_size_total=max(hh_seq) // Record how large the HH was for weighting later.
drop if hh_seq >= 5
drop hh_seq random



// Record hh size
bysort hh_id: egen hh_seq=seq()
bysort hh_id: egen hh_size_sample=max(hh_seq)
tab hh_size_sample
drop hh_seq



** RANDOM ASSIGNMENT TO INCENTIVES **
preserve
collapse hh_size_sample, by(hh_id)

//Random assignment of households for post-incentive:
//$5 - 70%
//$10 - 30%
set seed 7435334
gen rand=runiform()
sort hh_size_sample rand
egen post_incentive = seq(), from(1) to (10)
recode post_incentive (1/7=5) (8/10=10)
tab post_incentive, mis
drop rand


//Merge back in household-level randomizations into individual-level data
drop hh_size
tempfile incentive
save `incentive'
restore
merge m:1 hh_id using `incentive', nogen

unique hh_id

// Create logins.
set seed 67354484
set sortseed 9724126
gen loginstem = strtrim(subinstr(lower(firstname), " ", "", .))
replace loginstem = strtrim(subinstr(lower(lastname), " ", "", .)) if missing(loginstem)
gen login = loginstem + word(maddress,1)

duplicates t login, gen(ldupe)
tab ldupe

replace login = loginstem + lower(substr(lastname, 1, 1)) + string(_n + 1111) if ldupe > 0

replace login = subinstr(login,"-","",.) //remove dashes

isid login // Make sure there are no duplicate logins.
drop loginstem ldupe

// Save base universe with usernames.
compress
save "baseline_universe`ctd'.dta", replace


****** QUALTRICS AND MAIL VENDOR DATA ******

//Export file to upload to qualtrics with both capitalized and non-capitalized first letters
preserve
	keep id firstname lastname mcity post_incentive login hh_id
	expand 2, gen(expand_num) //Double the observations
	replace login = proper(login) if expand_num == 1 //capitalize the first letter
	sort hh_id
	outsheet id firstname lastname mcity ///
		post_incentive login ///
		using qualtrics_upload`ctd'.csv, comma replace
restore


//Prepare file for mail
drop hh_size*
bysort hh_id: egen hh_seq = seq()
bysort hh_id: egen hh_size_mail = max(hh_seq)
keep id firstname middlename lastname suffix login maddress - mstate mzip5 mzip4 ///
	hh_id - hh_size_mail post_incentive

	
//Reshape to letter level.
reshape wide firstname middlename lastname suffix login id, i(hh_id) j(hh_seq)


//Envelope to line
gen nameline = firstname1 + " " + lastname1 + " " + suffix1 if hh_size == 1

replace nameline = firstname1 + ///
				" and " + firstname2 + " " + lastname2 ///
				if hh_size == 2 & lastname2 == lastname1
replace nameline = firstname1 + " " + lastname1 + " " + suffix1 + ///
				" and " + firstname2 + " " + lastname2 + " " + suffix2 ///
				if hh_size == 2 & lastname2 != lastname1

replace nameline = firstname1 + ///
				", " + firstname2 +  ///
				", and " + firstname3 + " " + lastname3 ///
				if hh_size == 3 & lastname2 == lastname1 & lastname2 == lastname3
replace nameline = firstname1 + " " + lastname1 + " " + suffix1 + ///
				", " + firstname2 + " " + lastname2 + " " + suffix2 + ///
				", and " + firstname3 + " " + lastname3 + " " + suffix3 ///
				if hh_size == 3 & (lastname2 != lastname1 | lastname1 != lastname3 | lastname2 != lastname3)
				
replace nameline = firstname1 + ///
				", " + firstname2 +  ///
				", " + firstname3 + ///
				", and " + firstname4 + " " + lastname4 ///
				if hh_size == 4 & lastname2 == lastname1 & lastname2 == lastname3 & lastname3 == lastname4
replace nameline = firstname1 + " " + lastname1 + " " + suffix1 + ///
				", " + firstname2 + " " + lastname2 + " " + suffix2 + ///
				", " + firstname3 + " " + lastname3 + " " + suffix3 + ///
				", and " + firstname4 + " " + lastname4 + " " + suffix4 ///
				if hh_size == 4 & !(lastname2 == lastname1 & lastname2 == lastname3 & lastname3 == lastname4)

replace nameline = firstname1 + " " + lastname1 + " and family" if length(nameline) > 50
				
replace nameline = subinstr(nameline,"  "," ",.)
replace nameline = subinstr(nameline,"  "," ",.)
replace nameline = subinstr(nameline," ,",",",.)
replace nameline = trim(nameline)
replace nameline = proper(nameline)
replace nameline = subinstr(nameline, " And ", " and ",.)
replace nameline = subinstr(nameline,"Iii","III",.)
replace nameline = subinstr(nameline,"Ii","II",.)

//Dear: line
gen in_sal = firstname1 if hh_size == 1
replace in_sal = firstname1 + " and " + firstname2 if hh_size == 2
replace in_sal = firstname1 + ", " + firstname2 + ", and " + firstname3 if hh_size == 3
replace in_sal = firstname1 + ", " + firstname2 + ", " + firstname3 + ", and " + firstname4 if hh_size == 4
replace in_sal = firstname1 + " and family" if length(in_sal) > 60

forvalues person=1/4{
	replace firstname`person' = "For: " + firstname`person' if !missing(firstname`person')
	replace login`person' = "Login: " + login`person' if !missing(login`person')
}

gen mzip4_addrline = ""
replace mzip4_addrline = "-" + mzip4 if mzip4 != ""

local keepvars = "hh_id maddress mcity mstate mzip5 mzip4_addrline nameline in_sal mstate post_incentive firstname1 login1 firstname2 login2 firstname3 login3 firstname4 login4"
keep `keepvars'
order `keepvars'

sort mzip5 mzip4 hh_id

outsheet using mail_vendor_merge_file_`ctd'.csv, comma replace
