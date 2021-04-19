********************************************************************************
*
*	Do-file:		05_hhClassif_an_univariable_analysis.do
*	Project:		hh risk classification
*	Programmed by:	K Wing, based on files from Hforbes, Fizz & Krishnan
*	Data used:		analysis_dataset.dta
*	Data created:	None
*	Other output:	Log file: 04_hhClassif_an_multivariable_analysis_`dataset'.log 
*
********************************************************************************
*

*  
********************************************************************************


* Set globals that will print in programs and direct output
*global outdir  	  "output" 
*global logdir     "log"
*global tempdir    "tempdata"

local dataset `1'

*list of demographic variables for adjustment: age (spline), sex, BMI, smoking, density of housing, geographic area (already taken account of in stratified analysis)
global demogadjlist age1 age2 age3 i.male i.obese4cat i.smoke_nomiss i.rural_urbanFive
*list of comorbidities for adjustment
global comorbidadjlist i.coMorbCat	

/*
local outcome `1' 
local dataset `2'
*/

************************************************************************************
*First clean up all old saved estimates for this outcome
*This is to guard against accidentally displaying left-behind results from old runs
************************************************************************************

* Open a log file
capture log close
log using ./logs/05_hhClassif_an_multivariable_analysis_`dataset', replace t


* Open dataset and fit specified model(s)
*(a) Multivariable not stratified by anything, not adjusted for ses or ethnicity
foreach outcome in covidDeath covidHosp nonCovidDeath {
*2 and 3 here are the two age categories I've created so far, need to change these when there are more
	forvalues x=2/3 {

	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_`x'`dataset'.dta, clear

		*Fit and save model
		cap erase ./output/an_multivariable_cox_models_`outcome'_AGESEX_ageband_`x'`dataset'.ster
		display "***********Outcome: `outcome', ageband: `x', dataset: `dataset'*************************"
		stcox i.hhRiskCatExp $demogadjlist $comorbidadjlist, strata(utla_group) vce(cluster hh_id)
		if _rc==0 {
			estimates
			estimates save ./output/an_multivariable_cox_models_`outcome'_AGESEX_ageband_`x'`dataset'.ster, replace
			}
		else di "WARNING - `var' vs `outcome' MODEL DID NOT SUCCESSFULLY FIT"*/
	}
}


*(b) Multivariable, stratified by ethnicity and including adjustment for SES
foreach outcome in covidDeath covidHosp nonCovidDeath {
*2 and 3 here are the two age categories I've created so far, need to change these when there are more
	forvalues x=2/3 {

	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_`x'`dataset'.dta, clear

		*Fit and save model
		cap erase ./output/an_multivariable_cox_models_`outcome'_AGESEX_ageband_`x'`dataset'_eth5Interaction.ster
		display "***********Outcome: `outcome', ageband: `x', dataset: `dataset' - stratified by ethnicity and adjusted for imd*************************"
		stcox i.hhRiskCatExp##i.eth5 $demogadjlist $comorbidadjlist i.imd, strata(utla_group) vce(cluster hh_id)
		
				*output HRs for each level of strata
		lincom 1.hhRiskCatExp + 1*1.hhRiskCatExp#eth5
		lincom 1.hhRiskCatExp + 2*1.hhRiskCatExp#eth5
		lincom 1.hhRiskCatExp + 3*1.hhRiskCatExp#eth5
		lincom 1.hhRiskCatExp + 4*1.hhRiskCatExp#eth5
		lincom 1.hhRiskCatExp + 5*1.hhRiskCatExp#eth5
		
		lincom 2.hhRiskCatExp + 1*2.hhRiskCatExp#eth5
		lincom 2.hhRiskCatExp + 2*2.hhRiskCatExp#eth5
		lincom 2.hhRiskCatExp + 3*2.hhRiskCatExp#eth5
		lincom 2.hhRiskCatExp + 4*2.hhRiskCatExp#eth5
		lincom 2.hhRiskCatExp + 5*2.hhRiskCatExp#eth5
		
		lincom 3.hhRiskCatExp + 1*3.hhRiskCatExp#eth5
		lincom 3.hhRiskCatExp + 2*3.hhRiskCatExp#eth5
		lincom 3.hhRiskCatExp + 3*3.hhRiskCatExp#eth5
		lincom 3.hhRiskCatExp + 4*3.hhRiskCatExp#eth5
		lincom 3.hhRiskCatExp + 5*3.hhRiskCatExp#eth5
		
		lincom 4.hhRiskCatExp + 1*4.hhRiskCatExp#eth5
		lincom 4.hhRiskCatExp + 2*4.hhRiskCatExp#eth5
		lincom 4.hhRiskCatExp + 3*4.hhRiskCatExp#eth5
		lincom 4.hhRiskCatExp + 4*4.hhRiskCatExp#eth5
		lincom 4.hhRiskCatExp + 5*4.hhRiskCatExp#eth5
		
		lincom 5.hhRiskCatExp + 1*5.hhRiskCatExp#eth5
		lincom 5.hhRiskCatExp + 2*5.hhRiskCatExp#eth5
		lincom 5.hhRiskCatExp + 3*5.hhRiskCatExp#eth5
		lincom 5.hhRiskCatExp + 4*5.hhRiskCatExp#eth5
		lincom 5.hhRiskCatExp + 5*5.hhRiskCatExp#eth5
		
		lincom 6.hhRiskCatExp + 1*6.hhRiskCatExp#eth5
		lincom 6.hhRiskCatExp + 2*6.hhRiskCatExp#eth5
		lincom 6.hhRiskCatExp + 3*6.hhRiskCatExp#eth5
		lincom 6.hhRiskCatExp + 4*6.hhRiskCatExp#eth5
		lincom 6.hhRiskCatExp + 5*6.hhRiskCatExp#eth5
		
		lincom 7.hhRiskCatExp + 1*7.hhRiskCatExp#eth5
		lincom 7.hhRiskCatExp + 2*7.hhRiskCatExp#eth5
		lincom 7.hhRiskCatExp + 3*7.hhRiskCatExp#eth5
		lincom 7.hhRiskCatExp + 4*7.hhRiskCatExp#eth5
		lincom 7.hhRiskCatExp + 5*7.hhRiskCatExp#eth5
		
		lincom 8.hhRiskCatExp + 1*8.hhRiskCatExp#eth5
		lincom 8.hhRiskCatExp + 2*8.hhRiskCatExp#eth5
		lincom 8.hhRiskCatExp + 3*8.hhRiskCatExp#eth5
		lincom 8.hhRiskCatExp + 4*8.hhRiskCatExp#eth5
		lincom 8.hhRiskCatExp + 5*8.hhRiskCatExp#eth5
		
		if _rc==0 {
			estimates
			estimates save ./output/an_multivariable_cox_models_`outcome'_AGESEX_ageband_`x'`dataset'_eth5Interaction.ster, replace
			}
		else di "WARNING - `var' vs `outcome' MODEL DID NOT SUCCESSFULLY FIT"
		

	}
}
* Close log file
log close
















