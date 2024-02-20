* set the working directory
gl arsene "C:/Users/Arsene Zongo/Box/Az/Github"
cd "${arsene}/ipaclean/test/3 test ipamerge/1 test data"

* clear
clear all

* generate master dataset
webuse autosize
gen v1_school = "School 1"
gen v2_dir = .
gen v5_longnum = 1234567 in 2 //at this stage, safely cannot convert more than 7 digits to string
save master.dta, replace
list

* generate using 1 dataset
webuse autoexpense
gen v1_school = 1
//gen v2_dir = "missing1"
gen v2_dir = 1
gen v3_using1 = "using 1 only"
gen v4_using2 = "2"
gen v5_longnum = 12
save using1.dta, replace
list

* generate using 2 dataset
gen v1_consent = 1 if _n == 2 | _n == 3
drop v1_school v2_dir v3_using1 v4_using2 v5_longnum
//gen v1_school = 1
gen v1_school = "School 1"
//gen v2_dir = 2
gen v2_dir = "missing"
//gen v4_using2 = "2"
gen v4_using2 = 2
//gen v5_longnum = 1234
gen v5_longnum = "i12345678914"
set obs `=`c(N)' + 1'
* new obs
replace make = "Mercedes 190" in `c(N)'
replace v2_dir = "missing missing" in `c(N)'
save using2.dta, replace
list

* load the master dataset
use master.dta, clear


