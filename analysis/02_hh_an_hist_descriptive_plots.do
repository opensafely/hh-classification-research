/*==============================================================================
DO FILE NAME:			02_an_data_checks
PROJECT:				Households and COVID
AUTHOR:					K Wing
DATE: 					25th August 2020
DESCRIPTION OF FILE:	Outputs sanity checking histograms of secondary cases by household size, also by date and ethnicity

DATASETS USED:			hh_analysis_datasetREDVARS
DATASETS CREATED: 		None
OTHER OUTPUT: 			Log file: $logdir\02_an_hist_descriptive_plots

cd ${outputData}
clear all
use hh_analysis_dataset_DRAFT.dta, clear
							
==============================================================================*/
cd ${outputData}
clear all
use hh_analysis_dataset.dta, clear


* Open a log file
cap log close
log using "02_an_hist_descriptive_plots", replace t

/*These need updated - don't need to program that removes all bins <5, only need to redact when:
	1. If the total in the histogram is <5 then don't include in the hh size histogram
	2. Always include the total number of households with 0 cases somewhere in the plot
	3. The first 3 bars of the histogram have to add up to more than 5, otherwise need to redact
Based on meeting between Roz, Amir, Stephen and Kevin 7th October 2020
*/


*========================PROGRAMS=====================================

******************(b) Set 2 of histograms: distribution of total number of cases by household size, by ethnicity to start with******************
program hhCasesHistByEthnicity
	if `3'==1  { 
		local ethnicity="White"
	}
	else if `3'==2  { 
		local ethnicity="South_Asian"
	}
	else if `3'==3  { 
		local ethnicity="Black"
	}
	hist `1' if hh_size==`2' & eth5==`3', frequency addlabels discrete xlabel(1(1)`2') title (Household size: `2', size (medium)) subtitle(`ethnicity' "(households with no cases: `4')", size (medium)) saving(`2'_`ethnicity', replace)
end

/*
e.g. in a household size of 4, how many houses had 1 case, how many had 2, how many had 3, how many had 4
-so instead of case_date as the parameter, I want number of cases in the household
*/ 




*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
use hh_analysis_dataset.dta, clear
 
*first of all, create a number of cases in the household variable
bysort hh_id:egen totCasesInHH=total(case) 
*then reduce to one record per household id
duplicates drop hh_id, force

preserve
	keep if totCasesInHH==0
	save hhWithZeroCases.dta, replace
restore
 
*keep only houses with at least one case for this descriptive analysis
keep if totCasesInHH>0
count
*drop cases that are dates prior to Feb012020
*drop if case_date<date("20200201", "YMD")

tempfile forHistOutput
save `forHistOutput'


*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	

	
	*histogram showing distribution of total number of cases in household by ethnicity
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==1
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 1 `hhWithNoCases' 	/*white*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==2
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 2 `hhWithNoCases'  /*south asian*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==3
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 3 `hhWithNoCases'	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph
	gr export totCasesinHHsize`l'ByEthnicity.pdf, replace
}





**************repeat above by RURAL URBAN broad categories*******************
use hh_analysis_dataset.dta, clear
numlabel, add
 
*first of all, create a number of cases in the household variable
bysort hh_id:egen totCasesInHH=total(case) 
*then reduce to one record per household id
duplicates drop hh_id, force

*keep only households in conurbations
tab rural_urbanFive
keep if rural_urbanFive==1|rural_urbanFive==2
tab rural_urbanFive

preserve
	keep if totCasesInHH==0
	save hhWithZeroCases.dta, replace
restore
 
*keep only houses with at least one case for this descriptive analysis
keep if totCasesInHH>0
count
*drop cases that are dates prior to Feb012020
*drop if case_date<date("20200201", "YMD")

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==1
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 1 `hhWithNoCases' 	/*white*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==2
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 2 `hhWithNoCases'  /*south asian*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==3
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 3 `hhWithNoCases'	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (Urban (major or minor conurbation))
	gr export totCasesinHHsize`l'ByEthnicity_Conurbations.pdf, replace
}





**************repeat above by RURAL URBAN broad categories*******************
use hh_analysis_dataset.dta, clear
numlabel, add
 
*first of all, create a number of cases in the household variable
bysort hh_id:egen totCasesInHH=total(case) 
*then reduce to one record per household id
duplicates drop hh_id, force

*keep only households outside of conurbations
tab rural_urbanFive
keep if rural_urbanFive==3|rural_urbanFive==4|rural_urbanFive==5
tab rural_urbanFive

