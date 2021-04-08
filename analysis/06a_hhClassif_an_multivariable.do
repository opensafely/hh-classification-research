/*==============================================================================
DO FILE NAME:			06a_eth_an_multivariable_eth16
PROJECT:				Ethnicity and COVID
AUTHOR:					K Wing (modified from R Mathur, A wong and A Schultze)
DATE: 					15 July 2020					
DESCRIPTION OF FILE:	program 06 
						univariable regression
						multivariable regression 
DATASETS USED:			data in memory ($tempdir/analysis_dataset_STSET_outcome)
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir
						table2, printed to $Tabfigdir
						complete case analysis	
==============================================================================*/



/*"quick" univariable and multivariable regression based upon DAG and all variables listed in protocol, will need to go back and prepare a table 1 and then check these results
- Look at 2 different main exposures: (1) household size (2) household composition
*/

*first of all, create a household composition variable that is "age category x in household size y"
*based on age categories and household sizes, there will be 12 x 9 = 108  possible categories
*first, create the categorical age that I want: 0-4, 5-9, 10-14, 15-19, 20-29, 30-39, 40-49, 50-59, 60-69, 70-79, 80-89, 90+
*(1) Household size exposure
cd ${outputData}
clear all
use hh_analysis_datasetALLVARS.dta, clear
*create the age variable that I want
egen ageCat=cut(age), at (0, 5, 10, 15, 20, 30, 40, 50, 60, 70, 80, 90, 120)
recode ageCat 0=1 5=2 10=3 15=4 20=5 30=6 40=7 50=8 60=9 70=10 80=11 90=12 
label define ageCatLabel 1 "0-4" 2 "5-9" 3 "10-14" 4 "15-19" 5 "20-29" 6 "30-39" 7 "40-49" 8 "50-59" 9 "60-69" 10 "70-79" 11 "80-89" 12 "90+"
label values ageCat ageCatLabel
tab ageCat, miss
la var ageCat "Categorised age"
*now creat the household composition variable that takes account of age of the person and the size of the house that they are in
*this doesn't take account of the ages of the other people in the house though?
generate hh_composition=.
la var hh_composition "Combination of person's age and household size'"
levelsof ageCat, local(ageLevels)
local count=0
foreach l of local ageLevels {
	levelsof hh_size, local(hh_sizeLevels)
	foreach m of local hh_sizeLevels {
		local count=`count'+1
		display `count'
		replace hh_composition=`count' if ageCat==`l' & hh_size==`m'
	}	
}
order age hh_size hh_composition
tab hh_composition


*(A) CRUDE ASSOCIATIONS

*crude association between household size and COVID-19 infection (not including death at this stage)
logistic case i.hh_size, or base

*crude association between household composition and COVID-19 infection
logistic case i.hh_composition, or base



*(B) MULTIVARIABLE ASSOCIATIONS BASED UPON DAG/protocol list
*crude first
logistic case i.hh_size, or base
*adjusted for age
logistic case i.hh_size age, or base
*adjusted for all variables in DAG/protocol list except comorbidities, shielding behaviour
/*i.e. 
	age, sex, BMI, smoking, IMD, geographical variation, ethnicity
*/
tab sex
generate sex2=.
replace sex2=0 if sex=="F"
replace sex2=1 if sex=="M"
tab sex2
label define sex2Label 0 "F" 1 "M"
label values sex2 sex2Label

tab bmicat /*not quite what we have in the protocol, lots of missing*/
tab smoke
tab imd
tab region
generate region2=.
replace region2=0 if region=="East"
replace region2=1 if region=="East Midlands"
replace region2=2 if region=="London"
replace region2=3 if region=="North East"
replace region2=4 if region=="North West"
replace region2=5 if region=="South East"
replace region2=6 if region=="South West"
replace region2=7 if region=="West Midlands"
replace region2=8 if region=="Yorkshire and The Humber"
label define region2Label 0 "East" 1 "East Midlands"  2 "London" 3 "North East" 4 "North West" 5 "South East" 6 "South West" 7 "West Midlands" 8 "Yorkshire and The Humber"
label values region2 region2Label

