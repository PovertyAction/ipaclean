
* clear
clear all


* cd
cd "C:/Users/Arsene Zongo/Box/Az/Github/ipaclean/test/3 test ipamerge/1 test data"
use master.dta, clear
drop v1_school
gen v1_school = 11


* master data
webuse autosize
gen v1_school = "School 1"
gen v2_dir = .
gen v5_longnum = 1234567890 in 2
save master.dta, replace
list


* using 1 data
webuse autoexpense
gen v1_school = 1
//gen v2_dir = "missing1"
gen v2_dir = 1
gen v3_using1 = "using 1 only"
gen v4_using2 = "2"
gen v5_longnum = 12
save using1.dta, replace
list


* using 2 data
gen v1_consent = 1 if _n == 2 | _n == 3
drop v1_school v2_dir v3_using1 v4_using2 v5_longnum
//gen v1_school = 1
gen v1_school = "School 1"
//gen v2_dir = 2
gen v2_dir = "missing"
//gen v4_using2 = "2"
gen v4_using2 = 2
//gen v5_longnum = 1234
gen v5_longnum = "i12345678901"
set obs `=`c(N)' + 1'

* new obs
replace make = "Mercedes 190" in `c(N)'

save using2.dta, replace
list

* load master
use master.dta, clear