preserve
	keep if totCasesInHH==0
	save hhWithZeroCases.dta, replace
restore
 
*keep only houses with at least one case for this descriptive analysis
keep if totCasesInHH>0
count
*drop cases that are dates prior to Feb012020
*drop if case_date<date("20200201", "YMD")

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==1
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 1 `hhWithNoCases' 	/*white*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==2
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 2 `hhWithNoCases'  /*south asian*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==3
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 3 `hhWithNoCases'	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (More rural)
	gr export totCasesinHHsize`l'ByEthnicity_More_Rural.pdf, replace
}






**************repeat above by rural urban broad categories*******************
*=========RURAL LOCATION===============
*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
use hh_analysis_dataset.dta, clear
numlabel, add

*keep only cases for this descriptive analysis
keep if case==1
*drop cases that are dates prior to Feb012020
drop if case_date<date("20200201", "YMD")

*keep only the more well off househholds
tab rural_urbanBroad
keep if rural_urbanBroad==0

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 1	/*white*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 2   /*south asian*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 3	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (Rural)
	gr export totCasesinHHsize`l'ByEthnicity_Rural.pdf, replace
}




*=========URBAN LOCATION===============
*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
use hh_analysis_dataset.dta, clear
numlabel, add

*keep only cases for this descriptive analysis
keep if case==1
*drop cases that are dates prior to Feb012020
drop if case_date<date("20200201", "YMD")

*keep only the more well off househholds
tab rural_urbanBroad
keep if rural_urbanBroad==1

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 1	/*white*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 2   /*south asian*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 3	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (Urban)
	gr export totCasesinHHsize`l'ByEthnicity_Urban.pdf, replace
}














/* legacy code
* Open a log file

cap log close
log using "02_an_data_checks", replace t

*capture log close
*log using "$Logdir/02_an_data_checks", replace t

numlabel, add

* Open Stata dataset
*use "$Tempdir/analysis_dataset.dta", clear


*Duplicate patient check
datacheck _n==1, bysort(patient_id) nol


/* CHECK INCLUSION AND EXCLUSION CRITERIA=====================================*/ 

* DATA STRUCTURE: Confirm one row per patient 
duplicates tag patient_id, generate(dup_check)
cap assert dup_check == 0 
drop dup_check

* INCLUSION 1: <=110 at 1 Feb 2020 
cap assert age < .
cap assert age <= 110
 
* INCLUSION 2: M or F gender at 1 Feb 2020 
cap assert inlist(sex, "M", "F")

* EXCLUDE 1:  MISSING IMD
cap assert inlist(imd, 1, 2, 3, 4, 5)


/* EXPECTED VALUES============================================================*/ 

*HH
summ hh_size hh_linear hh_log_linea
safetab hh_total_cat, m

*Care home
safetab carehome, m
safetab carehome hh_total_cat, m

* Age
summ age
datacheck age<., nol
datacheck inlist(agegroup, 1, 2, 3, 4, 5, 6, 7), nol

* Sex
safetab male, m
datacheck inlist(male, 0, 1), nol

* BMI 
summ bmi
safetab obese4cat, m 
datacheck inlist(obese4cat, 1, 2, 3, 4), nol

safetab obese4cat_sa, m
datacheck inlist(obese4cat_sa, 1, 2, 3, 4), nol

safetab bmicat, m
datacheck inlist(bmicat, 1, 2, 3, 4, 5, 6, .u), nol

safetab bmicat_sa, m
datacheck inlist(bmicat_sa, 1, 2, 3, 4, 5, 6, .u), nol

* IMD
summ imd
safetab imd, m
datacheck inlist(imd, 1, 2, 3, 4, 5), nol

* Ethnicity
safetab ethnicity
datacheck inlist(ethnicity, 1, 2, 3, 4, 5, 6), nol

safetab eth5,m
datacheck inlist(eth5, 1, 2, 3, 4, 5, 6), nol

safetab ethnicity_16,m
datacheck inlist(ethnicity_16, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17), nol

safetab eth16,m
datacheck inlist(eth16, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12), nol

* Smoking
datacheck inlist(smoke, 1, 2, 3, .u), nol
datacheck inlist(smoke_nomiss, 1, 2, 3), nol 


* Check date ranges for all variables - keep in mind they'll all be 15th of the month!

foreach var of varlist  *date {
	format `var' %d
	summ `var', format
}

**********************************
*  Distribution in whole cohort  *
**********************************

