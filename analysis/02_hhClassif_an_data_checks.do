/*==============================================================================
DO FILE NAME:			02_hhClassif_an_data_checks
PROJECT:				HH COVID risk classification
AUTHOR:					K Wing adapted from H Forbes,  A Wong, A Schultze, C Rentsch
						 K Baskharan, E Williamson
DATE: 					26 Jan 2021 
DESCRIPTION OF FILE:	Run sanity checks on all variables
							- Check variables take expected ranges 
							- Cross-check logical relationships 
							- Explore expected relationships 
							- Check stsettings 
DATASETS USED:			./output/hhClassif_analysis_dataset.dta
DATASETS CREATED: 		None
OTHER OUTPUT: 			Log file: ./released_outputs/02_hhClassif_an_data_checks.log  
							
==============================================================================*/
sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles


*first argument main W2 
local dataset `1'
if "`dataset'"=="MAIN" local fileextension
else local fileextension "_`1'"
local inputfile "hhClassif_analysis_dataset`dataset'"

* Open a log file

capture log close
log using ./logs/02_hhClassif_an_data_checks`fileextension', replace t

* Open Stata dataset
use ./output/`inputfile', clear

/*
* Open a log file
capture log close
log using ./released_outputs/02_hhClassif_an_data_checks.log, replace t

* Open Stata dataset
use ./output/hhClassif_analysis_dataset.dta, clear
*/

*run ssc install if not on local machine - server needs datacheck.ado file
*ssc install datacheck 

*Duplicate patient check
datacheck _n==1, by(patient_id) nol


/* CHECK INCLUSION AND EXCLUSION CRITERIA=====================================*/ 

* DATA STRUCTURE: Confirm one row per patient 
duplicates tag patient_id, generate(dup_check)
assert dup_check == 0 
drop dup_check

* INCLUSION 1: >=18 and <=110 at 1 March 2020 
assert age < .
assert age >= 18
assert age <= 110
 
* INCLUSION 2: M or F gender at 1 March 2020 
assert inlist(male, 0, 1)

* EXCLUDE 1:  MISSING IMD
assert inlist(imd, 1, 2, 3, 4, 5, .u)

* EXCLUDE 2:  HH with more than 12 people
datacheck inlist(hh_size, 1, 2, 3, 4, 5,6, 7, 8, 9, 10, 11, 12 .u), nol

/* EXPECTED VALUES============================================================*/ 

*HH composition variables
*hhRiskCat (the generic starting variable)
datacheck hhRiskCat<., nol
datacheck inlist(hhRiskCat, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14), nol
*hhRiskCatExp_5cats
datacheck hhRiskCatExp_5cats<., nol
datacheck inlist(hhRiskCat, 1, 2, 3, 4, 5), nol


* Age
datacheck age<., nol
datacheck inlist(ageCatHHRisk, 0, 1, 2, 3), nol

* Sex
datacheck inlist(male, 0, 1), nol

* BMI 
datacheck inlist(obese4cat, 1, 2, 3, 4), nol
datacheck inlist(bmicat, 1, 2, 3, 4, 5, 6, .u), nol

* IMD
datacheck inlist(imd, 1, 2, 3, 4, 5, .u), nol

* Ethnicity
*eth5
datacheck inlist(eth5, 1, 2, 3, 4, 5, .), nol
*eth16
datacheck inlist(eth5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, .), nol

* Smoking
datacheck inlist(smoke, 1, 2, 3, 4), nol
datacheck inlist(smoke, 1, 2, 3), nol 


foreach comorb in $varlist { 

	local comorb: subinstr local comorb "i." ""
	safetab `comorb', m
	
}

*summarise end dates for each outcome
foreach outcome in covidDeathCase covidHospCase nonCOVIDDeathCase	 {
sum `outcome', format
}

foreach outcome in covidDeathCase covidHospCase nonCOVIDDeathCase	 {
gen `outcome'_month=mofd(`outcome') 
 lab define `outcome'_month 721 feb 722 mar 723 apr 724 may 725 june 726 jul 727 aug 728 sept 729 oct
lab val `outcome'_month `outcome'_month
tab `outcome'_month
drop `outcome'_month
}

*Outcome dates
di d(1feb2020)
* 21946
di d(01apr2020)
* 22006
di d(01june2020)
* 22067
di d(01aug2020)
* 22128
di d(01oct2020)
* 22189

