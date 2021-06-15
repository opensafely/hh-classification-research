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
sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles

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
foreach outcome in covidDeath covidHosp covidHospOrDeath nonCovidDeath {
*2 and 3 here are the two age categories I've created so far, need to change these when there are more
	forvalues x=2/3 {

	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_`x'`dataset'.dta, clear

		*Fit and save model
		cap erase ./output/hhClassif_multivariableAllEthnicities_`outcome'_ageband_`x'`dataset'.ster
		display "***********Outcome: `outcome', ageband: `x', dataset: `dataset'*************************"
		stcox i.hhRiskCatExp $demogadjlist $comorbidadjlist, strata(utla_group) vce(cluster hh_id)
		if _rc==0 {
			estimates
			estimates save ./output/hhClassif_multivariableAllEthnicities_`outcome'_ageband_`x'`dataset'.ster, replace
			}
		else di "WARNING - `var' vs `outcome' MODEL DID NOT SUCCESSFULLY FIT"
	}
}
