********************************************************************************
*
*	Do-file:		12_hhClassif_an_MV_analysis_W_SA_multipleinteractions.do
*	Project:		hh risk classification
*	Programmed by:	K Wing, based on files from Hforbes, Fizz & Krishnan
*	Data used:		analysis_dataset.dta
*	Data created:	None
*	Other output:	Log file: 12_hhClassif_an_MV_analysis_W_SA_multipleinteractions.do 
*
********************************************************************************
*
*This file tests for interactions with smoking and IMD, in order to see if they should be included as interaction parameters
*  
********************************************************************************


* Set globals that will print in programs and direct output
*global outdir  	  "output" 
*global logdir     "log"
*global tempdir    "tempdata"

local dataset `1'

*list of demographic variables for adjustment: age (spline), sex, BMI, smoking, density of housing, geographic area (already taken account of in stratified analysis)
*global demogadjlist age1 age2 age3 i.male i.obese4cat i.smoke_nomiss i.rural_urbanFive
*list of comorbidities for adjustment
*global comorbidadjlist i.coMorbCat	

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
log using ./logs/12_hhClassif_an_MV_analysis_W_SA_multipleinteractions_`dataset', replace t


*Testing smoking-ethnicity interaction
use ./output/hhClassif_analysis_dataset_STSET_covidHospOrDeath_ageband_3`dataset'.dta, clear
keep if eth5<3

capture noisily stcox i.hhRiskCatExp_3cats i.eth5##i.smoke_nomiss age1 age2 age3 i.male i.obese4cat i.rural_urbanFive i.coMorbCat i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_3cats i.eth5 i.smoke_nomiss age1 age2 age3 i.male i.obese4cat i.rural_urbanFive i.coMorbCat i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-SMOKING*****************"
lrtest A B, force

*Testing IMD-ethnicity interaction
capture noisily stcox i.hhRiskCatExp_3cats i.eth5##i.imd i.smoke_nomiss age1 age2 age3 i.male i.obese4cat i.rural_urbanFive i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_3cats i.eth5 i.imd i.smoke_nomiss age1 age2 age3 i.male i.obese4cat i.rural_urbanFive i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-IMD*****************"
lrtest A B, force

*Testing obesity interaction
capture noisily stcox i.hhRiskCatExp_3cats i.eth5##i.obese4cat i.imd i.smoke_nomiss age1 age2 age3 i.male i.rural_urbanFive i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_3cats i.eth5 i.obese4cat i.imd i.smoke_nomiss age1 age2 age3 i.male  i.rural_urbanFive i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-OBESITY*****************"
lrtest A B, force

*Testing rural urban interaction
capture noisily stcox i.hhRiskCatExp_3cats i.eth5##i.rural_urbanFive i.obese4cat i.imd i.smoke_nomiss age1 age2 age3 i.male i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_3cats i.eth5 i.rural_urbanFive i.obese4cat i.imd i.smoke_nomiss age1 age2 age3 i.male  i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-RURALURBAN*****************"
lrtest A B, force

*Testing hh size interaction
capture noisily stcox i.hhRiskCatExp_3cats i.eth5##i.hh_total_cat i.rural_urbanFive i.obese4cat i.imd i.smoke_nomiss age1 age2 age3 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_3cats i.eth5##i.hh_total_cat i.rural_urbanFive i.obese4cat i.imd i.smoke_nomiss age1 age2 age3 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHSIZE*****************"
lrtest A B, force

**Testing main exposure-ethnicity interaction while also including other interactions
capture noisily stcox i.hhRiskCatExp_3cats##i.eth5 i.imd##i.eth5 i.smoke_nomiss##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive##i.eth5 i.hh_total_cat##i.eth5 age1 age2 age3 i.male i.coMorbCat , strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_3cats i.eth5 i.imd##i.eth5 i.smoke_nomiss##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive##i.eth5 i.hh_total_cat##i.eth5 age1 age2 age3 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHCOMPOSITION*****************"
lrtest A B, force
*output lincom for this
*Fit and save model
capture noisily stcox i.hhRiskCatExp_3cats##i.eth5 i.imd##i.eth5 i.smoke_nomiss##i.eth5 age1 age2 age3 i.male i.obese4cat i.rural_urbanFive i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
capture noisily estimates store mvAdjWHHSize		
*helper variables
sum eth5
local maxEth5=r(max) 
sum hhRiskCatExp_3cats
local maxhhRiskCat=r(max)

*for each ethnicity category, output hhrisk hazard ratios
forvalues ethCat=1/`maxEth5' {
	display "*************Ethnicity: `ethCat'************ "
	forvalues riskCat=1/`maxhhRiskCat' {
		display "`ethCat'"
		display "`riskCat'"
		capture noisily lincom `riskCat'.hhRiskCatExp_3cats + `riskCat'.hhRiskCatExp_3cats#`ethCat'.eth5, eform
	}
}

