* import_covid_self_reporting_form.do
*
* 	Imports and aggregates "COVID Self Reporting Form" (ID: covid_self_reporting_form) data.
*
*	Inputs:  "COVID Self Reporting Form.csv"
*	Outputs: "COVID Self Reporting Form.dta"
*
*	Output by SurveyCTO October 11, 2023 8:32 AM.

* initialize Stata
clear all
set more off
set mem 100m

* initialize workflow-specific parameters
*	Set overwrite_old_data to 1 if you use the review and correction
*	workflow and allow un-approving of submissions. If you do this,
*	incoming data will overwrite old data, so you won't want to make
*	changes to data in your local .dta file (such changes can be
*	overwritten with each new import).
local overwrite_old_data 0

* initialize form-specific parameters
local csvfile "COVID Self Reporting Form.csv"
local dtafile "COVID Self Reporting Form.dta"
local corrfile "COVID Self Reporting Form_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid country enum_id enum enum_project high_temp sym_cnt bangladesh bolivia burkina_faso colombia dominican_republic cote_d_ivoire ghana"
local text_fields2 "kenya liberia malawi mali mexico myanmar paraguay peru philippines rwanda sierra_leone tanzania uganda united_states zambia instanceid"
local date_fields1 ""
local datetime_fields1 "submissiondate starttime endtime"

disp
disp "Starting import of: `csvfile'"
disp

* import data from primary .csv file
insheet using "`csvfile'", names clear

* drop extra table-list columns
cap drop reserved_name_for_field_*
cap drop generated_table_list_lab*