* Comorbidities
safetab bpcat
safetab bpcat, m
safetab htdiag_or_highbp
safetab chronic_respiratory_disease
safetab asthma
safetab chronic_cardiac_disease
safetab cancer
safetab chronic_liver_disease
safetab dm_type
*safetab immunosuppressed
safetab other_neuro
safetab dementia
safetab stroke
safetab egfr_cat
safetab egfr60
safetab esrf
safetab hypertension
safetab ra_sle_psoriasis
safetab stp
safetab region
safetab rural_urban


/* LOGICAL RELATIONSHIPS======================================================*/ 

*HH variables
summ hh_size hh_total

* BMI
bysort bmicat: summ bmi
bysort bmicat_sa: summ bmi

safetab bmicat obese4cat, m
safetab bmicat_sa obese4cat_sa, m

* Age
bysort agegroup: summ age

* Smoking
safetab smoke smoke_nomiss, m

* Diabetes
safetab dm_type
safetab dm_type_exeter_os
tab dm_type dm_type_exeter_os, row col

* CKD
safetab egfr60, m

/* EXPECTED RELATIONSHIPS WITH ETHNICITY =======================================*/ 

foreach var in $varlist {	
	safetab `var'
	safetab eth5 `var', row 
	safetab eth16 `var', row
}

/* AGE DISTRUBUTION OF HOUSEHOLDS=======================================================*/
bysort eth5: tab agegroup hh_total_cat, col

/* SENSE CHECK OUTCOMES=======================================================*/
foreach i of global outcomes {
		safetab `i'
		safetab eth5 `i', row
		safetab eth16 `i', row
		
		*proportion with diabetes who have the outcome x ethnicity
		bysort eth5:safetab  dm_type `i', col
		bysort eth16: safetab  dm_type `i', col
		
		*proportion of household size who have the outcome x ethnicity
		bysort eth5: safetab  hh_total_cat `i', col
		bysort eth16: safetab  hh_total_cat `i', col
}

* Close log file 
log close










*LEGACY CODE

*=================0 how many households in total, and how many have at least one case=============
tab hh_size
codebook hh_id /*5,295,872*/
*how many with no cases
*count houses with at least one case
gsort hh_id -case
generate atLeastone=.
by hh_id:replace atLeastone=1 if case[1]==1
replace atLeastone=0 if atLeastone==.
*drop duplicate hh_ids
preserve
	duplicates drop hh_id, force
	count
	tab atLeastone
	tab hh_size atLeastone
restore



*=======================1 descriptive histograms as per meeting on Fri 28th=======================
/*
Outputs discussed:
1. Histograms of distribution of secondary cases over time by each household size
2. Overall and by 2 time periods: March 1 - End April, April 1 - current date (i.e. change in policy, moving from pillar 1 to pillar 2)
3. Then summarise these by ethnicity

*/

*========================PROGRAMS=====================================

*program that outputs histogram with bins that represent less than 5 people redacted, takes household size as a parameter, saves with title as household size
program redactedTimeSeriesHist
	hist `1' if hh_size==`2', width(5) frequency tlabel(01feb2020 01apr2020 01jun2020 01aug2020, format(%tdmd))
	*serset command loads the data underlying the graph into memory
	serset use, clear
	generate cases=__000000
	generate case_date=__000002
	format case_date %td
	expand cases
	sort case_date
	drop if cases<5
	drop if cases==.
	count
	hist `1', width(5) frequency tlabel(01feb2020 01apr2020 01jun2020 01aug2020, format(%tdmd)) saving(`1', replace) title (Household size: `1', size (medium)) subtitle(n=`r(N)', size (medium))
	*check no bins under 5
	serset use, clear
	list 
end



****************(a) Set 1 of histograms: case date (time series) by household size across the entire time period***************
use hh_analysis_dataset.dta, clear

*keep only cases for this descriptive analysis
keep if case==1
*drop cases that are dates prior to Feb012020
drop if case_date<date("20200201", "YMD")

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	use `forHistOutput', clear
	
	*call redactedHist program
	redactedTimeSeriesHist case_date `l'
}
gr combine 2.gph 3.gph 4.gph 5.gph 
gr export caseDistByHHSizes2-5.pdf, replace
gr combine 6.gph 7.gph 8.gph 9.gph 
gr export caseDistByHHSizes6-9.pdf, replace




******************(b) Set 2 of histograms: distribution of total number of cases by household size, by ethnicity to start with******************
program redactedHHCasesHistByEthnicity
	if `3'==1  { 
		local ethnicity="White"
	}
	else if `3'==2  { 
		local ethnicity="South_Asian"
	}
	else if `3'==3  { 
		local ethnicity="Black"
	}
	hist `1' if hh_size==`2' & eth5==`3', frequency addlabels discrete xlabel(1(1)`2') title (Household size: `2', size (medium)) subtitle(`ethnicity', size (medium)) saving(`2'_`ethnicity', replace)
	*serset command loads the data underlying the graph into memory
	serset use, clear
	generate freq=__000000
	generate totCasesInHH=__000002
	drop if totCasesInHH<1
	expand freq
	sort totCasesInHH
	drop if freq<5
	hist `1', frequency addlabels discrete xlabel(1(1)`2') title (Household size: `2', size (medium)) subtitle(`ethnicity', size (medium)) saving(`2'_`ethnicity', replace)
	*check no bins under 5
	serset use, clear
	list 