*multivariable for hh_size
tab eth5
logistic case i.hh_size age i.sex2 i.bmicat i.smoke i.imd i.region2 i.eth5, or base

*multivariable for hh_composition
logistic case i.hh_composition, or base
logistic case i.hh_composition i.sex2 i.bmicat i.smoke i.imd i.region2 i.eth5, or base

logistic case i.hh_size age i.sex2 i.bmicat i.smoke i.imd i.region2 i.eth5, or base


logistic case i.hh_composition ageCat i.sex2 i.bmicat i.smoke i.imd i.region2 i.eth5, or base


logistic case i.hh_composition age i.sex2 i.bmicat i.smoke i.imd i.region2 i.eth5, or base




*now add all likely confounders based on DAG/list from protocol
/*these are:
	
*/






/*Code for outputting tables as well that I need to come back to*/
* Open a log file

cap log close
macro drop hr
log using "$Logdir/06a_eth_an_multivariable_eth16", replace t 

cap file close tablecontent
file open tablecontent using $Tabfigdir/table2_eth16.txt, write text replace
file write tablecontent ("Table 2: Association between ethnicity in 16 categories and COVID-19 outcomes - Complete Case Analysis") _n
file write tablecontent _tab ("Denominator") _tab ("Event") _tab ("Total person-weeks") _tab ("Rate per 1,000") _tab ("Crude") _tab _tab ("Age/Sex Adjusted") _tab _tab ("Age/Sex/IMD Adjusted") _tab _tab 	("plus co-morbidities") _tab _tab 	("plus hh size/carehome")  _tab _tab  _n
file write tablecontent _tab _tab _tab _tab _tab   ("HR") _tab ("95% CI") _tab ("HR") _tab ("95% CI") _tab ("HR") _tab ("95% CI") _tab ("HR") _tab ("95% CI") _tab ("HR") _tab ("95% CI") _n