*Harriet code
/*
*************************************************************************************
*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basecoxmodel
prog define basecoxmodel
	syntax , exposure(string) age(string) 

timer clear
timer on 1
	capture stcox 	`exposure' 				///
			$demogadjlist	 			  	///
			$comorbidadjlist				///
			`if'							///
			, strata(stp) vce(cluster household_id)
timer off 1
timer list
end
*************************************************************************************


* Open dataset and fit specified model(s)
forvalues x=0/1 {

use "$tempdir/cr_create_analysis_dataset_STSET_`outcome'_ageband_`x'`dataset'.dta", clear

******************************
*  Multivariable Cox models  *
******************************



foreach exposure_type in kids_cat4  {

*Age spline model (not adj ethnicity)
cap erase "./output/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_ageband_`x'`dataset'"
basecoxmodel, exposure("i.`exposure_type'") age("age1 age2 age3") 
if _rc==0{
estimates
estimates save "./output/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_ageband_`x'`dataset'", replace
	*  Proportional Hazards test 
	* Based on Schoenfeld residuals
	timer clear 
	timer on 1
	if e(N_fail)>0 estat phtest, d
	timer off 1
	timer list 
	
}
else di "WARNING AGE SPLINE MODEL DID NOT FIT (OUTCOME `outcome')"

}

foreach exposure_type in  gp_number_kids {
*Age spline model (not adj ethnicity)
cap erase "./output/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_ageband_`x'`dataset'"
basecoxmodel, exposure("i.`exposure_type'") age("age1 age2 age3") 
if _rc==0{
estimates
estimates save "./output/an_multivariate_cox_models_`outcome'_`exposure_type'_MAINFULLYADJMODEL_ageband_`x'`dataset'", replace
}
else di "WARNING AGE SPLINE MODEL DID NOT FIT (OUTCOME `outcome')"

}


*SENSITIVITY ANALYSIS: 12 months FUP
keep if has_12_m_follow_up == 1
foreach exposure_type in kids_cat4   {

*Age spline model (not adj ethnicity)
cap erase ./output/an_sense_`outcome'_plus_eth_12mo_ageband_`x'`dataset'
basecoxmodel, exposure("i.`exposure_type'") age("age1 age2 age3")  
if _rc==0{
estimates
estimates save ./output/an_sense_`outcome'_plus_eth_12mo_ageband_`x'`dataset', replace
*estat concordance /*c-statistic*/
}
else di "WARNING 12 MO FUP MODEL W/ AGE SPLINE  DID NOT FIT (OUTCOME `outcome')"
}	
}

log close


exit, clear STATA