end

/*
e.g. in a household size of 4, how many houses had 1 case, how many had 2, how many had 3, how many had 4
-so instead of case_date as the parameter, I want number of cases in the household
*/ 
use hh_analysis_dataset.dta, clear

*keep only cases for this descriptive analysis
keep if case==1
*drop cases that are dates prior to Feb012020
drop if case_date<date("20200201", "YMD")

*first of all, create a number of cases in the household variable
bysort hh_id:egen totCasesInHH=total(case)

redactedHHCasesHistByEthnicity totCasesInHH 4 1


*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
use hh_analysis_dataset.dta, clear

*keep only cases for this descriptive analysis
keep if case==1
*drop cases that are dates prior to Feb012020
drop if case_date<date("20200201", "YMD")

*first of all, create a number of cases in the household variable
bysort hh_id:egen totCasesInHH=total(case)

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 1	/*white*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 2   /*south asian*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 3	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph
	gr export totCasesinHHsize`l'ByEthnicity.pdf, replace
}




**************repeat above by IMD broad categories*******************
*=========LESS DEPRIVED IMD===============
*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
use hh_analysis_dataset.dta, clear
numlabel, add

*keep only cases for this descriptive analysis
keep if case==1
*drop cases that are dates prior to Feb012020
drop if case_date<date("20200201", "YMD")

*keep only the more well off househholds
tab imdBroad
keep if imdBroad==1

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 1	/*white*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 2   /*south asian*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 3	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (Less deprived)
	gr export totCasesinHHsize`l'ByEthnicity_LessDeprived.pdf, replace
}




*=========MORE DEPRIVED IMD===============
*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
use hh_analysis_dataset.dta, clear
numlabel, add

*keep only cases for this descriptive analysis
keep if case==1
*drop cases that are dates prior to Feb012020
drop if case_date<date("20200201", "YMD")

*keep only the more well off househholds
tab imdBroad
keep if imdBroad==2

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 1	/*white*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 2   /*south asian*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 3	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (More deprived)
	gr export totCasesinHHsize`l'ByEthnicity_MoreDeprived.pdf, replace
}






**************repeat above by rural urban broad categories*******************
*=========RURAL LOCATION===============
*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
use hh_analysis_dataset.dta, clear
numlabel, add

*keep only cases for this descriptive analysis
keep if case==1
*drop cases that are dates prior to Feb012020
drop if case_date<date("20200201", "YMD")

*keep only the more well off househholds
tab rural_urbanBroad
keep if rural_urbanBroad==0

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 1	/*white*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 2   /*south asian*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 3	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (Rural)
	gr export totCasesinHHsize`l'ByEthnicity_Rural.pdf, replace
}




*=========URBAN LOCATION===============
*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
use hh_analysis_dataset.dta, clear
numlabel, add

*keep only cases for this descriptive analysis
keep if case==1
*drop cases that are dates prior to Feb012020
drop if case_date<date("20200201", "YMD")

*keep only the more well off househholds
tab rural_urbanBroad
keep if rural_urbanBroad==1

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 1	/*white*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 2   /*south asian*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 3	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (Urban)
	gr export totCasesinHHsize`l'ByEthnicity_Urban.pdf, replace
}














/* legacy code
* Open a log file

cap log close
log using "02_an_data_checks", replace t

*capture log close
*log using "$Logdir/02_an_data_checks", replace t

numlabel, add

* Open Stata dataset
*use "$Tempdir/analysis_dataset.dta", clear


*Duplicate patient check
datacheck _n==1, bysort(patient_id) nol


/* CHECK INCLUSION AND EXCLUSION CRITERIA=====================================*/ 