foreach i of global outcomes {
use "$Tempdir/analysis_dataset_STSET_`i'.dta", clear
safetab eth16 `i', missing row
} //end outcomes

foreach i of global outcomes {
	di "`i'"
	
* Open Stata dataset
use "$Tempdir/analysis_dataset_STSET_`i'.dta", clear

*drop irish for icu due to small numbers
drop if eth16==2 & "`i'"=="icu"


/* Main Model=================================================================*/

/* Univariable model */ 

stcox i.eth16, nolog
estimates save "$Tempdir/crude_`i'_eth16", replace 
parmest, label eform format(estimate p lb ub) saving("$Tempdir/crude_`i'_eth16", replace) idstr("crude_`i'_eth16") 
local hr "`hr' "$Tempdir/crude_`i'_eth16" "


/* Multivariable models */ 
*Age and gender
stcox i.eth16 i.male age1 age2 age3, strata(stp) nolog
estimates save "$Tempdir/model0_`i'_eth16", replace 
parmest, label eform format(estimate p lb ub) saving("$Tempdir/model0_`i'_eth16", replace) idstr("model0_`i'_eth16")
local hr "`hr' "$Tempdir/model0_`i'_eth16" "
 

* Age, Gender, IMD

stcox i.eth16 i.male age1 age2 age3 i.imd, strata(stp) nolog
if _rc==0{
estimates
estimates save "$Tempdir/model1_`i'_eth16", replace 
parmest, label eform format(estimate p lb ub) saving("$Tempdir/model1_`i'_eth16", replace) idstr("model1_`i'_eth16") 
local hr "`hr' "$Tempdir/model1_`i'_eth16" "
}
else di "WARNING MODEL1 DID NOT FIT (OUTCOME `i')"

* Age, Gender, IMD and Comorbidities 
stcox i.eth16 i.male age1 age2 age3 	i.imd						///
										bmi	hba1c_pct				///
										gp_consult_count			///
										i.smoke_nomiss				///
										i.hypertension bp_map		 	///	
										i.asthma					///
										chronic_respiratory_disease ///
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
										i.ra_sle_psoriasis, strata(stp) nolog		
if _rc==0{
estimates
estimates save "$Tempdir/model2_`i'_eth16", replace 
parmest, label eform format(estimate p lb ub) saving("$Tempdir/model2_`i'_eth16", replace) idstr("model2_`i'_eth16") 
local hr "`hr' "$Tempdir/model2_`i'_eth16" "
}
else di "WARNING MODEL2 DID NOT FIT (OUTCOME `i')"

										
* Age, Gender, IMD and Comorbidities  and household size and carehome
stcox i.eth16 i.male age1 age2 age3 	i.imd						///
										bmi	hba1c_pct				///
										gp_consult_count			///
										i.smoke_nomiss				///
										i.hypertension bp_map		 	///	
										i.asthma					///
										chronic_respiratory_disease ///
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
										i.hh_total_cat i.carehome, strata(stp) nolog		
if _rc==0{
estimates
estimates save "$Tempdir/model3_`i'_eth16", replace
parmest, label eform format(estimate p lb ub) saving("$Tempdir/model3_`i'_eth16", replace) idstr("model3_`i'_eth16") 
local hr "`hr' "$Tempdir/model3_`i'_eth16" "
}
else di "WARNING MODEL3 DID NOT FIT (OUTCOME `i')"

										
/* Print table================================================================*/ 
*  Print the results for the main model 


* Column headings 
file write tablecontent ("`i'") _n

* Row headings 
local lab1: label eth16 1
local lab2: label eth16 2
local lab3: label eth16 3
local lab4: label eth16 4
local lab5: label eth16 5
local lab6: label eth16 6
local lab7: label eth16 7
local lab8: label eth16 8
local lab9: label eth16 9
local lab10: label eth16 10
local lab11: label eth16 11

/* counts */
 
* First row, eth16 = 1 (White British) reference cat
	qui safecount if eth16==1
	local denominator = r(N)
	qui safecount if eth16 == 1 & `i' == 1
	local event = r(N)
    bysort eth16: egen total_follow_up = total(_t)
	qui su total_follow_up if eth16 == 1
	local person_week = r(mean)/7
	local rate = 1000*(`event'/`person_week')
	
	file write tablecontent  ("`lab1'") _tab (`denominator') _tab (`event') _tab %10.0f (`person_week') _tab %3.2f (`rate') _tab
	file write tablecontent ("1.00") _tab _tab ("1.00") _tab _tab ("1.00")  _tab _tab ("1.00") _tab _tab ("1.00") _n
	
* Subsequent ethnic groups
forvalues eth=2/11 {
	qui safecount if eth16==`eth'
	local denominator = r(N)
	qui safecount if eth16 == `eth' & `i' == 1
	local event = r(N)
	qui su total_follow_up if eth16 == `eth'
	local person_week = r(mean)/7
	local rate = 1000*(`event'/`person_week')
	file write tablecontent  ("`lab`eth''") _tab (`denominator') _tab (`event') _tab %10.0f (`person_week') _tab %3.2f (`rate') _tab  
	cap estimates use "$Tempdir/crude_`i'_eth16" 
	cap cap lincom `eth'.eth16, eform
	file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _tab 
	cap estimates clear
	cap estimates use "$Tempdir/model0_`i'_eth16" 
	cap cap lincom `eth'.eth16, eform
	file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _tab 
	cap estimates clear
	cap estimates use "$Tempdir/model1_`i'_eth16" 
	cap cap lincom `eth'.eth16, eform
	file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _tab 
	cap estimates clear
	cap estimates use "$Tempdir/model2_`i'_eth16" 
	cap cap lincom `eth'.eth16, eform
	file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _tab 
	cap estimates clear
	cap estimates use "$Tempdir/model3_`i'_eth16" 
	cap cap lincom `eth'.eth16, eform
	file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _n
}  //end ethnic group


} //end outcomes

file close tablecontent

************************************************create forestplot dataset
dsconcat `hr'
duplicates drop
split idstr, p(_)
ren idstr1 model
ren idstr2 outcome
drop idstr idstr3
tab model

*save dataset for later
outsheet using "$Tabfigdir/FP_multivariable_eth16.txt", replace

* Close log file 
log close

insheet using $Tabfigdir/table2_eth16.txt, clear

