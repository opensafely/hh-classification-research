/*==============================================================================
DO FILE NAME:			08b_eth_cr_imputed_eth5
PROJECT:				NSAID in COVID-19 
AUTHOR:					R Mathur (modified from A wong and A Schultze)
DATE: 					15 July 2020					
DESCRIPTION OF FILE:	program 07
						univariable regression using multiple imputation for ethnicity
						multivariable regression using multiple imputation for ethnicity
DATASETS USED:			data in memory ($tempdir/analysis_dataset_STSET_outcome)
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir
						table2_eth5_mi, printed to analysis/$outdir
						
https://stats.idre.ucla.edu/stata/seminars/mi_in_stata_pt1_new/						
							
==============================================================================*/

local dataset `1' 


*log file
cap log close
log using "./logs/01b_hhClassif_imputed_datasets_`dataset'", text replace
* Open Stata dataset
use ./output/hhClassif_analysis_dataset_with_missing_ethnicity_ageband_3`dataset'.dta, clear
encode utla_group, generate(utla_group2)

*mi set the data
mi set mlong

*mi register 
tab eth5
replace eth5=. if eth5==6 //set unknown to missing - need to check if this will work as I dropped all records with missing ethnicity!
tab eth5, miss
mi register imputed eth5

*test code - works!
*noisily mi impute mlogit eth5, add(10) rseed(70548) augment force by(male coMorbCat) nolog 	

*mi impute the dataset - need to edit this list based upon variables, testing 3 iterations for now, want to increase this to 5 once I know it works on the server
capture noisily mi impute mlogit eth5 i.covidHospOrDeathCase, add(10) rseed(70548) augment force by(hhRiskCat67PLUS_5cats imd smoke obese4cat rural_urbanFive ageCatfor67Plus male coMorbCat)
										
*mi stset - need to check this code is the same as my source file
mi stset stime_covidHospOrDeathCaseCase, fail(covidHospOrDeathCaseCase) id(patient_id) enter(enter_date) origin(enter_date)
save ./output/hhClassif_analysis_dataset_eth5_mi_ageband_3_STSET_`outcome'_`dataset'.dta, replace	


*i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth


*SOURCE CODE FROM ROHINI:

/*
* Open a log file
cap log close
macro drop hr
estimates clear
log using $logdir\08b_eth_cr_imputed_mi_eth5, replace text


foreach i of global outcomes {
* Open Stata dataset
use "$Tempdir/analysis_dataset_STSET_`i'.dta", clear

*mi set the data
mi set mlong

*mi register 
replace eth5=. if eth5==6 //set unknown to missing
mi register imputed eth5

*mi impute the dataset - remove variables with missing values - bmi	hba1c_pct bp_map 
noisily mi impute mlogit eth5 `i' i.stp i.male age1 age2 age3 	i.imd						///
										i.bmicat_sa	i.hba1ccat			///
										gp_consult_count			///
										i.smoke_nomiss				///
										i.hypertension i.bp_cat	 	///	
										i.asthma					///
										i.chronic_respiratory_disease ///
										i.chronic_cardiac_disease	///
										i.dm_type 					///	
										i.cancer                    ///
										i.chronic_liver_disease		///
										i.stroke					///
										i.dementia					///
										i.other_neuro				///
										i.egfr60					///
										i.esrf						///
										i.immunosuppressed	 		///
										i.ra_sle_psoriasis			///
										i.hh_total_cat, ///
										add(10) rseed(70548) augment force // can maybe remove the force option in the server
										

*mi stset
mi	stset stime_`i', fail(`i') 	id(patient_id) enter(indexdate) origin(indexdate)
save "$Tempdir/analysis_dataset_STSET_`i'_eth5_mi.dta", replace
}
 

log close
*/