* DATA STRUCTURE: Confirm one row per patient 
duplicates tag patient_id, generate(dup_check)
cap assert dup_check == 0 
drop dup_check

* INCLUSION 1: <=110 at 1 Feb 2020 
cap assert age < .
cap assert age <= 110
 
* INCLUSION 2: M or F gender at 1 Feb 2020 
cap assert inlist(sex, "M", "F")

* EXCLUDE 1:  MISSING IMD
cap assert inlist(imd, 1, 2, 3, 4, 5)


/* EXPECTED VALUES============================================================*/ 

*HH
summ hh_size hh_linear hh_log_linea
safetab hh_total_cat, m

*Care home
safetab carehome, m
safetab carehome hh_total_cat, m

* Age
summ age
datacheck age<., nol
datacheck inlist(agegroup, 1, 2, 3, 4, 5, 6, 7), nol

* Sex
safetab male, m
datacheck inlist(male, 0, 1), nol

* BMI 
summ bmi
safetab obese4cat, m 
datacheck inlist(obese4cat, 1, 2, 3, 4), nol

safetab obese4cat_sa, m
datacheck inlist(obese4cat_sa, 1, 2, 3, 4), nol

safetab bmicat, m
datacheck inlist(bmicat, 1, 2, 3, 4, 5, 6, .u), nol

safetab bmicat_sa, m
datacheck inlist(bmicat_sa, 1, 2, 3, 4, 5, 6, .u), nol

* IMD
summ imd
safetab imd, m
datacheck inlist(imd, 1, 2, 3, 4, 5), nol

* Ethnicity
safetab ethnicity
datacheck inlist(ethnicity, 1, 2, 3, 4, 5, 6), nol

safetab eth5,m
datacheck inlist(eth5, 1, 2, 3, 4, 5, 6), nol

safetab ethnicity_16,m
datacheck inlist(ethnicity_16, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17), nol

safetab eth16,m
datacheck inlist(eth16, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12), nol

* Smoking
datacheck inlist(smoke, 1, 2, 3, .u), nol
datacheck inlist(smoke_nomiss, 1, 2, 3), nol 


* Check date ranges for all variables - keep in mind they'll all be 15th of the month!

foreach var of varlist  *date {
	format `var' %d
	summ `var', format
}

**********************************
*  Distribution in whole cohort  *
**********************************

* Comorbidities
safetab bpcat
safetab bpcat, m
safetab htdiag_or_highbp
safetab chronic_respiratory_disease
safetab asthma
safetab chronic_cardiac_disease
safetab cancer
safetab chronic_liver_disease
safetab dm_type
*safetab immunosuppressed
safetab other_neuro
safetab dementia
safetab stroke
safetab egfr_cat
safetab egfr60
safetab esrf
safetab hypertension
safetab ra_sle_psoriasis
safetab stp
safetab region
safetab rural_urban


/* LOGICAL RELATIONSHIPS======================================================*/ 

*HH variables
summ hh_size hh_total

* BMI
bysort bmicat: summ bmi
bysort bmicat_sa: summ bmi

safetab bmicat obese4cat, m
safetab bmicat_sa obese4cat_sa, m

* Age
bysort agegroup: summ age

* Smoking
safetab smoke smoke_nomiss, m

* Diabetes
safetab dm_type
safetab dm_type_exeter_os
tab dm_type dm_type_exeter_os, row col

* CKD
safetab egfr60, m

/* EXPECTED RELATIONSHIPS WITH ETHNICITY =======================================*/ 

foreach var in $varlist {	
	safetab `var'
	safetab eth5 `var', row 
	safetab eth16 `var', row
}

/* AGE DISTRUBUTION OF HOUSEHOLDS=======================================================*/
bysort eth5: tab agegroup hh_total_cat, col

/* SENSE CHECK OUTCOMES=======================================================*/
foreach i of global outcomes {
		safetab `i'
		safetab eth5 `i', row
		safetab eth16 `i', row
		
		*proportion with diabetes who have the outcome x ethnicity
		bysort eth5:safetab  dm_type `i', col
		bysort eth16: safetab  dm_type `i', col
		
		*proportion of household size who have the outcome x ethnicity
		bysort eth5: safetab  hh_total_cat `i', col
		bysort eth16: safetab  hh_total_cat `i', col
}

* Close log file 
log close
