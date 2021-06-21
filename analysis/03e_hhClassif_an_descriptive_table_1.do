/*==============================================================================
DO FILE NAME:			05b_eth_table1_descriptives_eth5
PROJECT:				Household transmission analysis 
DATE: 					25 August 2020 
AUTHOR:					K Wing
						adapted from R Mathur	
DESCRIPTION OF FILE:	Produce a table of baseline characteristics by:
								1.household size that a person lives in
								2.age of a person
						These two are of interest because the main outcome variable (hh composition) is a combination of both of these
						Need to update this code so that it is for household size to start with (am adapting a file that was outputting by ethnicity categories)
						Output to a textfile for further formatting
DATASETS USED:			$Tempdir\analysis_dataset.dta
DATASETS CREATED: 		None
OTHER OUTPUT: 			Results in txt: $Tabfigdir\table1.txt 
						Log file: $Logdir\05_eth_table1_descriptives
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)	
  
 Notes:
 Table 1 population is people who are alive on indexdate
 It does not exclude anyone who experienced any outcome prior to indexdate
 change the analysis_dataset to exlucde people with any of the following as of Feb 1st 2020:
 COVID identified in primary care
 COVID test result via  SGSS
 A&E admission for COVID-19
 ICU admission for COVID-19
 
sysdir set PLUS "/Users/kw/Documents/GitHub/households-research/analysis/adofiles" 
sysdir set PERSONAL "/Users/kw/Documents/GitHub/households-research/analysis/adofiles" 

cd ${outputData}
clear all


*first test run, am going to see if I can output tables by ethnicity category - worked, now make edits for hh_size and age
*probably going to make a 5 category variable for age

 ==============================================================================*/
sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles

local dataset `1'

* Open a log file

capture log close
log using ./logs/03d_hhClassif_an_descriptive_table_1_`dataset'.log, replace t

* Open Stata dataset
use ./output/hhClassif_analysis_dataset`dataset'.dta, clear





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
file open tablecontent using ./output/table1_hhClassif`dataset'.txt, write text replace

file write tablecontent ("Table 1: Demographic and Clinical Characteristics") _n

* eth5 labelled columns *THESE WOULD BE HOUSEHOLD LABELS, eth5 is the equivqlent of the hh size variable

local lab1: label hhRiskCatBROADLabel 1
local lab2: label hhRiskCatBROADLabel 2
local lab3: label hhRiskCatBROADLabel 3
*local lab4: label hhRiskCatBROADLabel 4
*local lab5: label eth5 5
*local lab6: label eth5 6



file write tablecontent _tab ("Total")				  			  _tab ///
							 ("`lab1'")  						  _tab ///
							 ("`lab2'")  						  _tab ///
							 ("`lab3'")  						  _n
							 *("`lab4'")  						  _n
							 *("`lab5'")  						  _tab
							 *("`lab6'")  						  _n 							 
							 


* DEMOGRAPHICS (more than one level, potentially missing) 

/*reminder of variables:
patient_id age ageCat hh_id hh_size hh_composition case_date case eth5 eth16 ethnicity_16 indexdate sex bmicat smoke imd region comorb_Neuro comorb_Immunosuppression shielding chronic_respiratory_disease chronic_cardiac_disease diabetes chronic_liver_disease cancer egfr_cat hypertension smoke_nomiss rural_urban
*/


*format hba1c_pct bmi egfr %9.2f

/*
gen byte cons=1
tabulatevariable, variable(cons) min(1) max(1) 
file write tablecontent _n 
*/

*SIZE OF LINKED DATASETS
*gen  byte SGSS=1 if tested==1

*file write tablecontent ("SGSS data") _tab
*generaterow2, variable(SGSS) condition("==1")

*gen  byte ICNARC=1 if tested==1
*file write tablecontent ("ICNARC data") _tab
*generaterow2, variable(ICNARC) condition("==1")

*SEX
tabulatevariable, variable(sex) min(1) max(2) 
file write tablecontent _n 

*AGE
qui summarizevariable, variable(age) 
file write tablecontent _n

tabulatevariable, variable(ageCatHHRisk) min(0) max(3) 
file write tablecontent _n 

*ETHNICITY
tabulatevariable, variable(eth5) min(1) max(5) 
file write tablecontent _n 

*BMI
tabulatevariable, variable(bmicat) min(1) max(6) 
file write tablecontent _n 

*SMOKING
tabulatevariable, variable(smoke) min(1) max(4) 
file write tablecontent _n 

*IMD
tabulatevariable, variable(imd) min(1) max(5) 
file write tablecontent _n 

*REGION
tabulatevariable, variable(region) min(0) max(8) 
file write tablecontent _n 

*RURAL URBAN (five categories)
tabulatevariable, variable(rural_urbanFive) min(1) max(5) 
file write tablecontent _n 

*HOUSEHOLD SIZE
tabulatevariable, variable(hh_total_cat) min(1) max(3) 
file write tablecontent _n 

*COMORBIDITIES (3 CATEGORIES)
tabulatevariable, variable(coMorbCat) min(0) max(2) 
file write tablecontent _n 



file write tablecontent _n _n


file close tablecontent


* Close log file 
log close

clear
insheet using ./output/table1_hhClassif`dataset'.txt, clear


export excel using ./output/table1_hhClassif`dataset'.xlsx, replace



















