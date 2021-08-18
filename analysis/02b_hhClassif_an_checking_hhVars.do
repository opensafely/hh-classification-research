/*==============================================================================
DO FILE NAME:			00_hhClassif_cr_analysis_dataset
PROJECT:				Classification of hh into risk groups
DATE: 					12th August 2020 
AUTHOR:					Kevin Wing adapted from R Mathur H Forbes, A Wong, A Schultze, C Rentsch,K Baskharan, E Williamson 										
DESCRIPTION OF FILE:	program 00, data management for project  
						reformat variables 
						categorise variables
						label variables 
						apply exclusion criteria
DATASETS USED:			data in memory (from output/inputWithHHDependencies.csv)
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir

t


sysdir set PLUS "/Users/kw/Documents/GitHub/households-research/analysis/adofiles" 
sysdir set PERSONAL "/Users/kw/Documents/GitHub/households-research/analysis/adofiles" 

							
==============================================================================*/
sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles

local dataset `1'

* Open a log file
cap log close
log using ./logs/02b_hhClassif_an_checking_hhVars_`dataset'.log, replace t


*PRIORITY FOR THIS FILE IS TO FIX MY COHORT, I CAN COME BACK AND DO FURTHER INVESTIGATIONS LATER!
*NEED TO THINK ABOUT THE IMPLICATIONS OF HAVING DROPPED HH BIGGER THAN 12 BASED ON TPP HH SIZE!

use ./output/allHH_sizedBetween1And12_`dataset'.dta, clear



*============(1) CHECK TO SEE IF TPP HH_ID AND HH_SIZE ARE DISCREPANT================
*(a) Create a home made hh_size variable
*create a home-made household size variable
generate kw_hh_people_count=.
bysort hh_id: replace kw_hh_people_count=_n
la var kw_hh_people_count "kw generated counter for people in house"
generate kw_hh_size=.
by hh_id: replace kw_hh_size=kw_hh_people_count[_N]
la var kw_hh_size "kw generated household size"


*(b) Within people who are in households that are 12 or less in size, check to see how many of the TPP calculated household sizes are different to the kw calculated hh size
generate hh_size_wrong=.
la var hh_size_wrong "1=TPP hh size different to kw calc hh size, 0=no difference"
replace hh_size_wrong=0 if hh_size==kw_hh_size
replace hh_size_wrong=1 if hh_size!=kw_hh_size
display "===================(1) Proportion of all people in hh sized 12 or less where TPP hh_size differs from kw_calculated hh_size============="
tab hh_size_wrong

log close



*(c)Reduce

/*


*keep only people marked as living in private homes
drop if care_home_type!="U"

*might need to 
			
label define hh_total_cat  1 "1-2" ///
						   2 "3-5" ///
						   3 "6+" ///
											
label values hh_total_cat hh_total_cat

safetab hh_total_cat,m
safetab hh_total_cat care_home_type,m

safetab hh_size hh_total_cat,m





******Create a household composition variable for the hh risk classification study (might be useful for snotty noses? - takes 5 minutes to run up to line 363)
/*test how to create a variable with the following categories (see protocol safetable 1)
	1 SG1 - hh has only 18-29 year olds in it
	2 SG2 - hh has only 30-66 year olds in it
	3 SG3 - hh has only 67+ in it
	4 2G1 - hh has 0-17 and 18-29 in it
	5 2G2 - hh has 0-17 and 30-66 in it
	6 2G3 - hh has 0-17 and 67+ in it
	7 2G4 - hh has 18-29 and 67+ in it
	8 2G5 - hh has 30-66 and 67+ in it
	9 2G6 - hh has 18-29 and 67+ in it
	10 MG1 - hh has 0-17, 18-29 and 30-66 in it
	11 MG2 - hh has 0-17, 18-29 and 67+ in it
	12 MG3 - hh has 0-17, 30-66 and 67+ in it
	13 MG4 - hh has 18-29, 30-66 and 67+ in it
	14 MG5 - hh has 0-17, 18-29, 30-66 and 67+ in it
*/
*first of all, create age bands that I need for this
egen ageCatHHRisk=cut(age), at (0, 18, 30, 67, 200)
recode ageCatHHRisk 0=0 18=1 30=2 67=3 
label define ageCatHHRisk 0 "0-17" 1 "18-29" 2 "30-66" 3 "67+"
label values ageCatHHRisk ageCatHHRisk
safetab ageCatHHRisk, miss
la var ageCatHHRisk "Age categorised for HH risk analysis"

*make an age category variable here that is for table 1 of the 67+ year old analysis
egen ageCatfor67Plus=cut(age), at (67, 70, 75, 80, 85, 200)
recode ageCatfor67Plus 67=0 70=1 75=2 80=3 85=4 
label define ageCatfor67Plus 0 "67-69" 1 "70-74" 2 "75-79" 3 "80-84" 4 "85+"
label values ageCatfor67Plus ageCatfor67Plus
safetab ageCatfor67Plus, miss
la var ageCatfor67Plus "Age (categories)"
*check groupins
forvalues i=0/4{
	sum age if ageCatfor67Plus==`i'
}

