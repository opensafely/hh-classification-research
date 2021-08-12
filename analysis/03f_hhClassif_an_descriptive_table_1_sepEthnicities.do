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
log using ./logs/03f_hhClassif_an_descriptive_table_1_sepEthnicities_`dataset'.log, replace t




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
	local lab: label `variable' `level'
	file write tablecontents (" `lab'") _tab
	
	*local lab: label hhRiskCatExp_4catsLabel 4

	
	/*this is the overall column*/
	cou if `variable' `condition'
	local total = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	*file write tablecontents %9.0gc (`total')  (" (") %3.1f (`colpct') (")") _tab
	file write tablecontents %9.0f (`total')  (" (") %3.1f (`colpct') (")") _tab

	/*this loops through groups*/
	forvalues i=1/4{
	cou if hhRiskCatExp_4cats == `i'
	local rowdenom = r(N)
	cou if hhRiskCatExp_4cats == `i' & `variable' `condition'
	local pct = 100*(r(N)/`total') 
	*file write tablecontents %9.0gc (r(N)) (" (") %3.1f (`pct') (")") _tab
	file write tablecontents %9.0f (r(N)) (" (") %3.1f (`pct') (")") _tab
	}
	
	file write tablecontents _n
end


cap prog drop generaterowEight
program define generaterowEight
syntax, variable(varname) condition(string) 
	
	cou
	local overalldenom=r(N)
	
	sum `variable' if `variable' `condition'
	**K Wing additional code to aoutput variable category labels**
	local level=substr("`condition'",3,.)
	local lab: label `variable' `level'
	file write tablecontents (" `lab'") _tab
	
	*local lab: label hhRiskCatExp_4catsLabel 4

	
	/*this is the overall column*/
	cou if `variable' `condition'
	local total = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	*file write tablecontents %9.0gc (`total')  (" (") %3.1f (`colpct') (")") _tab
	file write tablecontents %9.0f (`total')  (" (") %3.1f (`colpct') (")") _tab

	/*this loops through groups*/
	forvalues i=1/8{
	cou if hhRiskCatExp == `i'
	local rowdenom = r(N)
	cou if hhRiskCatExp == `i' & `variable' `condition'
	local pct = 100*(r(N)/`total') 
	*file write tablecontents %9.0gc (r(N)) (" (") %3.1f (`pct') (")") _tab
	file write tablecontents %9.0f (r(N)) (" (") %3.1f (`pct') (")") _tab
	}
	
	file write tablecontents _n
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
	file write tablecontents %9.0gc (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	forvalues i=1/4{
	cou if hhRiskCatExp_4cats == `i'
	local rowdenom = r(N)
	cou if hhRiskCatExp_4cats == `i' & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	file write tablecontents %9.0gc (r(N)) (" (") %3.1f (`pct') (")") _tab
	}
	
	file write tablecontents _n
end



/* Explanatory Notes 

defines a program (SAS macro/R function equivalent), generate row
the syntax row specifies two inputs for the program: 

	a VARNAME which is your variable 
	a CONDITION which is a string of some condition you impose 
	
the program counts if variable and condition and returns the counts
column percentages are then automatically generated
this is then written to the text file 'tablecontents' 
the number followed by space, brackets, formatted pct, end bracket and then tab

the format %3.1f specifies length of 3, followed by 1 dp. 

*/ 

********************************************************************************
* Generic code to output one section (varible) within table (calls above)

cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) min(real) max(real) [missing]

	local lab: variable label `variable'
	file write tablecontents ("`lab'") _n 

	forvalues varlevel = `min'/`max'{ 
		generaterow, variable(`variable') condition("==`varlevel'")
	}
	
	if "`missing'"!="" generaterow, variable(`variable') condition("== 12")
	


end

cap prog drop tabulatevariableEight
prog define tabulatevariableEight
syntax, variable(varname) min(real) max(real) [missing]

	local lab: variable label `variable'
	file write tablecontents ("`lab'") _n 

	forvalues varlevel = `min'/`max'{ 
		generaterowEight, variable(`variable') condition("==`varlevel'")
	}
	
	if "`missing'"!="" generaterowEight, variable(`variable') condition("== 12")
	


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
	file write tablecontents ("`lab'") _n 


	qui summarize `variable', d
	file write tablecontents ("Mean (SD)") _tab 
	file write tablecontents  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	
	forvalues i=1/4{							
	qui summarize `variable' if hhRiskCatExp_4cats == `i', d
	file write tablecontents  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	}

file write tablecontents _n

	
	qui summarize `variable', d
	file write tablecontents ("Median (IQR)") _tab 
	file write tablecontents %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	
	forvalues i=1/4{
	qui summarize `variable' if hhRiskCatExp_4cats == `i', d
	file write tablecontents %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	}
	
file write tablecontents _n
	
end

cap prog drop summarizevariableEight
prog define summarizevariableEight
syntax, variable(varname) 

	local lab: variable label `variable'
	file write tablecontents ("`lab'") _n 


	qui summarize `variable', d
	file write tablecontents ("Mean (SD)") _tab 
	file write tablecontents  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	
	forvalues i=1/8{							
	qui summarize `variable' if hhRiskCatExp_4cats == `i', d
	file write tablecontents  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	}

file write tablecontents _n

	
	qui summarize `variable', d
	file write tablecontents ("Median (IQR)") _tab 
	file write tablecontents %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	
	forvalues i=1/8{
	qui summarize `variable' if hhRiskCatExp_4cats == `i', d
	file write tablecontents %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	}
	
file write tablecontents _n
	
end




*Program that defines which variables are being outputted
program outputTableFourCats

* eth5 labelled columns *THESE WOULD BE HOUSEHOLD LABELS, eth5 is the equivqlent of the hh size variable

	local lab1: label hhRiskCat67PLUS_4cats 1
	local lab2: label hhRiskCat67PLUS_4cats 2
	local lab3: label hhRiskCat67PLUS_4cats 3
	local lab4: label hhRiskCat67PLUS_4cats 4
	*local lab5: label eth5 5
	*local lab6: label eth5 6



	file write tablecontents _tab ("Total")				  			  _tab ///
								 ("`lab1'")  						  _tab ///
								 ("`lab2'")  						  _tab ///
								 ("`lab3'")  						  _tab ///
								 ("`lab4'")  						  _n
								 *("`lab5'")  						  _tab
								 *("`lab6'")  						  _n 							 
								 

	*SEX
	tabulatevariable, variable(sex) min(1) max(2) 
	file write tablecontents _n 

	*AGE
	qui summarizevariable, variable(age) 
	file write tablecontents _n

	tabulatevariable, variable(ageCatfor67Plus) min(0) max(4) 
	file write tablecontents _n 

	*BMI
	tabulatevariable, variable(bmicat) min(1) max(6) 
	file write tablecontents _n 

	*SMOKING
	tabulatevariable, variable(smoke) min(1) max(3) 
	file write tablecontents _n 

	*IMD
	tabulatevariable, variable(imd) min(1) max(5) 
	file write tablecontents _n 

	*REGION
	tabulatevariable, variable(region) min(0) max(8) 
	file write tablecontents _n 

	*RURAL URBAN (five categories)
	tabulatevariable, variable(rural_urbanFive) min(1) max(5) 
	file write tablecontents _n 

	*HOUSEHOLD SIZE
	tabulatevariable, variable(hh_total_cat) min(1) max(3) 
	file write tablecontents _n 

	*COMORBIDITIES (3 CATEGORIES)
	tabulatevariable, variable(coMorbCat) min(0) max(2) 
	file write tablecontents _n 

	file write tablecontents _n _n

end


*Program that defines which variables are being outputted
program outputTableEightCats

* eth5 labelled columns *THESE WOULD BE HOUSEHOLD LABELS, eth5 is the equivqlent of the hh size variable

	local lab1: label hhRiskCat67PLUS 1
	local lab2: label hhRiskCat67PLUS 2
	local lab3: label hhRiskCat67PLUS 3
	local lab4: label hhRiskCat67PLUS 4
	local lab5: label hhRiskCat67PLUS 5
	local lab6: label hhRiskCat67PLUS 6
	local lab7: label hhRiskCat67PLUS 7
	local lab8: label hhRiskCat67PLUS 8
	*local lab5: label eth5 5
	*local lab6: label eth5 6



	file write tablecontents _tab ("Total")				  			  _tab ///
								 ("`lab1'")  						  _tab ///
								 ("`lab2'")  						  _tab ///
								 ("`lab3'")  						  _tab ///
								 ("`lab4'")  						  _tab ///
								 ("`lab5'")  						  _tab ///
								 ("`lab6'")  						  _tab ///
								 ("`lab7'")  						  _tab ///
								 ("`lab8'")  						  _n
								 *("`lab5'")  						  _tab
								 *("`lab6'")  						  _n 							 
								 

	*SEX
	tabulatevariableEight, variable(sex) min(1) max(2) 
	file write tablecontents _n 

	*AGE
	qui summarizevariableEight, variable(age) 
	file write tablecontents _n

	tabulatevariableEight, variable(ageCatfor67Plus) min(0) max(4) 
	file write tablecontents _n 

	*BMI
	tabulatevariableEight, variable(bmicat) min(1) max(6) 
	file write tablecontents _n 

	*SMOKING
	tabulatevariableEight, variable(smoke) min(1) max(3) 
	file write tablecontents _n 

	*IMD
	tabulatevariableEight, variable(imd) min(1) max(5) 
	file write tablecontents _n 

	*REGION
	tabulatevariableEight, variable(region) min(0) max(8) 
	file write tablecontents _n 

	*RURAL URBAN (five categories)
	tabulatevariableEight, variable(rural_urbanFive) min(1) max(5) 
	file write tablecontents _n 

	*HOUSEHOLD SIZE
	tabulatevariableEight, variable(hh_total_cat) min(1) max(3) 
	file write tablecontents _n 

	*COMORBIDITIES (3 CATEGORIES)
	tabulatevariableEight, variable(coMorbCat) min(0) max(2) 
	file write tablecontents _n 

	file write tablecontents _n _n

end




/* INVOKE PROGRAMS FOR TABLE 1 BY ETHNICITY================================================*/ 
*Set up output file
cap file close tablecontents
file open tablecontents using ./output/table1_hhClassif_byEthnicity`dataset'.txt, write text replace

file write tablecontents ("Table 1: Demographic and Clinical Characteristics - `dataset'") _n

forvalues e=1/5 {
		* Open Stata dataset
		if `e'==1 {
			file write tablecontents "Ethnicity: White " _n
			use ./output/hhClassif_analysis_dataset_ageband_3`dataset'.dta, clear
			keep if eth5==1
			file write tablecontents "-Four categories-" _n
			outputTableFourCats
			file write tablecontents "-Eight categories-" _n
			outputTableEightCats
		}
		else if `e'==2 {
			file write tablecontents "Ethnicity: South Asian " 
			use ./output/hhClassif_analysis_dataset_ageband_3`dataset'.dta, clear
			keep if eth5==2
			file write tablecontents "-Four categories-" _n
			outputTableFourCats
			file write tablecontents "-Eight categories-" _n
			outputTableEightCats
		}
		else if `e'==3 {
			file write tablecontents "Ethnicity: Black " 
			use ./output/hhClassif_analysis_dataset_ageband_3`dataset'.dta, clear
			keep if eth5==3
			file write tablecontents "-Four categories-" _n
			outputTableFourCats
			file write tablecontents "-Eight categories-" _n
			outputTableEightCats
		}
		else if `e'==4 {
			file write tablecontents "Ethnicity: Mixed " 
			use ./output/hhClassif_analysis_dataset_ageband_3`dataset'.dta, clear
			keep if eth5==4
			file write tablecontents "-Four categories-" _n
			outputTableFourCats
			file write tablecontents "-Eight categories-" _n
			outputTableEightCats
		}
		else if `e'==5 {
			file write tablecontents "Ethnicity: Other "
			use ./output/hhClassif_analysis_dataset_ageband_3`dataset'.dta, clear
			keep if eth5==5
			file write tablecontents "-Four categories-" _n
			outputTableFourCats
			file write tablecontents "-Eight categories-" _n
			outputTableEightCats
		}
	}
cap file close tablecontents
cap log close


















