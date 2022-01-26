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

*create a two category obesity category to see if imputation works with this
tab obese4cat
tab obese4cat, nolabel
generate obese2cat=obese4cat
recode obese2cat 3=2 4=2
tab obese4cat obese2cat
la var obese2cat "obesity in 2 categories"
label define obese2cat 	1 "Non-obese" 2 "Obese"
label values obese2cat obese2cat
tab obese2cat,m

*create a binary age group as convergence failed when age was in four groups
tab ageCatfor67Plus
tab ageCatfor67Plus, nolabel
generate ageCatfor67PlusTWOCATS=ageCatfor67Plus
recode ageCatfor67PlusTWOCATS 0=1 3=2 4=2
label define ageCatfor67PlusTWOCATS 1 "67-74" 2 "75+"
label values ageCatfor67PlusTWOCATS ageCatfor67PlusTWOCATS
tab ageCatfor67PlusTWOCATS ageCatfor67Plus


*mi set the data
mi set mlong

*mi register 
tab eth5
replace eth5=. if eth5==6 //set unknown to missing - need to check if this will work as I dropped all records with missing ethnicity!
tab eth5, miss
mi register imputed eth5

*test code - works!
*noisily mi impute mlogit eth5, add(10) rseed(70548) augment force by(male coMorbCat) nolog 

*capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.ageCatfor67Plus##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive i.smoke i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)	

*mi impute the dataset - need to edit this list based upon variables, testing 3 iterations for now, want to increase this to 5 once I know it works on the server
noisily mi impute mlogit eth5 i.covidHospOrDeathCase i.rural_urbanFive i.smoke i.male i.coMorbCat, add(10) rseed(70548) augment force by(hhRiskCat67PLUS_5cats imd obese2cat ageCatfor67PlusTWOCATS)
		
*save imputed raw data
save ./output/hhClassif_analysis_dataset_eth5_mi_ageband_3_`dataset'.dta, replace		
		
*mi stset - need to check this code is the same as my source file
*for reference from source file: stset stime_covidHospOrDeathCase, fail(covidHospOrDeathCase) id(patient_id) enter(enter_date) origin(enter_date)
mi stset stime_covidHospOrDeathCase, fail(covidHospOrDeathCase) id(patient_id) enter(enter_date) origin(enter_date)
save ./output/hhClassif_analysis_dataset_eth5_mi_ageband_3_STSET_covidHospOrDeathCase_`dataset'.dta, replace
tab _mi_m	


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