* continue only if there's at least one row of data to import
if _N>0 {
	* drop note fields (since they don't contain any real data)
	forvalues i = 1/100 {
		if "`note_fields`i''" ~= "" {
			drop `note_fields`i''
		}
	}
	
	* format date and date/time fields
	forvalues i = 1/100 {
		if "`datetime_fields`i''" ~= "" {
			foreach dtvarlist in `datetime_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=clock(`tempdtvar',"DMYhms",2025)
						* automatically try without seconds, just in case
						cap replace `dtvar'=clock(`tempdtvar',"DMYhm",2025) if `dtvar'==. & `tempdtvar'~=""
						format %tc `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
		if "`date_fields`i''" ~= "" {
			foreach dtvarlist in `date_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=date(`tempdtvar',"DMY",2025)
						format %td `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
	}

	* ensure that text fields are always imported as strings (with "" for missing values)
	* (note that we treat "calculate" fields as text; you can destring later if you wish)
	tempvar ismissingvar
	quietly: gen `ismissingvar'=.
	forvalues i = 1/100 {
		if "`text_fields`i''" ~= "" {
			foreach svarlist in `text_fields`i'' {
				cap unab svarlist : `svarlist'
				if _rc==0 {
					foreach stringvar in `svarlist' {
						quietly: replace `ismissingvar'=.
						quietly: cap replace `ismissingvar'=1 if `stringvar'==.
						cap tostring `stringvar', format(%100.0g) replace
						cap replace `stringvar'="" if `ismissingvar'==1
					}
				}
			}
		}
	}
	quietly: drop `ismissingvar'


	* consolidate unique ID into "key" variable
	replace key=instanceid if key==""
	drop instanceid


	* label variables
	label variable key "Unique submission ID"
	cap label variable submissiondate "Date/time submitted"
	cap label variable formdef_version "Form version used on device"
	cap label variable review_status "Review status"
	cap label variable review_comments "Comments made during review"
	cap label variable review_corrections "Corrections made during review"


	label variable enum_id "Please enter your ID"
	note enum_id: "Please enter your ID"

	label variable conf "Is the information above accurate?"
	note conf: "Is the information above accurate?"
	label define conf 1 "Yes" 0 "No"
	label values conf conf

	label variable rt "Is this a Check-in or Check-out?"
	note rt: "Is this a Check-in or Check-out?"
	label define rt 1 "Check-in" 2 "Check-out"
	label values rt rt

	label variable pt1 "PT1 Did you use any public means of transportation today?"
	note pt1: "PT1 Did you use any public means of transportation today?"
	label define pt1 1 "Yes" 0 "No"
	label values pt1 pt1

	label variable tmp_pt2_0 ""
	note tmp_pt2_0: ""
	label define tmp_pt2_0 1 "Yes" 0 "No"
	label values tmp_pt2_0 tmp_pt2_0

	label variable pt2a "PT2A As transportation to the field"
	note pt2a: "PT2A As transportation to the field"
	label define pt2a 1 "Yes" 0 "No"
	label values pt2a pt2a

	label variable pt2b "PT2B As transportation from the field"
	note pt2b: "PT2B As transportation from the field"
	label define pt2b 1 "Yes" 0 "No"
	label values pt2b pt2b

	label variable pt2c "PT2C As transportation while on field"
	note pt2c: "PT2C As transportation while on field"
	label define pt2c 1 "Yes" 0 "No"
	label values pt2c pt2c

	label variable pt3 "PT3 Was social distancing observed while you where using public transport?"
	note pt3: "PT3 Was social distancing observed while you where using public transport?"
	label define pt3 1 "Yes" 0 "No"
	label values pt3 pt3

	label variable pt4 "PT4 Where all passengers in public transportation wearing face mask/covering?"
	note pt4: "PT4 Where all passengers in public transportation wearing face mask/covering?"
	label define pt4 1 "Yes" 0 "No"
	label values pt4 pt4

	label variable pt5 "PT5 Did you wash or sanitize your hands after riding in public transport?"
	note pt5: "PT5 Did you wash or sanitize your hands after riding in public transport?"
	label define pt5 1 "Yes" 0 "No"
	label values pt5 pt5

	label variable sc1 "SC1 Has your temperature been recorded?"
	note sc1: "SC1 Has your temperature been recorded?"
	label define sc1 1 "Yes" 0 "No"
	label values sc1 sc1

	label variable sc2 "SC2 What was your temperature (Celsius)?"
	note sc2: "SC2 What was your temperature (Celsius)?"

	label variable tmp_sc3_lab ""
	note tmp_sc3_lab: ""
	label define tmp_sc3_lab 1 "Yes" 0 "No"
	label values tmp_sc3_lab tmp_sc3_lab

	label variable sc3a "SC3A Cough"
	note sc3a: "SC3A Cough"
	label define sc3a 1 "Yes" 0 "No"
	label values sc3a sc3a

	label variable sc3b "SC3B Fever or chills"
	note sc3b: "SC3B Fever or chills"
	label define sc3b 1 "Yes" 0 "No"
	label values sc3b sc3b

	label variable sc3c "SC3C Shortness of breath or difficulty breathing"
	note sc3c: "SC3C Shortness of breath or difficulty breathing"
	label define sc3c 1 "Yes" 0 "No"
	label values sc3c sc3c

	label variable sc3d "SC3D Muscle or body aches"
	note sc3d: "SC3D Muscle or body aches"
	label define sc3d 1 "Yes" 0 "No"
	label values sc3d sc3d

	label variable sc3e "SC3E Sore throat"
	note sc3e: "SC3E Sore throat"
	label define sc3e 1 "Yes" 0 "No"
	label values sc3e sc3e

	label variable sc3f "SC3F New loss of taste or smell"
	note sc3f: "SC3F New loss of taste or smell"
	label define sc3f 1 "Yes" 0 "No"
	label values sc3f sc3f

	label variable sc3g "SC3G Diarrhea"
	note sc3g: "SC3G Diarrhea"
	label define sc3g 1 "Yes" 0 "No"
	label values sc3g sc3g

	label variable sc3h "SC3H Headache"
	note sc3h: "SC3H Headache"
	label define sc3h 1 "Yes" 0 "No"
	label values sc3h sc3h

	label variable sc3i "SC3I Nausea or vomiting"
	note sc3i: "SC3I Nausea or vomiting"
	label define sc3i 1 "Yes" 0 "No"
	label values sc3i sc3i

	label variable sc3j "SC3J New fatigue"
	note sc3j: "SC3J New fatigue"
	label define sc3j 1 "Yes" 0 "No"
	label values sc3j sc3j

	label variable sc3k "SC3K Congestion or runny nose"
	note sc3k: "SC3K Congestion or runny nose"
	label define sc3k 1 "Yes" 0 "No"
	label values sc3k sc3k

	label variable sc4 "SC4 During the last 14 days (today included), have you had close contact with so"
	note sc4: "SC4 During the last 14 days (today included), have you had close contact with someone diagnosed with COVID-19 or been notified that you may have been exposed to it?"
	label define sc4 1 "Yes" 0 "No"
	label values sc4 sc4

	label variable tmp_lg_lab ""
	note tmp_lg_lab: ""
	label define tmp_lg_lab 1 "Sufficient" 2 "Not Sufficient" 0 "No"
	label values tmp_lg_lab tmp_lg_lab

	label variable lg1 "LG1 Facemask/Face Covering"
	note lg1: "LG1 Facemask/Face Covering"
	label define lg1 1 "Sufficient" 2 "Not Sufficient" 0 "No"
	label values lg1 lg1

	label variable lg2 "LG2 Hand Sanitizer"
	note lg2: "LG2 Hand Sanitizer"
	label define lg2 1 "Sufficient" 2 "Not Sufficient" 0 "No"
	label values lg2 lg2

	label variable lg3 "LG3 Disinfectant"
	note lg3: "LG3 Disinfectant"
	label define lg3 1 "Sufficient" 2 "Not Sufficient" 0 "No"
	label values lg3 lg3

	label variable lg4 "LG4 Disposable Hand Gloves"
	note lg4: "LG4 Disposable Hand Gloves"
	label define lg4 1 "Sufficient" 2 "Not Sufficient" 0 "No"
	label values lg4 lg4

	label variable lg5 "LG5 COVID-19 information leaflets"
	note lg5: "LG5 COVID-19 information leaflets"
	label define lg5 1 "Sufficient" 2 "Not Sufficient" 0 "No"
	label values lg5 lg5

	label variable tc1 "TC1 How many members were in your team today? (This includes the Team Leader)"
	note tc1: "TC1 How many members were in your team today? (This includes the Team Leader)"

	label variable tc2 "TC2 Did your team hold an in-person team meeting today?"
	note tc2: "TC2 Did your team hold an in-person team meeting today?"
	label define tc2 1 "Yes" 0 "No"
	label values tc2 tc2

	label variable ct1 "CT1 During field activities today, have you been in close contact with anyone wh"
	note ct1: "CT1 During field activities today, have you been in close contact with anyone who wasn't a respondent or a team member? Close contact is defined as any individual who was within 6 feet of another person for at least 15 minutes."
	label define ct1 1 "Yes" 0 "No"
	label values ct1 ct1

	label variable sym_check_yn "Do you have the neccesary permission to proceed to the field?"
	note sym_check_yn: "Do you have the neccesary permission to proceed to the field?"
	label define sym_check_yn 1 "Yes" 0 "No"
	label values sym_check_yn sym_check_yn






	/* append old, previously-imported data (if any)
	cap confirm file "`dtafile'"
	if _rc == 0 {
		* mark all new data before merging with old data
		gen new_data_row=1
		
		* pull in old data
		append using "`dtafile'"
		
		* drop duplicates in favor of old, previously-imported data if overwrite_old_data is 0
		* (alternatively drop in favor of new data if overwrite_old_data is 1)
		sort key
		by key: gen num_for_key = _N
		drop if num_for_key > 1 & ((`overwrite_old_data' == 0 & new_data_row == 1) | (`overwrite_old_data' == 1 & new_data_row ~= 1))
		drop num_for_key

		* drop new-data flag
		drop new_data_row
	}
	*/
	
	* save data to Stata format
	save "`dtafile'", replace

	* show codebook and notes
	* codebook
	* notes list
}

disp
disp "Finished import of: `csvfile'"
disp

* OPTIONAL: LOCALLY-APPLIED STATA CORRECTIONS
*
* Rather than using SurveyCTO's review and correction workflow, the code below can apply a list of corrections
* listed in a local .csv file. Feel free to use, ignore, or delete this code.
*
*   Corrections file path and filename:  COVID Self Reporting Form_corrections.csv
*
*   Corrections file columns (in order): key, fieldname, value, notes

capture confirm file "`corrfile'"
if _rc==0 {
	disp
	disp "Starting application of corrections in: `corrfile'"
	disp

	* save primary data in memory
	preserve

	* load corrections
	insheet using "`corrfile'", names clear
	
	if _N>0 {
		* number all rows (with +1 offset so that it matches row numbers in Excel)
		gen rownum=_n+1
		
		* drop notes field (for information only)
		drop notes
		
		* make sure that all values are in string format to start
		gen origvalue=value
		tostring value, format(%100.0g) replace
		cap replace value="" if origvalue==.
		drop origvalue
		replace value=trim(value)
		
		* correct field names to match Stata field names (lowercase, drop -'s and .'s)
		replace fieldname=lower(subinstr(subinstr(fieldname,"-","",.),".","",.))
		
		* format date and date/time fields (taking account of possible wildcards for repeat groups)
		forvalues i = 1/100 {
			if "`datetime_fields`i''" ~= "" {
				foreach dtvar in `datetime_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						gen origvalue=value
						replace value=string(clock(value,"DMYhms",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
						* allow for cases where seconds haven't been specified
						replace value=string(clock(origvalue,"DMYhm",2025),"%25.0g") if strmatch(fieldname,"`dtvar'") & value=="." & origvalue~="."
						drop origvalue
					}
				}
			}
			if "`date_fields`i''" ~= "" {
				foreach dtvar in `date_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						replace value=string(clock(value,"DMY",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
					}
				}
			}
		}

		* write out a temp file with the commands necessary to apply each correction
		tempfile tempdo
		file open dofile using "`tempdo'", write replace
		local N = _N
		forvalues i = 1/`N' {
			local fieldnameval=fieldname[`i']
			local valueval=value[`i']
			local keyval=key[`i']
			local rownumval=rownum[`i']
			file write dofile `"cap replace `fieldnameval'="`valueval'" if key=="`keyval'""' _n
			file write dofile `"if _rc ~= 0 {"' _n
			if "`valueval'" == "" {
				file write dofile _tab `"cap replace `fieldnameval'=. if key=="`keyval'""' _n
			}
			else {
				file write dofile _tab `"cap replace `fieldnameval'=`valueval' if key=="`keyval'""' _n
			}
			file write dofile _tab `"if _rc ~= 0 {"' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab _tab `"disp "CAN'T APPLY CORRECTION IN ROW #`rownumval'""' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab `"}"' _n
			file write dofile `"}"' _n
		}
		file close dofile
	
		* restore primary data
		restore
		
		* execute the .do file to actually apply all corrections
		do "`tempdo'"

		* re-save data
		save "`dtafile'", replace
	}
	else {
		* restore primary data		
		restore
	}

	disp
	disp "Finished applying corrections in: `corrfile'"
	disp
}


* launch .do files to process repeat groups

do "import_covid_self_reporting_form-ct2_grp.do"
