/*==============================================================================
DO FILE NAME:			00_hhClassif_cr_analysis_dataset
PROJECT:				describe household composition by ethnicity and IMD
DATE: 					12th August 2020 
AUTHOR:					Rohini Mathur/Kevin Wing 
DESCRIPTION OF FILE:	program 10, descriptive variables
DATASETS USED:			main analysis dataset for each wave
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir


sysdir set PLUS "/Users/kw/Documents/GitHub/households-research/analysis/adofiles" 
sysdir set PERSONAL "/Users/kw/Documents/GitHub/households-research/analysis/adofiles" 
							
==============================================================================*/
sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles
pwd



* Open a log file
cap log close
log using ./logs/10_hh_imd_descriptives_W1.log, replace t


 /* PROGRAMS TO AUTOMATE TABULATIONS===========================================*/ 

********************************************************************************
* All below code from K Baskharan 
* Generic code to output one row of table for ethnicity

cap prog drop generaterow_eth
program define generaterow_eth
syntax, variable(varname) condition(string) 
	
	cou
	local overalldenom=r(N)
	
	sum `variable' if `variable' `condition'
	**K Wing additional code to aoutput variable category labels**
	local level=substr("`condition'",3,.)
	local lab: label `variable'Label `level'
	file write tablecontent (" `lab'") _tab
	
	*local lab: label hhRiskCatBROADLabel 4

	
	/*this is the overall column*/
	cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %9.0f (`rowdenom') _tab   %3.1f (`colpct')  _tab

	/*this loops through groups*/
	forvalues i=1/5{
	cou if eth5 == `i'
	local rowdenom = r(N)
	cou if eth5 == `i' & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	*file write tablecontent %9.0gc (r(N))  %3.1f (`pct')  _tab
	file write tablecontent %9.0f (r(N)) _tab  %3.1f (`pct')  _tab
	}
	
	file write tablecontent _n
end


********************************************************************************
* Generic code to output one section (varible) within table (calls above)

cap prog drop tabulatevariable_eth
prog define tabulatevariable_eth
syntax, variable(varname) min(real) max(real) [missing]

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 

	forvalues varlevel = `min'/`max'{ 
		generaterow_eth, variable(`variable') condition("==`varlevel'")
	}
	
	if "`missing'"!="" generaterow_eth, variable(`variable') condition("== 12")
	
end

********************************************************************************
* All below code from K Baskharan 
* Generic code to output one row of table for ethnicity-imd combined variable

cap prog drop generaterow_ethimd
program define generaterow_ethimd
syntax, variable(varname) condition(string) 
	
	cou
	local overalldenom=r(N)
	
	sum `variable' if `variable' `condition'
	**K Wing additional code to aoutput variable category labels**
	local level=substr("`condition'",3,.)
	local lab: label `variable'Label `level'
	file write tablecontent (" `lab'") _tab
	
	*local lab: label hhRiskCatBROADLabel 4

	
	/*this is the overall column*/
	cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %9.0f (`rowdenom') _tab   %3.1f (`colpct')  _tab

	/*this loops through groups*/
	forvalues i=1/10{
	cou if eth_imd == `i'
	local rowdenom = r(N)
	cou if eth_imd == `i' & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	*file write tablecontent %9.0gc (r(N))  %3.1f (`pct')  _tab
	file write tablecontent %9.0f (r(N)) _tab  %3.1f (`pct')  _tab
	}
	
	file write tablecontent _n
end


********************************************************************************
* Generic code to output one section (varible) within table (calls above)

cap prog drop tabulatevariable_ethimd
prog define tabulatevariable_ethimd
syntax, variable(varname) min(real) max(real) [missing]

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 

	forvalues varlevel = `min'/`max'{ 
		generaterow_ethimd, variable(`variable') condition("==`varlevel'")
	}
	
	if "`missing'"!="" generaterow_ethimd, variable(`variable') condition("== 12")
	
end


/* INVOKE PROGRAMS FOR TABLE 1================================================*/ 

* Open Stata dataset
use ./output/hhClassif_analysis_datasetMAIN.dta, clear
*use ./output/hhClassif_analysis_dataset`dataset'.dta, clear

keep patient_id hhRiskCat hh_size* hhRiskCatBROAD ethnicity ethnicity_16 hh_size eth5 imd eth16

*Set up output file
cap file close tablecontent
file open tablecontent using ./output/table_ethnicity_descriptivesMAIN.txt, write text replace

file write tablecontent ("Table x: Household size by ethnic group") _n

* HOUSEHOLD SIZE BY ETHNICITY ONLY

local lab1: label eth5 1
local lab2: label eth5 2
local lab3: label eth5 3
local lab4: label eth5 4
local lab5: label eth5 5



file write tablecontent _tab ("Total")				  			  _tab _tab ///
							 ("`lab1'")  						  _tab _tab ///
							 ("`lab2'")  						  _tab _tab ///
							 ("`lab3'")  						  _tab _tab ///
							 ("`lab4'")  						  _tab _tab ///
							 ("`lab5'")  						  _tab _n
							 



*HOUSEHOLD GENERATIONS BROAD
tabulatevariable_eth, variable( hhRiskCatBROAD) min(1) max(3) 
file write tablecontent _n 

*HOUSEHOLD SIZE
tabulatevariable_eth, variable(hh_size5cat) min(1) max(4) 
file write tablecontent _n 

*HOUSEHOLD GENERATIONS DETAILED
tabulatevariable_eth, variable(hhRiskCat) min(1) max(14) 
file write tablecontent _n 


file write tablecontent _n _n
file close tablecontent
insheet using ./output/table_ethnicity_descriptivesMAIN.txt, clear



* HOUSEHOLD SIZE BY ETHNICITY AND IMD

* Open Stata dataset
use ./output/hhClassif_analysis_datasetMAIN.dta, clear
*use ./output/hhClassif_analysis_dataset`dataset'.dta, clear

keep patient_id hhRiskCat hh_size* hhRiskCatBROAD ethnicity ethnicity_16 hh_size eth5 imd eth16

*Set up output file
file open tablecontent using ./output/table_ethimd_descriptivesMAIN.txt, write text replace

file write tablecontent ("Table x: Household size by ethnic and IMD") _n

*gen eth-imd variable for white and SA
gen eth_imd=1 if eth5==1 & imd==1
replace eth_imd=2 if eth5==1 & imd==2
replace eth_imd=3 if eth5==1 & imd==3
replace eth_imd=4 if eth5==1 & imd==4
replace eth_imd=5 if eth5==1 & imd==5
replace eth_imd=6 if eth5==2 & imd==1
replace eth_imd=7 if eth5==2 & imd==2
replace eth_imd=8 if eth5==2 & imd==3
replace eth_imd=9 if eth5==2 & imd==4
replace eth_imd=10 if eth5==2 & imd==5

label define eth_imd 1"White Q1" 2"White Q2" 3"White Q3" 4"White Q4" 5"White Q5" ///
6"SA Q1" 7"SA Q2" 8"SA Q3" 9"SA Q4" 10"SA Q5" 

label values eth_imd eth_imd
tab eth_imd

local lab1: label eth_imd 1
local lab2: label eth_imd 2
local lab3: label eth_imd 3
local lab4: label eth_imd 4
local lab5: label eth_imd 5
local lab5: label eth_imd 6
local lab5: label eth_imd 7
local lab5: label eth_imd 8
local lab5: label eth_imd 9
local lab5: label eth_imd 10


file write tablecontent _tab ("Total")				  			  _tab _tab ///
							 ("`lab1'")  						  _tab _tab ///
							 ("`lab2'")  						  _tab _tab ///
							 ("`lab3'")  						  _tab _tab ///
							 ("`lab4'")  						  _tab _tab ///
							 ("`lab5'")  						  _tab _tab ///
							 ("`lab6'")  						  _tab _tab ///
							 ("`lab7'")  						  _tab _tab ///
							 ("`lab8'")  						  _tab  _tab ///
							 ("`lab9'")  						  _tab _tab  ///
							 ("`lab10'")  						  _n
							 



*HOUSEHOLD GENERATIONS BROAD
tabulatevariable_ethimd, variable( hhRiskCatBROAD) min(1) max(3) 
file write tablecontent _n 

*HOUSEHOLD SIZE
tabulatevariable_ethimd, variable(hh_size5cat) min(1) max(4) 
file write tablecontent _n 

*HOUSEHOLD GENERATIONS DETAILED
tabulatevariable_ethimd, variable(hhRiskCat) min(1) max(14) 
file write tablecontent _n 


file write tablecontent _n _n


file close tablecontent



* Close log file 
log close




*check imd
insheet using ./output/table_ethimd_descriptivesMAIN.txt, clear



**BAR CHARTS

use ./output/hhClassif_analysis_datasetMAIN.dta, clear
keep eth5 imd hhRiskCatBROAD hh_size5cat hhRiskCat
tab  hhRiskCatBROAD, generate(broad)
tab  hh_size5cat, generate(size)
tab  hhRiskCat, generate(hhcat)

*BY ETHNICITY 
graph bar broad1 broad2 broad3, over(eth5) saving(./output/rohini_hhbroad_eth.gph, replace)

graph bar size1 size2 size3 size4, over(eth5) saving(./output/rohini_hhsize_eth.gph, replace)

graph bar hhcat1 hhcat2 hhcat3 hhcat4 hhcat5 hhcat6 hhcat7 hhcat8 hhcat9 hhcat10 hhcat11 hhcat12 hhcat13 hhcat14, over(eth5) saving(./output/rohini_hhcat_eth.gph, replace)

*BY ETHNICITY AND IMD
*gen eth-imd variable for white and SA
gen eth_imd=1 if eth5==1 & imd==1
replace eth_imd=2 if eth5==1 & imd==2
replace eth_imd=3 if eth5==1 & imd==3
replace eth_imd=4 if eth5==1 & imd==4
replace eth_imd=5 if eth5==1 & imd==5
replace eth_imd=6 if eth5==2 & imd==1
replace eth_imd=7 if eth5==2 & imd==2
replace eth_imd=8 if eth5==2 & imd==3
replace eth_imd=9 if eth5==2 & imd==4
replace eth_imd=10 if eth5==2 & imd==5

label define eth_imd 1"White Q1" 2"White Q2" 3"White Q3" 4"White Q4" 5"White Q5" ///
6"SA Q1" 7"SA Q2" 8"SA Q3" 9"SA Q4" 10"SA Q5" 

label values eth_imd eth_imd
tab eth_imd

							  
graph bar broad1 broad2 broad3, over(eth_imd) saving(./output/rohini_hhbroad_ethimd.gph, replace)

graph bar size1 size2 size3 size4, over(eth_imd) saving(./output/rohini_hhsize_ethimd.gph, replace)

graph bar hhcat1 hhcat2 hhcat3 hhcat4 hhcat5 hhcat6 hhcat7 hhcat8 hhcat9 hhcat10 hhcat11 hhcat12 hhcat13 hhcat14, over(eth_imd) saving(./output/rohini_hhcat_ethimd.gph, replace) legend(off)