preserve
	*keep only the variables I need to work this out
	keep hh_id patient_id ageCatHHRisk
	sort hh_id ageCatHHRisk

	*mark whether hh has each age category using egen max which returns true (1) or false (0) (see https://www.stata.com/support/faqs/data-management/create-variable-recording/)
	egen hasUnder18=max(ageCatHHRisk==0), by(hh_id)
	egen has18_29=max(ageCatHHRisk==1), by(hh_id)
	egen has30_66=max(ageCatHHRisk==2), by(hh_id)
	egen has67Plus=max(ageCatHHRisk==3), by(hh_id)

	*now generate the hhRiskCat variable for each person
	generate hhRiskCat=.
	la var hhRiskCat "Household risk category"
	*Key:
	/*test how to create a variable with the following categories:
			1 SG1 - hh has only 18-29 year olds in it
			2 SG2 - hh has only 30-66 year olds in it
			3 SG3 - hh has only 67+ in it
			4 2G1 - hh has 0-17 and 18-29 in it
			5 2G2 - hh has 0-17 and 30-66 in it
			6 2G3 - hh has 0-17 and 67+ in it
			7 2G4 - hh has 18-29 and 67+ in it
			8 2G5 - hh has 30-66 and 67+ in it
			9 2G6 - hh has 18-29 and 67+ in it
			10 MG1 - hh has 0-17, 18-29 and 30-66 in it
			11 MG2 - hh has 0-17, 18-29 and 67+ in it
			12 MG3 - hh has 0-17, 30-66 and 67+ in it
			13 MG4 - hh has 18-29, 30-66 and 67+ in it
			14 MG5 - hh has 0-17, 18-29, 30-66 and 67+ in it
	*/
	replace hhRiskCat=0 if hasUnder18==1 & has18_29==0 & has30_66==0 & has67Plus==0
	replace hhRiskCat=1 if hasUnder18==0 & has18_29==1 & has30_66==0 & has67Plus==0
	replace hhRiskCat=2 if hasUnder18==0 & has18_29==0 & has30_66==1 & has67Plus==0
	replace hhRiskCat=3 if hasUnder18==0 & has18_29==0 & has30_66==0 & has67Plus==1
	replace hhRiskCat=4 if hasUnder18==1 & has18_29==1 & has30_66==0 & has67Plus==0
	replace hhRiskCat=5 if hasUnder18==1 & has18_29==0 & has30_66==1 & has67Plus==0
	replace hhRiskCat=6 if hasUnder18==1 & has18_29==0 & has30_66==0 & has67Plus==1
	replace hhRiskCat=7 if hasUnder18==0 & has18_29==1 & has30_66==1 & has67Plus==0
	replace hhRiskCat=8 if hasUnder18==0 & has18_29==1 & has30_66==0 & has67Plus==1
	replace hhRiskCat=9 if hasUnder18==0 & has18_29==0 & has30_66==1 & has67Plus==1
	replace hhRiskCat=10 if hasUnder18==1 & has18_29==1 & has30_66==1 & has67Plus==0
	replace hhRiskCat=11 if hasUnder18==1 & has18_29==1 & has30_66==0 & has67Plus==1
	replace hhRiskCat=12 if hasUnder18==1 & has18_29==0 & has30_66==1 & has67Plus==1
	replace hhRiskCat=13 if hasUnder18==0 & has18_29==1 & has30_66==1 & has67Plus==1
	replace hhRiskCat=14 if hasUnder18==1 & has18_29==1 & has30_66==1 & has67Plus==1
	
	*label variable
	label define hhRiskCatLabel 0 "Only <18"  1 "Only 18-29" 2 "Only 30-66" 3 "Only 67+" 4 "0-17 & 18-29" 5 "0-17 & 30-66" 6 "0-17 & 67+" 7 "18-29 & 30-66" 8 "18-29 & 67+" 9 "30-66 & 67+" 10 "0-17, 18-29 & 30-66" 11 "0-17, 18-29 & 67+" 12 "0-17, 30-66 & 67+" 13 "18-29, 30-66 & 67+" 14 "0-17, 18-29, 30-66 & 67+"
	label values hhRiskCat hhRiskCat
	la var hhRiskCat "Age group(s) of hh occupants"
	safetab hhRiskCat, miss
	keep hh_id hhRiskCat
	duplicates drop hh_id, force
	tempfile hhRiskCat
	save `hhRiskCat', replace
restore
merge m:1 hh_id using `hhRiskCat'
drop _merge
safetab hhRiskCat, miss
*missing here are likely to be people living in households made up of only under 18 year olds


*(b) variable for stratifying by the oldest age group (67+)
generate hhRiskCat67PLUS=.
la var hhRiskCat67PLUS "hhRiskCat for the over 67 year old age group"
replace hhRiskCat67PLUS=1 if hhRiskCat==3
replace hhRiskCat67PLUS=2 if hhRiskCat==6
replace hhRiskCat67PLUS=3 if hhRiskCat==8
replace hhRiskCat67PLUS=4 if hhRiskCat==9
replace hhRiskCat67PLUS=5 if hhRiskCat==11
replace hhRiskCat67PLUS=6 if hhRiskCat==12
replace hhRiskCat67PLUS=7 if hhRiskCat==13
replace hhRiskCat67PLUS=8 if hhRiskCat==14
*label variable
label define hhRiskCat67PLUS 1 "Only 67+" 2 "0-17 & 67+" 3 "18-29 & 67+" 4 "30-66 & 67+" 5 "0-17, 18-29 & 67+" 6 "0-17, 30-66 & 67+" 7 "18-29, 30-66 & 67+" 8 "0-17, 18-29, 30-66 & 67+"
label values hhRiskCat67PLUS hhRiskCat67PLUS
safetab hhRiskCat hhRiskCat67PLUS, miss

*create another version that has 4 categories (1) living with only one generation (2) living with one other generation (3) living with two other generations (4) living with three other gens
generate hhRiskCat67PLUS_4cats=.
la var hhRiskCat67PLUS_4cats "hhRiskCat for the over 67 year old age group - 4 categories"
replace hhRiskCat67PLUS_4cats=1 if hhRiskCat67PLUS==1
replace hhRiskCat67PLUS_4cats=2 if hhRiskCat67PLUS>1 & hhRiskCat67PLUS<5
replace hhRiskCat67PLUS_4cats=3 if hhRiskCat67PLUS>4 & hhRiskCat67PLUS<8
replace hhRiskCat67PLUS_4cats=4 if hhRiskCat67PLUS==8
*label variable
label define hhRiskCat67PLUS_4cats 1 "Only 67+" 2 "67+ & 1 other gen" 3 "67+ & 2 other gens" 4 "67+ & 3 other gens"
label values hhRiskCat67PLUS_4cats hhRiskCat67PLUS_4cats
safetab hhRiskCat67PLUS hhRiskCat67PLUS_4cats, miss




****************************
*  Create required cohort  *
****************************

* Age: Exclude those with implausible ages
cap assert age<.
noi di "DROPPING AGE<105:" 
drop if age>105
safecount
* Sex: Exclude categories other than M and F
cap assert inlist(sex, "M", "F", "I", "U")
noi di "DROPPING GENDER NOT M/F:" 
drop if inlist(sex, "I", "U")
safecount

gen male = 1 if sex == "M"
replace male = 0 if sex == "F"
label define male 0"Female" 1"Male"
label values male male
safetab male


* Create binary age (for age stratification)
*recode age min/65.999999999 = 0 ///
*           66/max = 1, gen(age66)

* Check there are no missing ages
*cap assert age < .
*cap assert agegroup < .
*cap assert age66 < .

* Create restricted cubic splines for age
*mkspline age = age, cubic nknots(4)



* Close log file 
log close







							  










/*
*tying up labelling
label variable ageCat "Categorised age (years)"
label define eth5Label 1 "White" 2 "South Asian" 3 "Black" 4 "Mixed" 5 "Other"
label values eth5 eth5Label
label define chronic_respiratory_diseaseLabel 0 "No" 1 "Yes"
label values chronic_respiratory_disease chronic_respiratory_diseaseLabel
label define chronic_cardiac_diseaseLabel 0 "No" 1 "Yes"
label values chronic_cardiac_disease chronic_cardiac_diseaseLabel
label define cancerLabel 0 "No" 1 "Yes"
label values cancer cancerLabel
label define chronic_liver_diseaseLabel 0 "No" 1 "Yes"
label values chronic_liver_disease chronic_liver_diseaseLabel
label define hypertensionLabel 0 "No" 1 "Yes"
label values hypertension hypertensionLabel
label define comorb_NeuroLabel 0 "No" 1 "Yes"
label values comorb_Neuro comorb_NeuroLabel
label define comorb_ImmunosuppressionLabel 0 "No" 1 "Yes"
label values comorb_Immunosuppression comorb_ImmunosuppressionLabel
label define diabetesLabel 0 "No" 1 "Yes"
label values diabetes diabetesLabel
label define imdLabel 1 "1 - least deprived" 2 "2" 3 "3" 4 "4" 5 "5 - most deprived", replace
label values imd imdLabel
label define bmicatLabel 1 "Underweight" 2 "Normal" 3 "Overweight" 4 "Obese I" 5 "Obese II" 6 "Obese III"
label values bmicat bmicatLabel




save hhClassif_analysis_dataset.dta, replace



*extra code I don't needed
/*



*create household composition variable for transmission model study
*edited dataset that only contains variables that will be used in the regression analysis (and were for shared in dummydata with Thomas and Heather)
*create the age variable that I want
egen ageCat=cut(age), at (0, 5, 10, 15, 20, 30, 40, 50, 60, 70, 80, 90, 120)
recode ageCat 0=1 5=2 10=3 15=4 20=5 30=6 40=7 50=8 60=9 70=10 80=11 90=12 
label define ageCatLabel 1 "0-4" 2 "5-9" 3 "10-14" 4 "15-19" 5 "20-29" 6 "30-39" 7 "40-49" 8 "50-59" 9 "60-69" 10 "70-79" 11 "80-89" 12 "90+"
label values ageCat ageCatLabel
safetab ageCat, miss
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
safetab hh_composition

*create a key for the hh composition variable
preserve
    describe, replace clear
    list
    export excel using hhCompositionKey.xlsx, replace first(var)
restore




/*

****************************************************************
*  Create outcome specific datasets for the whole population  *
*****************************************************************


foreach i of global outcomes {
	use "$Tempdir/analysis_dataset.dta", clear
	
	drop if `i'_date <= indexdate 

	stset stime_`i', fail(`i') 				///	
	id(patient_id) enter(indexdate) origin(indexdate)
	save "$Tempdir/analysis_dataset_STSET_`i'.dta", replace
}	


****************************************************************
*  Create outcome specific datasets for those with evidence of infection  *
*****************************************************************
use "$Tempdir/analysis_dataset.dta", clear

keep if confirmed==1 | positivetest==1
safecount
gen infected_date=min(confirmed_date, positivetest_date)
save "$Tempdir/analysis_dataset_infected.dta", replace

foreach i of global outcomes2 {
	use "$Tempdir/analysis_dataset_infected.dta", clear
	
	drop if `i'_date <= infected_date 

	stset stime_`i', fail(`i') 				///	
	id(patient_id) enter(infected_date) origin(infected_date)
	save "$Tempdir/analysis_dataset_STSET_`i'_infected.dta", replace
}	

	
* Close log file 
log close

