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

* Open Stata dataset
use ./output/hhClassif_analysis_datasetMAIN.dta, clear
*use ./output/hhClassif_analysis_dataset`dataset'.dta, clear

keep patient_id hhRiskCat hh_size* hhRiskCatBROAD ethnicity ethnicity_16 hh_size eth5 imd eth16

 /* PROGRAMS TO AUTOMATE TABULATIONS===========================================*/ 

********************************************************************************
* All below code from K Baskharan 
* Generic code to output one row of table

cap prog drop generaterow
program define generaterow
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
	*file write tablecontent %9.0gc (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab
	file write tablecontent %9.0f (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	/*this loops through groups*/
	forvalues i=1/3{
	cou if hhRiskCatBROAD == `i'
	local rowdenom = r(N)
	cou if hhRiskCatBROAD == `i' & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	*file write tablecontent %9.0gc (r(N)) (" (") %3.1f (`pct') (")") _tab
	file write tablecontent %9.0f (r(N)) (" (") %3.1f (`pct') (")") _tab
	}
	
	file write tablecontent _n
end


* Output one row of table for co-morbidities and meds

cap prog drop generaterow2 /*this puts it all on the same row, is rohini's edit*/
program define generaterow2
syntax, variable(varname) condition(string) 
	
	cou
	local overalldenom=r(N)5
	
	cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %9.0gc (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	forvalues i=1/3{
	cou if hhRiskCatBROAD == `i'
	local rowdenom = r(N)
	cou if hhRiskCatBROAD == `i' & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	file write tablecontent %9.0gc (r(N)) (" (") %3.1f (`pct') (")") _tab
	}
	
	file write tablecontent _n
end



/* Explanatory Notes 

defines a program (SAS macro/R function equivalent), generate row
the syntax row specifies two inputs for the program: 

	a VARNAME which is your variable 
	a CONDITION which is a string of some condition you impose 
	
the program counts if variable and condition and returns the counts
column percentages are then automatically generated
this is then written to the text file 'tablecontent' 
the number followed by space, brackets, formatted pct, end bracket and then tab

the format %3.1f specifies length of 3, followed by 1 dp. 

*/ 

********************************************************************************
* Generic code to output one section (varible) within table (calls above)

cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) min(real) max(real) [missing]

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 

	forvalues varlevel = `min'/`max'{ 
		generaterow, variable(`variable') condition("==`varlevel'")
	}
	
	if "`missing'"!="" generaterow, variable(`variable') condition("== 12")
	


end

********************************************************************************

/* Explanatory Notes 

defines program tabulate variable 
syntax is : 

	- a VARNAME which you stick in variable 
	- a numeric minimum 
	- a numeric maximum 
	- optional missing option, default value is . 

forvalues lowest to highest of the variable, manually set for each var
run the generate row program for the level of the variable 
if there is a missing specified, then run the generate row for missing vals

*/ 

********************************************************************************
* Generic code to qui summarize a continous variable 

cap prog drop summarizevariable 
prog define summarizevariable
syntax, variable(varname) 

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 


	qui summarize `variable', d
	file write tablecontent ("Mean (SD)") _tab 
	file write tablecontent  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	
	forvalues i=1/3{							
	qui summarize `variable' if hhRiskCatBROAD == `i', d
	file write tablecontent  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	}

file write tablecontent _n

	
	qui summarize `variable', d
	file write tablecontent ("Median (IQR)") _tab 
	file write tablecontent %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	
	forvalues i=1/3{
	qui summarize `variable' if hhRiskCatBROAD == `i', d
	file write tablecontent %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	}
	
file write tablecontent _n
	
end

/* INVOKE PROGRAMS FOR TABLE 1================================================*/ 

*Set up output file
cap file close tablecontent
file open tablecontent using ./output/table_hh_descriptives`dataset'.txt, write text replace

file write tablecontent ("Table x: Household size by ethnic group") _n

* HOUSEHOLD SIZE BY ETHNICITY ONLY

local lab1: label eth5 1
local lab2: label eth5 2
local lab3: label eth5 3
local lab4: label eth5 4
local lab5: label eth5 5



file write tablecontent _tab ("Total")				  			  _tab ///
							 ("`lab1'")  						  _tab ///
							 ("`lab2'")  						  _tab ///
							 ("`lab3'")  						  _tab ///
							 ("`lab4'")  						  _tab ///
							 ("`lab5'")  						  _n
							 



*HOUSEHOLD GENERATIONS BROAD
tabulatevariable, variable( hhRiskCatBROAD) min(1) max(3) 
file write tablecontent _n 

*HOUSEHOLD SIZE
tabulatevariable, variable(hh_size5cat) min(1) max(4) 
file write tablecontent _n 

*HOUSEHOLD GENERATIONS DETAILED
tabulatevariable, variable(hhRiskCat) min(1) max(14) 
file write tablecontent _n 


file write tablecontent _n _n


file close tablecontent

clear
insheet using ./output/table_hh_descriptives`dataset'.txt, clear
export excel using ./output/table_hh_descriptives`dataset'.xlsx, replace


* HOUSEHOLD SIZE BY ETHNICITY AND IMD



* Close log file 
log close



















							  









