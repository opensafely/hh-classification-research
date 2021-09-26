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
*global demogadjlist age1 age2 age3 i.male i.obese4cat i.smoke i.rural_urbanFive
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

use ./output/hhClassif_analysis_dataset_STSET_covidHospOrDeath_ageband_3`dataset'.dta, clear
*May also want to do this for all ethnicities? - yes
*keep if eth5<4


/*
*Testing smoking-ethnicity interaction
capture noisily stcox i.hhRiskCatExp_4cats i.eth5##i.smoke age1 age2 age3 i.male i.obese4cat i.rural_urbanFive i.coMorbCat i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats i.eth5 i.smoke age1 age2 age3 i.male i.obese4cat i.rural_urbanFive i.coMorbCat i.imd i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-SMOKING result - evidence for interaction*****************"
lrtest A B, force

*Testing IMD-ethnicity interaction
capture noisily stcox i.hhRiskCatExp_4cats i.eth5##i.imd i.smoke age1 age2 age3 i.male i.obese4cat i.rural_urbanFive i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats i.eth5 i.imd i.smoke age1 age2 age3 i.male i.obese4cat i.rural_urbanFive i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-IMD - evidence for interaction*****************"
lrtest A B, force

*Testing obesity interaction
capture noisily stcox i.hhRiskCatExp_4cats i.eth5##i.obese4cat i.imd i.smoke age1 age2 age3 i.male i.rural_urbanFive i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats i.eth5 i.obese4cat i.imd i.smoke age1 age2 age3 i.male  i.rural_urbanFive i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-OBESITY - evidence for interaction*****************"
lrtest A B, force

*Testing rural urban interaction
capture noisily stcox i.hhRiskCatExp_4cats i.eth5##i.rural_urbanFive i.obese4cat i.imd i.smoke age1 age2 age3 i.male i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats i.eth5 i.rural_urbanFive i.obese4cat i.imd i.smoke age1 age2 age3 i.male  i.coMorbCat i.hh_total_cat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-RURALURBAN - NO evidence for interaction*****************"
lrtest A B, force

*Testing hh_size interaction
capture noisily stcox i.hhRiskCatExp_4cats i.eth5##i.hh_total_cat i.rural_urbanFive i.obese4cat i.imd i.smoke age1 age2 age3 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats i.eth5 i.hh_total_cat i.rural_urbanFive i.obese4cat i.imd i.smoke age1 age2 age3 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHSIZE - CODING ERROR, REDOING*****************"
lrtest A B, force

**Testing main exposure-ethnicity interaction while also including other interactions FOR WHICH THERE IS EVIDENCE OF INTERACTION
/*capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive age1 age2 age3 i.male i.coMorbCat , strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive age1 age2 age3 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHCOMPOSITION - evidence for interaction (hooray)*****************"
lrtest A B, force*/
*/


*THIS VERSION IS WHERE I ONLY LOOK AT INTERACTIONS THAT LOOK LIKE THEY ARE PRESENT FROM TABLE S5 (Age, smoking, IMD)
**Testing main exposure-ethnicity interaction while also including INTERACTIONS WITH ALL OTHER VARIABLES (BASED ON MEETING WITH STEPHEN 28 JUL)
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat i.hh_total_cat i.rural_urbanFive i.ageCatfor67Plus##i.eth5 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat i.hh_total_cat i.rural_urbanFive i.ageCatfor67Plus##i.eth5 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHCOMPOSITION - INCLUDING INTERACTIONS FOR ALL OTHER VARIABLES*****************"
lrtest A B, force


*output lincom for this
*Fit and save model
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat i.hh_total_cat i.rural_urbanFive i.ageCatfor67Plus##i.eth5 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
capture noisily estimates store mvAdjWHHSize		
*helper variables
sum eth5
local maxEth5=r(max) 
sum hhRiskCatExp_4cats
local maxhhRiskCat=r(max)

*for each ethnicity category, output hhrisk hazard ratios
forvalues ethCat=1/`maxEth5' {
	display "*************Ethnicity: `ethCat'************ "
	forvalues riskCat=1/`maxhhRiskCat' {
		display "`ethCat'"
		display "`riskCat'"
		capture noisily lincom `riskCat'.hhRiskCatExp_4cats + `riskCat'.hhRiskCatExp_4cats#`ethCat'.eth5, eform
	}
}
*/

log close






/***THIS VERSION IS WHERE I ALLOW FOR INTERACTIONS WITH EVERYTHING
*EDITED THIS SO HH COMPOSITION IS A CONTINOUS VARIABLE

**Testing main exposure-ethnicity interaction while also including INTERACTIONS WITH ALL OTHER VARIABLES (BASED ON MEETING WITH STEPHEN 28 JUL)
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox hhRiskCatExp_4cats i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHCOMPOSITION - INCLUDING INTERACTIONS FOR ALL OTHER VARIABLES*****************"
lrtest A B, force

/*
*output lincom for this
*Fit and save model
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
capture noisily estimates store mvAdjWHHSize		
*helper variables
sum eth5
local maxEth5=r(max) 
sum hhRiskCatExp_4cats
local maxhhRiskCat=r(max)

*for each ethnicity category, output hhrisk hazard ratios
forvalues ethCat=1/`maxEth5' {
	display "*************Ethnicity: `ethCat'************ "
	forvalues riskCat=1/`maxhhRiskCat' {
		display "`ethCat'"
		display "`riskCat'"
		capture noisily lincom `riskCat'.hhRiskCatExp_4cats + `riskCat'.hhRiskCatExp_4cats#`ethCat'.eth5, eform
	}
}
*/

log close