log close


*Testing imd interaction

/*
*(b) Multivariable, stratified by ethnicity and including adjustment for SES
*foreach outcome in covidDeath covidHosp covidHospOrDeath nonCovidDeath
foreach outcome in covidHospOrDeath {
*2 and 3 here are the two age categories I've created so far, need to change these when there are more

	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear
	
	*Perform LRT test to get p-value for interaction
	capture noisily stcox i.hhRiskCatExp_3cats##i.eth5 $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
	est store A
	capture noisily stcox i.hhRiskCatExp_3cats i.eth5 $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
	est store B
	display "***************LRT TEST 5 ETH CATEGORIES*****************"
	lrtest A B, force

	*Fit and save model for outputting HRs
	display "***********ALL 5 ETHNICITY CATEGORIES - Outcome: `outcome', ageband: 67+, dataset: `dataset' - broad categories, interaction with ethnicity*************************"
	capture noisily stcox i.hhRiskCatExp_3cats##i.eth5 $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
	capture noisily estimates store mvAdjWHHSize		
	
	
	*helper variables
	sum eth5
	local maxEth5=r(max) 
	sum hhRiskCatExp_3cats
	local maxhhRiskCat=r(max)

	*for each ethnicity category, output hhrisk hazard ratios
	forvalues ethCat=1/`maxEth5' {
		display "*************Ethnicity: `ethCat'************ "
		forvalues riskCat=1/`maxhhRiskCat' {
			display "`ethCat'"
			display "`riskCat'"
			capture noisily lincom `riskCat'.hhRiskCatExp_3cats + `riskCat'.hhRiskCatExp_3cats#`ethCat'.eth5, eform
		}
	}
}



foreach outcome in covidHospOrDeath {
*foreach outcome in covidDeath covidHosp covidHospOrDeath nonCovidDeath {
*2 and 3 here are the two age categories I've created so far, need to change these when there are more

	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear
	*keep only white and south asian (eth5 categories one and 2)
	keep if eth5<3
	
	*Perform LRT test to get p-value for interaction
	capture noisily stcox i.hhRiskCatExp_3cats##i.eth5 $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
	est store A
	capture noisily stcox i.hhRiskCatExp_3cats i.eth5 $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
	est store B
	display "***************LRT TEST 2 ETH CATEGORIES*****************"
	lrtest A B, force

	*Fit and save model
	display "***********ONLY WHITE AND SOUTH ASIAN EHTNICITY CATEGORIES - Outcome: `outcome', ageband: 67+, dataset: `dataset' - broad categories, interaction with ethnicity*************************"
	capture noisily stcox i.hhRiskCatExp_3cats##i.eth5 $demogadjlist $comorbidadjlist i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
	capture noisily estimates store mvAdjWHHSize		
	
	
	*helper variables
	sum eth5
	local maxEth5=r(max) 
	sum hhRiskCatExp_3cats
	local maxhhRiskCat=r(max)

	*for each ethnicity category, output hhrisk hazard ratios
	forvalues ethCat=1/`maxEth5' {
		display "*************Ethnicity: `ethCat'************ "
		forvalues riskCat=1/`maxhhRiskCat' {
			display "`ethCat'"
			display "`riskCat'"
			capture noisily lincom `riskCat'.hhRiskCatExp_3cats + `riskCat'.hhRiskCatExp_3cats#`ethCat'.eth5, eform
		}
	}
}
* Close log file
log close




/*


******MANUAL BUGHUNTING OF LINCOM ISSUES*******(comment out unless bughunting locally)
/*
cd /Users/kw/Documents/GitHub/hh-classification-research
use ./output/hhClassif_analysis_dataset_STSET_covidDeath_ageband_3MAIN.dta
tab eth5
tab eth5, nolabel

global demogadjlist age1 age2 age3 i.male i.obese4cat i.smoke_nomiss i.rural_urbanFive
global comorbidadjlist i.coMorbCat	

stcox i.hhRiskCatExp##i.eth5 $demogadjlist $comorbidadjlist i.imd, strata(utla_group) vce(cluster hh_id)

		*helper variables
		sum eth5
		local maxEth5=r(max) 
		sum hhRiskCatExp
		local maxhhRiskCat=r(max)

		*for each ethnicity category, output hhrisk hazard ratios
		forvalues ethCat=1/`maxEth5' {
			display "*************Ethnicity: `ethCat'************ "
			forvalues riskCat=1/`maxhhRiskCat' {
				capture noisily lincom `riskCat'.hhRiskCatExp + `riskCat'.hhRiskCatExp#`ethCat'.eth5, eform
			}
		}


*output hhrisk exposures by each level of ethnicity
				*1=white
				lincom 1.hhRiskCatExp + 1.hhRiskCatExp#1.eth5, eform
				lincom 2.hhRiskCatExp + 2.hhRiskCatExp#1.eth5, eform 
				lincom 3.hhRiskCatExp + 3.hhRiskCatExp#1.eth5, eform
				lincom 4.hhRiskCatExp + 4.hhRiskCatExp#1.eth5, eform
				lincom 5.hhRiskCatExp + 5.hhRiskCatExp#1.eth5, eform
				lincom 6.hhRiskCatExp + 6.hhRiskCatExp#1.eth5, eform
				lincom 7.hhRiskCatExp + 7.hhRiskCatExp#1.eth5, eform
				lincom 8.hhRiskCatExp + 8.hhRiskCatExp#1.eth5, eform
				
				*2=south asian
				lincom 1.hhRiskCatExp + 1.hhRiskCatExp#2.eth5, eform
				lincom 2.hhRiskCatExp + 2.hhRiskCatExp#2.eth5, eform 
				lincom 3.hhRiskCatExp + 3.hhRiskCatExp#2.eth5, eform
				lincom 4.hhRiskCatExp + 4.hhRiskCatExp#2.eth5, eform
				lincom 5.hhRiskCatExp + 5.hhRiskCatExp#2.eth5, eform
				lincom 6.hhRiskCatExp + 6.hhRiskCatExp#2.eth5, eform
				lincom 7.hhRiskCatExp + 7.hhRiskCatExp#2.eth5, eform
				lincom 8.hhRiskCatExp + 8.hhRiskCatExp#2.eth5, eform
				
				*3=black
				lincom 1.hhRiskCatExp + 1.hhRiskCatExp#3.eth5, eform
				lincom 2.hhRiskCatExp + 2.hhRiskCatExp#3.eth5, eform 
				lincom 3.hhRiskCatExp + 3.hhRiskCatExp#3.eth5, eform
				lincom 4.hhRiskCatExp + 4.hhRiskCatExp#3.eth5, eform
				lincom 5.hhRiskCatExp + 5.hhRiskCatExp#3.eth5, eform
				lincom 6.hhRiskCatExp + 6.hhRiskCatExp#3.eth5, eform
				lincom 7.hhRiskCatExp + 7.hhRiskCatExp#3.eth5, eform
				lincom 8.hhRiskCatExp + 8.hhRiskCatExp#3.eth5, eform
				
				*4=mixed
				lincom 1.hhRiskCatExp + 1.hhRiskCatExp#4.eth5, eform
				lincom 2.hhRiskCatExp + 2.hhRiskCatExp#4.eth5, eform 
				lincom 3.hhRiskCatExp + 3.hhRiskCatExp#4.eth5, eform
				lincom 4.hhRiskCatExp + 4.hhRiskCatExp#4.eth5, eform
				lincom 5.hhRiskCatExp + 5.hhRiskCatExp#4.eth5, eform
				lincom 6.hhRiskCatExp + 6.hhRiskCatExp#4.eth5, eform
				lincom 7.hhRiskCatExp + 7.hhRiskCatExp#4.eth5, eform
				lincom 8.hhRiskCatExp + 8.hhRiskCatExp#4.eth5, eform		
				
				*5=other
				lincom 1.hhRiskCatExp + 1.hhRiskCatExp#5.eth5, eform
				lincom 2.hhRiskCatExp + 2.hhRiskCatExp#5.eth5, eform 
				lincom 3.hhRiskCatExp + 3.hhRiskCatExp#5.eth5, eform
				lincom 4.hhRiskCatExp + 4.hhRiskCatExp#5.eth5, eform
				lincom 5.hhRiskCatExp + 5.hhRiskCatExp#5.eth5, eform
				lincom 6.hhRiskCatExp + 6.hhRiskCatExp#5.eth5, eform
				lincom 7.hhRiskCatExp + 7.hhRiskCatExp#5.eth5, eform
				lincom 8.hhRiskCatExp + 8.hhRiskCatExp#5.eth5, eform

*lincom 3.smoke_nomiss + 3.smoke_nomiss#1.male, eform

*hhRiskCatExp baseline category, by each ethnicity category
		*lincom 1.hhRiskCatExp + 1.hhRiskCatExp#1.eth5, eform
		*lincom 1.hhRiskCatExp + 1.hhRiskCatExp#2.eth5, eform 
		*lincom 1.hhRiskCatExp + 1.hhRiskCatExp#3.eth5, eform
		*lincom 1.hhRiskCatExp + 1.hhRiskCatExp#4.eth5, eform
		*lincom 1.hhRiskCatExp + 1.hhRiskCatExp#5.eth5, eform
		
		lincom 2.hhRiskCatExp + 2.hhRiskCatExp#1.eth5, eform
		lincom 2.hhRiskCatExp + 2.hhRiskCatExp#2.eth5, eform 
		lincom 2.hhRiskCatExp + 2.hhRiskCatExp#3.eth5, eform
		lincom 2.hhRiskCatExp + 2.hhRiskCatExp#4.eth5, eform
		lincom 2.hhRiskCatExp + 2.hhRiskCatExp#5.eth5, eform
		
		lincom 3.hhRiskCatExp + 3.hhRiskCatExp#1.eth5, eform
		lincom 3.hhRiskCatExp + 3.hhRiskCatExp#2.eth5, eform 
		lincom 3.hhRiskCatExp + 3.hhRiskCatExp#3.eth5, eform
		lincom 3.hhRiskCatExp + 3.hhRiskCatExp#4.eth5, eform
		lincom 3.hhRiskCatExp + 3.hhRiskCatExp#5.eth5, eform
		
		lincom 4.hhRiskCatExp + 4.hhRiskCatExp#1.eth5, eform
		lincom 4.hhRiskCatExp + 4.hhRiskCatExp#2.eth5, eform 
		lincom 4.hhRiskCatExp + 4.hhRiskCatExp#3.eth5, eform
		lincom 4.hhRiskCatExp + 4.hhRiskCatExp#4.eth5, eform
		lincom 4.hhRiskCatExp + 4.hhRiskCatExp#5.eth5, eform		
		
		lincom 5.hhRiskCatExp + 5.hhRiskCatExp#1.eth5, eform
		lincom 5.hhRiskCatExp + 5.hhRiskCatExp#2.eth5, eform 
		lincom 5.hhRiskCatExp + 5.hhRiskCatExp#3.eth5, eform
		lincom 5.hhRiskCatExp + 5.hhRiskCatExp#4.eth5, eform
		lincom 5.hhRiskCatExp + 5.hhRiskCatExp#5.eth5, eform		
		
		lincom 6.hhRiskCatExp + 6.hhRiskCatExp#1.eth5, eform
		lincom 6.hhRiskCatExp + 6.hhRiskCatExp#2.eth5, eform 
		lincom 6.hhRiskCatExp + 6.hhRiskCatExp#3.eth5, eform
		lincom 6.hhRiskCatExp + 6.hhRiskCatExp#4.eth5, eform
		lincom 6.hhRiskCatExp + 6.hhRiskCatExp#5.eth5, eform
		
		lincom 7.hhRiskCatExp + 7.hhRiskCatExp#1.eth5, eform
		lincom 7.hhRiskCatExp + 7.hhRiskCatExp#2.eth5, eform 
		lincom 7.hhRiskCatExp + 7.hhRiskCatExp#3.eth5, eform
		lincom 7.hhRiskCatExp + 7.hhRiskCatExp#4.eth5, eform
		lincom 7.hhRiskCatExp + 7.hhRiskCatExp#5.eth5, eform
		
		lincom 8.hhRiskCatExp + 8.hhRiskCatExp#1.eth5, eform
		lincom 8.hhRiskCatExp + 8.hhRiskCatExp#2.eth5, eform 
		lincom 8.hhRiskCatExp + 8.hhRiskCatExp#3.eth5, eform
		lincom 8.hhRiskCatExp + 8.hhRiskCatExp#4.eth5, eform
		lincom 8.hhRiskCatExp + 8.hhRiskCatExp#5.eth5, eform

*limited version so I can check code
stcox i.smoke_nomiss##i.male, strata(utla_group) vce(cluster hh_id) base

lincom 3.smoke_nomiss + 3.smoke_nomiss#1.male, eform

lincom 2.hhRiskCatExp + 5*2.hhRiskCatExp#eth5, eform

lincom 2.hhRiskCatExp, eform
lincom 3.hhRiskCatExp, eform
lincom 4.hhRiskCatExp, eform 
lincom 5.hhRiskCatExp, eform
lincom 6.hhRiskCatExp, eform
lincom 7.hhRiskCatExp, eform

lincom 2.`exposure_type' + 1.`int_type'#2.`exposure_type', eform


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

