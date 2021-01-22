/*==============================================================================
DO FILE NAME:			02_an_data_checks
PROJECT:				Ethnicity and COVID
AUTHOR:					K Wing adapted from Rohini Mathur, H Forbes, A Wong, A Schultze, C Rentsch
						 K Baskharan, E Williamson
DATE: 					25th August 2020
DESCRIPTION OF FILE:	Run sanity checks on all variables
							- Check variables take expected ranges 
							- Cross-check logical relationships 
							- Explore expected relationships 
							- Check stsettings 
							- KW added: plots histograms of distribution of cases over time by household size
DATASETS USED:			$tempdir\`analysis_dataset'.dta
DATASETS CREATED: 		None
OTHER OUTPUT: 			Log file: $logdir\02_an_data_checks

cd ${outputData}
clear all
use hh_analysis_dataset_DRAFT.dta, clear
							
==============================================================================*/
cd ${outputData}
clear all


* Open a log file
cap log close
log using "02_an_data_checks", replace t

use hh_analysis_dataset.dta, clear


*how many households in total, and how many have at least one case
*have a quick look at the data
*how many households
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
restore



* Open a log file

cap log close
log using "02_an_data_checks", replace t

*capture log close
*log using "$Logdir/02_an_data_checks", replace t
*add numeric values to all labels
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
*summ hh_size hh_linear hh_log_linea
summ hh_size
safetab hh_size, m

*Care home
*safetab carehome, m
*safetab carehome hh_total_cat, m

* Age
summ age
datacheck age<., nol
datacheck inlist(ageCat, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12), nol

* Sex
safetab sex, m
datacheck inlist(sex, 0, 1), nol

* BMI 
*summ bmi
*safetab obese4cat, m 
*datacheck inlist(obese4cat, 1, 2, 3, 4), nol

*safetab obese4cat_sa, m
*datacheck inlist(obese4cat_sa, 1, 2, 3, 4), nol

safetab bmicat, m
datacheck inlist(bmicat, 1, 2, 3, 4, 5, 6, .u), nol

*safetab bmicat_sa, m
*datacheck inlist(bmicat_sa, 1, 2, 3, 4, 5, 6, .u), nol

* IMD
summ imd
safetab imd, m
datacheck inlist(imd, 1, 2, 3, 4, 5), nol

* Ethnicity
safetab ethnicity
datacheck inlist(ethnicity, 1, 2, 3, 4, 5, 6), nol

safetab eth5, m
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
*safetab bpcat
*safetab bpcat, m
*safetab htdiag_or_highbp
safetab chronic_respiratory_disease
*safetab asthma
safetab chronic_cardiac_disease
safetab cancer
safetab chronic_liver_disease
*safetab dm_type
*safetab immunosuppressed
*safetab other_neuro
*safetab dementia
*safetab stroke
safetab comorb_Neuro
safetab comorb_Immunosuppression
safetab egfr_cat
*safetab egfr60
*safetab esrf
safetab hypertension
*safetab ra_sle_psoriasis
*safetab stp
safetab region
safetab rural_urban


/* LOGICAL RELATIONSHIPS======================================================*/ 

*HH variables
summ hh_size
summ hh_composition

* BMI
bysort bmicat: summ bmi
bysort bmicat_sa: summ bmi

safetab bmicat obese4cat, m
safetab bmicat_sa obese4cat_sa, m

* Age
bysort ageCat: summ age

* Smoking
safetab smoke smoke_nomiss, m

* Diabetes
*safetab dm_type
*safetab dm_type_exeter_os
*tab dm_type dm_type_exeter_os, row col

* CKD
*safetab egfr60, m

/* EXPECTED RELATIONSHIPS WITH ETHNICITY =======================================*/ 

foreach var in $varlist {	
	safetab `var'
	safetab eth5 `var', row 
	safetab eth16 `var', row
}

/* AGE DISTRUBUTION OF HOUSEHOLDS=======================================================*/
bysort eth5: tab ageCat hh_size, col

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