foreach outcome of any covidDeathCase covidHospCase nonCOVIDDeathCase    {
summ  `outcome', format d 
summ patient_id if `outcome'==1
local total_`outcome'=`r(N)'
hist `outcome'Date, saving(`outcome', replace) ///
xlabel(21946 22006 22067 22128 22189,labsize(tiny))  xtitle(, size(vsmall)) ///
graphregion(color(white))  legend(off) freq  ///
yscale(range(0 3000)) ylab(0 (500) 6000, labsize(vsmall)) ytitle("Number", size(vsmall))  ///
title("N=`total_`outcome''", size(vsmall)) 
}
* Combine histograms
graph combine covidDeathCase.gph covidHospCase.gph nonCOVIDDeathCase.gph, graphregion(color(white))
erase covidDeathCase.gph 
erase covidHospCase.gph 
erase nonCOVIDDeathCase.gph
graph export ./output/01_histogram_outcomes.svg, as(svg) replace 

*censor dates
summ study_end_censor, format



/* LOGICAL RELATIONSHIPS======================================================*/ 

*HH variables
safetab hhRiskCat hh_total_cat
safetab hhRiskCatExp_5cats hh_total_cat


* BMI
bysort bmicat: summ bmi
safetab bmicat obese4cat, m

* Age
*bysort ageCatHHRisk: summ age
*safetab ageCatHHRisk age66, m

* Smoking
safetab smoke, m

* Diabetes
*safetab diabcat diabetes, m

* CKD
*safetab reduced egfr_cat, m
* CKD
*safetab reduced esrd, m

*comorbidities
safetab coMorbCat

/* EXPECTED RELATIONSHIPS=====================================================*/ 

/*  Relationships between demographic/lifestyle variables  */
safetab ageCatHHRisk bmicat, 	row 
safetab ageCatHHRisk smoke, 	row  
safetab ageCatHHRisk ethnicity, row 
safetab ageCatHHRisk imd, 		row 
*safetab ageCatHHRisk shield,    row 

safetab bmicat smoke, 		 row   
safetab bmicat ethnicity, 	 row 
safetab bmicat imd, 	 	 row 
safetab bmicat hypertension, row 
*safetab bmicat shield,    row 

                            
safetab smoke ethnicity, 	row 
safetab smoke imd, 			row 
safetab smoke hypertension, row 
*safetab smoke shield,    row 
                      
safetab ethnicity imd, 		row 
*safetab shield imd, 		row 

*safetab shield ethnicity, 		row 



* Relationships with age
foreach var of varlist 								///
					chronic_respiratory_disease 	///
					asthma_severe	///
					chronic_cardiac_disease  		///
					dm  			///
					cancer_nonhaemPrevYear ///
					cancer_haemPrev5Years				///
					chronic_liver_disease  ///
					stroke_dementia  ///
					egfr60  			/// 
					organ_transplant  			/// 
					asplenia			 	///
					other_immuno			 	///	 	
										{

		
 	safetab ageCatHHRisk `var', row 
 }


*Relationships with sex
foreach var of varlist 						///
					chronic_respiratory_disease 	///
					asthma_severe	///
					chronic_cardiac_disease  		///
					dm  			///
					cancer_nonhaemPrevYear ///
					cancer_haemPrev5Years				///
					chronic_liver_disease  ///
					stroke_dementia  ///
					egfr60  			/// 
					organ_transplant  			/// 
					asplenia			 	///
					other_immuno			 	///	
										{
						
 	safetab male `var', row 
}

*Relationships with smoking							
foreach var of varlist  							///
					chronic_respiratory_disease 	///
					asthma_severe	///
					chronic_cardiac_disease  		///
					dm  			///
					cancer_nonhaemPrevYear ///
					cancer_haemPrev5Years				///
					chronic_liver_disease  ///
					stroke_dementia  ///
					egfr60  			/// 
					organ_transplant  			/// 
					asplenia			 	///
					other_immuno			 	///
					{
	
 	safetab smoke `var', row 
}


/* SENSE CHECK OUTCOMES=======================================================*/
safetab covidDeathCase covidHospCase  , row col
safetab covidDeathCase nonCOVIDDeathCase  , row col
safetab nonCOVIDDeathCase covidHospCase  , row col

safecount if covidHospCase==1 & covidDeathCase==1
safecount if covidDeathCase==1 & nonCOVIDDeathCase==1
safecount if covidHospCase==1 & nonCOVIDDeathCase==1

* Close log file 
log close


