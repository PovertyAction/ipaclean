
* Prep Stata

	clear all
	cls
	
	set seed 		16738
	set sortseed 	89384
	
/*	TEST 1
* Import data


	cd "C:\Users\IBaako\Documents\projects\ipaclean\ipaodkmergerepeats/data"
	do "import_covid_self_reporting_form.do"
	
* Include program

	include "../ipaodkmergerepeats.ado"
	
	
* Run program
	
	ipaodkmergerepeats using "C:\Users\IBaako\Documents\projects\ipaclean\ipaodkmergerepeats/data/COVID Self Reporting Form"
*/


*	TEST 2
* Import data


	cd "C:\Users\IBaako\Documents\projects\ipaclean\ipaodkmergerepeats/data2"
	do "import_nested_repeat_data.do"
	
* Include program

	include "../ipaodkmergerepeats.ado"
	
	
* Run program
	
	ipaodkmergerepeats using "C:\Users\IBaako\Documents\projects\ipaclean\ipaodkmergerepeats/data2/Nested Repeat Data"
