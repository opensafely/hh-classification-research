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

*check number of records in this dataset - should be 2 624 405
count

*Keep just white, south asian
keep if eth5<3




*Here am going to do a final output that is the two ways of doing it: (1) Interactions with all variables (2) Interactions with all variables except household size
display "==============(1) INTERACTIONS WITH ALL VARIABLES================="
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox hhRiskCatExp_4cats i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHCOMPOSITION - INCLUDING ALL INTERACTIONS, WITH ONLY HHRISK LINEAR*****************"
lrtest A B, force

*output lincom for hh-comp ethnicity interaction - interactions with everything, this is to see if this gives HRs like the separate cohorts
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





display "==============(2) INTERACTIONS WITH ALL VARIABLES EXCEPT HH SIZE================="
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox hhRiskCatExp_4cats i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHCOMPOSITION - INCLUDING ALL INTERACTIONS EXCEPT HH SIZE*****************"
lrtest A B, force

*output lincom for hh-comp ethnicity interaction - interactions with everything, this is to see if this gives HRs like the separate cohorts
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
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




*SUPERCEDED CODE

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
/*
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat i.hh_total_cat i.rural_urbanFive i.ageCatfor67Plus##i.eth5 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat i.hh_total_cat i.rural_urbanFive i.ageCatfor67Plus##i.eth5 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHCOMPOSITION - INCLUDING INTERACTIONS BASED ON RESULTS FROM SEPARATE COHORTS*****************"
lrtest A B, force


*THESE ARE ALL INTERACTIONS I HAVE TESTED FOR ALREADY

*INTERACTIONS FOR OTHER VARIABKLES (AGE, SMOKING, IMD)
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat i.hh_total_cat i.rural_urbanFive i.ageCatfor67Plus##i.eth5 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat i.hh_total_cat i.rural_urbanFive i.ageCatfor67Plus i.eth5 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-AGE - INCLUDING INTERACTIONS BASED ON VARIABLES FROM SEPARATE COHORTS*****************"
lrtest A B, force

capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat i.hh_total_cat i.rural_urbanFive i.ageCatfor67Plus##i.eth5 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke i.eth5 i.obese4cat i.hh_total_cat i.rural_urbanFive i.ageCatfor67Plus##i.eth5 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-SMOKING - INCLUDING INTERACTIONS BASED ON VARIABLES FROM SEPARATE COHORTS*****************"
lrtest A B, force

capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat i.hh_total_cat i.rural_urbanFive i.ageCatfor67Plus##i.eth5 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd i.eth5 i.smoke##i.eth5 i.obese4cat i.hh_total_cat i.rural_urbanFive i.ageCatfor67Plus##i.eth5 i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-IMD - INCLUDING INTERACTIONS BASED ON VARIABLES FROM SEPARATE COHORTS*****************"
lrtest A B, force
*/


/*
*LRT when all interactions are included - but with linear effects for hhrisk, hhsize, age, comorbidities, imd
capture noisily stcox hhRiskCatExp_4cats##i.eth5 imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 ageCatfor67Plus##i.eth5 i.male##i.eth5 coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox hhRiskCatExp_4cats imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 ageCatfor67Plus##i.eth5 i.male##i.eth5 coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHCOMPOSITION - INCLUDING ALL INTERACTIONS*****************"
lrtest A B, force
*/

*LRT tests to see which variables I don't need to include (from above, I am already going to include age, IMD, smoking status so don't need to test these)
/*need to test:
- obesity
- household size
- rural_urbanFive
- male
- comorb

*am also going to try just linear effects for hh risk and not for others
*/

/*
*LRT obesity
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-OBESITY - INCLUDING ALL INTERACTIONS, WITH ONLY HHRISK LINEAR*****************"
lrtest A B, force

*LRT household size
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHSIZE - INCLUDING ALL INTERACTIONS, WITH ONLY HHRISK LINEAR*****************"
lrtest A B, force


*LRT rural urban
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-RURALURBAN - INCLUDING ALL INTERACTIONS, WITH ONLY HHRISK LINEAR*****************"
lrtest A B, force


*LRT male
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-MALE - INCLUDING ALL INTERACTIONS, WITH ONLY HHRISK LINEAR*****************"
lrtest A B, force


*LRT comorb
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-COMORB - INCLUDING ALL INTERACTIONS, WITH ONLY HHRISK LINEAR*****************"
lrtest A B, force
*/


/*
*IT WORKED: LRT when all interactions are included EXCEPT HH SIZE - testing hhrisk but only with this linear, not the others - p=0.0149
capture noisily stcox hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox hhRiskCatExp_4cats i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHCOMPOSITION - INCLUDING ALL INTERACTIONS, WITH ONLY HHRISK LINEAR*****************"
lrtest A B, force
*/
