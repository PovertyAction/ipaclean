* Description: Similate Datasets for Testing ipacompare
* Author: Ishmail Azindoo Baako
* 4oct2023

* Prep Stata

	clear all
	cls
	
	set seed 		16738
	set sortseed 	89384
	
* Create folder

	cap mkdir "simulated data"
	
* Generate Master Dataset

	* Import excel sheet with names and IDs
	
	import excel using "ipa_compare_output_markup.xlsx", clear first sheet("details") cellra(B3) case(l)
	keep id respondentname 
	
	* Add additional details
	
	gen byte sex = runiformint(1, 2)
	lab define sex 1 "Male" 2 "Female"
	lab val sex sex 
	
	gen int age = runiformint(18, 48)
	
	gen region = "Region " + string(runiformint(1, 4))
	lab var region "Select Respondent's Region:"
	gen community = subinstr(region, "Region", "Community", 1) + char(runiformint(65, 69))
	lab var community "Select Respondent's Community:"
	
	sort region community, stable
	gen byte treatment = runiform() < 0.5
	lab var treatment "Treatment Status"
	gen byte treatment_type = cond(!treatment, 0, runiformint(1, 3))
	lab var treatment_type "Treatment Category"
	
	* save data as dta, csv and xlsx
	save "simulated data/Deworming Project - Master Dataset", replace
	export delim using "simulated data/Deworming Project - Master Dataset", replace nolab
	export excel using "simulated data/Deworming Project - Master Dataset.xlsx", replace first(var) nolab
	
* Generate census dataset

	use "simulated data/Deworming Project - Master Dataset", clear
	drop treatment treatment_type
	
	bys region: gen enumerator = subinstr(region, "Region", "Enumerator", 1) + string(runiformint(1, 5))
	lab var enumerator "Enumerator Name"
	gen enumerator_id = substr(enumerator, -2, .), before(enumerator)
	destring enumerator_id, replace
	lab var enumerator_id "Enumerator ID"
	
	gen double starttime = clock("01mar2020 08:20:00", "DMY hms") + (runiformint(0, 18) * runiformint(16400000, 86400000))
	gen double endtime  = starttime + runiformint(1000000, 8000000)
	gen double submissiondate  = endtime + runiformint(6000000, 86400000)
	format %tc starttime endtime submissiondate
	
	
	gen byte consent = runiform() <= 0.98, after(enumerator)
	gen byte complete = runiform() <= 0.9 & consent, after(consent)
	
	replace complete = 2 if complete == 1 & runiform() <= 0.05
	
	lab define consent 1 "Yes" 0 "No"
	lab val consent consent
	
	lab define complete 0 "No consent" 1 "Fully Completed" 2 "Partially Completed"
	lab val complete complete
	
	* save baseline data
	
	save "simulated data/Deworming Project - Census", replace
	
	
* Generate baseline data

	drop if !consent
	
	replace consent  = 0 if runiform() < 0.02
	replace complete = runiform() <= 0.97 & consent
	replace complete = 2 if complete == 1 & runiform() <= 0.02
	
	replace starttime = starttime + 2629800000 + (runiformint(0, 18) * runiformint(16400000, 86400000))
	replace endtime  = starttime + runiformint(1000000, 8000000)
	replace submissiondate  = endtime + runiformint(6000000, 86400000)
	format %tc starttime endtime submissiondate
	
	save "simulated data/Deworming Project - Baseline", replace
	
* Generate Midline Data	


	drop if !consent
	drop if runiform() < 0.12
	
	replace consent  = 0 if runiform() < 0.02
	replace complete = runiform() <= 0.97 & consent
	replace complete = 2 if complete == 1 & runiform() <= 0.02
	
	replace starttime = starttime + (12 * 2629800000) + (runiformint(0, 18) * runiformint(16400000, 86400000))
	replace endtime  = starttime + runiformint(1000000, 8000000)
	replace submissiondate  = endtime + runiformint(6000000, 86400000)
	format %tc starttime endtime submissiondate
	
	save "simulated data/Deworming Project - Midline", replace
	
* Generate Endline

	drop if !consent
	drop if runiform() < 0.18
	
	replace consent  = 0 if runiform() < 0.02
	replace complete = runiform() <= 0.97 & consent
	replace complete = 2 if complete == 1 & runiform() <= 0.02
	
	replace starttime = starttime + 2629800000 + (runiformint(0, 18) * runiformint(16400000, 86400000))
	replace endtime  = starttime + runiformint(1000000, 8000000)
	replace submissiondate  = endtime + runiformint(6000000, 86400000)
	format %tc starttime endtime submissiondate
	
	save "simulated data/Deworming Project - Endline", replace