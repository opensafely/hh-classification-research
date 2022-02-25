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
*This file obtains p-values for interactions, with household-level interactions included a-priori (household composition, IMD, rural-urban)
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
log using ./logs/20_hhClassif_an_testing_interactions_`dataset', replace t

/*
use ./output/hhClassif_analysis_dataset_STSET_covidHospOrDeath_ageband_3`dataset'.dta, clear

*check number of records in this dataset - should be 2 624 405
count






*FOR REFERENCE
/*
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
*/

**NOTE: main exposure included as an a-priori interaction**


**(1)Testing interaction with hhRisk - RESULT W1:p=0.7371, W2: p<0.001 
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat i.ageCatfor67Plus, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCat67PLUS_5cats i.eth5 i.imd i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat i.ageCatfor67Plus, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: HHRISKCAT-ETH*****************"
lrtest A B, force

**(2)Testing interaction with IMD with HHRisk interaction included - RESULT W1:p=0.0697, W2: p=0.0042
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat i.ageCatfor67Plus, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat i.ageCatfor67Plus, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: IMD-ETH (WITH HHRISKCAT INTERACTION)*****************"
lrtest A B, force


**(3)Testing interaction with RURAL-URBAN with HHRisk and IMD interactions included - RESULT W1: p=0.2497, W2: p=0.0683
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive##i.eth5 i.smoke i.obese4cat i.male i.coMorbCat i.ageCatfor67Plus, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive i.eth5  i.smoke i.obese4cat i.male i.coMorbCat i.ageCatfor67Plus, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: URBAN-RURAL (WITH HHRISKCAT AND IMD INTERACTIONS)*****************"
lrtest A B, force



**(4)Testing interaction with AGE with HHRisk and IMD interactions included - RESULT W1:p<0.001, W2: p<0.001
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat i.ageCatfor67Plus##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat i.ageCatfor67Plus i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: AGE (WITH HHRISKCAT AND IMD INTERACTIONS))*****************"
lrtest A B, force



**(5)Testing interaction with COMORB with HHRisk, IMD and AGE interactions included - RESULT W1: p=0.0347, W2: p=0.1247
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat##i.eth5 i.ageCatfor67Plus##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat i.eth5 i.ageCatfor67Plus##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: COMORB (WITH HHRISKCAT AND IMD INTERACTIONS)*****************"
lrtest A B, force


*quick test for W1 only including hh comp interaction (a-priori), testing to see if there is evidence for comorbidity
**(1)Testing interaction with comorb with only hhrisk included as an interaction - RESULT W1: p=0.1639
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat##i.eth5 i.ageCatfor67Plus, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat i.eth5 i.ageCatfor67Plus, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: COMORB-ETH*****************"
lrtest A B, force


**(6)Testing interaction with SEX with HHRisk, IMD and AGE interactions included - RESULT W1: p=0.2973  W2: p=0.89
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.male##i.eth5 i.coMorbCat i.ageCatfor67Plus##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.male i.eth5 i.coMorbCat i.ageCatfor67Plus##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: SEX (WITH HHRISKCAT AND IMD INTERACTIONS)*****************"
lrtest A B, force


**(6)Testing interaction with OBESITY with HHRisk, IMD and AGE interactions included - RESULT W1: p=0.0963, W2: p<0.001
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive i.smoke i.obese4cat##i.eth5 i.male i.coMorbCat i.ageCatfor67Plus##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.eth5 i.male i.coMorbCat i.ageCatfor67Plus##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: OBESITY (WITH HHRISKCAT IMD AND AGE INTERACTIONS)*****************"
lrtest A B, force
*/

*quick test of p-value for non-COVID death for IMD

use ./output/hhClassif_analysis_dataset_STSET_nonCovidDeath_ageband_3`dataset'.dta, clear


capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat i.ageCatfor67Plus, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat i.ageCatfor67Plus, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: IMD-ETH (WITH HHRISKCAT INTERACTION)*****************"
lrtest A B, force


log close




/*I think the model I want is with interactions between the main exposure, IMD and age i.e.:

capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.ageCatfor67Plus##i.eth5 i.rural_urbanFive i.smoke i.obese4cat i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)

BUT also going to assess the effect on the results of including obesity i.e.:

capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.ageCatfor67Plus##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive i.smoke  i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)

*/

*legacy code for reference
/*


******(1) Age interaction analysis*******
/*
display "==============(1) INTERACTIONS WITH ALL VARIABLES, TESTING INTERACTION BETWEEN AGE AND ETHNICITY================="
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-AGE - INCLUDING ALL INTERACTIONS*****************"
lrtest A B, force
*/

*output lincom for a ethnicity age interaction (incl interactions with everything), this is to see if this gives HRs like the separate cohorts
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
capture noisily estimates store mvAdjWHHSize		
*helper variables
sum eth5
local maxEth5=r(max) 
sum ageCatfor67Plus
local maxAgeCatfor67Plus=r(max)


*for each ethnicity category, output age-eth5 hazard ratios
forvalues ethCat=1/`maxEth5' {
	display "*************Ethnicity: `ethCat'************ "
	forvalues ageCatfor67PlusCat=0/`maxAgeCatfor67Plus' {
		display "`ethCat'"
		display "`ageCatfor67PlusCat'"
		capture noisily lincom `ageCatfor67PlusCat'.ageCatfor67Plus + `ageCatfor67PlusCat'.ageCatfor67Plus#`ethCat'.eth5, eform
	}
}





******(2) IMD interaction analysis*******
/*
display "==============(1) INTERACTIONS WITH ALL VARIABLES, TESTING INTERACTION BETWEEN IMD AND ETHNICITY================="
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-IMD - INCLUDING ALL INTERACTIONS*****************"
lrtest A B, force
*/

*output lincom for a ethnicity IMD interaction (incl interactions with everything), this is to see if this gives HRs like the separate cohorts
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
*helper variables
sum eth5
local maxEth5=r(max) 
sum imd
local maxIMD=r(max)


*for each ethnicity category, output age-eth5 hazard ratios
forvalues ethCat=1/`maxEth5' {
	display "*************Ethnicity: `ethCat'************ "
	forvalues imdCat=1/`maxIMD' {
		display "`ethCat'"
		display "`imdCat'"
		capture noisily lincom `imdCat'.imd + `imdCat'.imd#`ethCat'.eth5, eform
	}
}



/*
*Here am going to do a final output that is the two ways of doing it: (1) Interactions with all variables (2) Interactions with all variables except household size
display "==============(1) INTERACTIONS WITH ALL VARIABLES================="
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHCOMPOSITION - INCLUDING ALL INTERACTIONS, WITH ONLY HHRISK LINEAR*****************"
lrtest A B, force
*/

/*
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
*/



/*
display "==============(2) INTERACTIONS WITH ALL VARIABLES EXCEPT HH SIZE================="
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store A
capture noisily stcox i.hhRiskCatExp_4cats i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
est store B
display "***************LRT TEST: ETHNICITY-HHCOMPOSITION - INCLUDING ALL INTERACTIONS EXCEPT HH SIZE*****************"
lrtest A B, force
*/

/*
*output lincom for hh-comp ethnicity interaction - interactions with everything, this is to see if this gives HRs like the separate cohorts
capture noisily stcox i.hhRiskCatExp_4cats##i.eth5 i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.hh_total_cat i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5, strata(utla_group) vce(cluster hh_id)
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
