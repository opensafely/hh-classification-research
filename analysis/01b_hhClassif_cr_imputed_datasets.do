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



foreach outcome in covidHospOrDeath {
	*log file
	cap log close
	log using "./logs/01b_hhClassif_imputed_datasets_`dataset'", text replace
	* Open Stata dataset
	use ./output/hhClassif_analysis_dataset_with_missing_ethnicity_ageband_3`dataset'.dta, clear
	encode utla_group, generate(utla_group2)
	*********code for dummy data only!!********
	replace eth5=6 if eth5==4
	*******************************************

	*mi set the data
	mi set mlong

	*mi register 
	tab eth5
	replace eth5=. if eth5==6 //set unknown to missing - need to check if this will work as I dropped all records with missing ethnicity!
	mi register imputed eth5

	*mi impute the dataset - need to edit this list based upon variables, going to leave hh_id out for now but might want to include?
	noisily mi impute mlogit eth5 i.`outcome'Case i.imd ///
											i.smoke ///
											i.obese4cat ///
											i.rural_urbanFive ///
											i.ageCatfor67Plus ///
											i.male ///
											i.coMorbCat ///
											i.region, /// 
											add(10) rseed(70548) augment force
											

											
	*mi stset - need to check this code is the same as my source file
	mi stset stime_`outcome'Case, fail(`outcome'Case) id(patient_id) enter(enter_date) origin(enter_date)
	save ./output/hhClassif_analysis_dataset_eth5_mi_ageband_3_STSET_`outcome'_`dataset'.dta, replace	
}
 

log close



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
