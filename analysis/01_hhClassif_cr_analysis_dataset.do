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


sysdir set PLUS "/Users/kw/Documents/GitHub/households-research/analysis/adofiles" 
sysdir set PERSONAL "/Users/kw/Documents/GitHub/households-research/analysis/adofiles" 

							
==============================================================================*/
sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles
pwd
import delimited ./output/input.csv, clear


*Both server and local
* Open a log file
cap log close
log using ./released_outputs/01_hhClassif_cr_analysis_dataset.log, replace t



di "STARTING safecount FROM IMPORT:"
safecount

*Start dates
gen index 			= "01/02/2020"

* Date of cohort entry, 1 Feb 2020
gen indexdate = date(index, "DMY")
format indexdate %d


*******************************************************************************



/* CREATE VARIABLES===========================================================*/

/* DEMOGRAPHICS */ 

* Ethnicity (5 category)
replace ethnicity = . if ethnicity==.
label define ethnicity 	1 "White"  					///
						2 "Mixed" 					///
						3 "Asian or Asian British"	///
						4 "Black"  					///
						5 "Other"					
						
label values ethnicity ethnicity
safetab ethnicity

 *re-order ethnicity
 gen eth5=1 if ethnicity==1
 replace eth5=2 if ethnicity==3
 replace eth5=3 if ethnicity==4
 replace eth5=4 if ethnicity==2
 replace eth5=5 if ethnicity==5
 replace eth5=. if ethnicity==.

 label define eth5	 	1 "White"  					///
						2 "South Asian"				///						
						3 "Black"  					///
						4 "Mixed"					///
						5 "Other"					
					

label values eth5 eth5
safetab eth5, m



* Ethnicity (16 category)
replace ethnicity_16 = . if ethnicity==.
label define ethnicity_16 									///
						1 "British or Mixed British" 		///
						2 "Irish" 							///
						3 "Other White" 					///
						4 "White + Black Caribbean" 		///
						5 "White + Black African"			///
						6 "White + Asian" 					///
 						7 "Other mixed" 					///
						8 "Indian or British Indian" 		///
						9 "Pakistani or British Pakistani" 	///
						10 "Bangladeshi or British Bangladeshi" ///
						11 "Other Asian" 					///
						12 "Caribbean" 						///
						13 "African" 						///
						14 "Other Black" 					///
						15 "Chinese" 						///
						16 "Other" 							
						
label values ethnicity_16 ethnicity_16
safetab ethnicity_16,m


* Ethnicity (16 category grouped further)
* Generate a version of the full breakdown with mixed in one group
gen eth16 = ethnicity_16
recode eth16 4/7 = 99
recode eth16 11 = 16
recode eth16 14 = 16
recode eth16 8 = 4
recode eth16 9 = 5
recode eth16 10 = 6
recode eth16 12 = 7
recode eth16 13 = 8
recode eth16 15 = 9
recode eth16 99 = 10
recode eth16 16 = 11





label define eth16 	///
						1 "British" ///
						2 "Irish" ///
						3 "Other White" ///
						4 "Indian" ///
						5 "Pakistani" ///
						6 "Bangladeshi" ///					
						7 "Caribbean" ///
						8 "African" ///
						9 "Chinese" ///
						10 "All mixed" ///
						11 "All Other" 
label values eth16 eth16
safetab eth16,m



* STP 
rename stp stp_old
bysort stp_old: gen stp = 1 if _n==1
replace stp = sum(stp)
drop stp_old

/*  IMD  */
* Group into 5 groups
rename imd imd_o
egen imd = cut(imd_o), group(5) icodes

* add one to create groups 1 - 5 
replace imd = imd + 1

* - 1 is missing, should be excluded from population 
replace imd = .u if imd_o == -1
drop imd_o

* Reverse the order (so high is more deprived)
recode imd 5 = 1 4 = 2 3 = 3 2 = 4 1 = 5 .u = .u

label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" .u "Unknown"
label values imd imd 

/*  Age variables  */ 

* Create categorised age 
recode age 	0/17.9999=0 ///
			18/29.9999 = 1 /// 
		    30/39.9999 = 2 /// 
			40/49.9999 = 3 ///
			50/59.9999 = 4 ///
			60/69.9999 = 5 ///
			70/79.9999 = 6 ///
			80/max = 7, gen(agegroup) 

label define agegroup 	0 "0-<18" ///
						1 "18-<30" ///
						2 "30-<40" ///
						3 "40-<50" ///
						4 "50-<60" ///
						5 "60-<70" ///
						6 "70-<80" ///
						7 "80+"
						
label values agegroup agegroup






**************************** HOUSEHOLD VARS*******************************************
*update with UPRN data

*sum hh_total hh_size
rename household_id hh_id
rename household_size hh_size

*gen categories of household size - KW will use actual household sizes in analysis but will leave this in so easy to find where it is used in Rohini analysis files.
gen hh_total_cat=.
replace hh_total_cat=1 if hh_size >=1 & hh_size<=2
replace hh_total_cat=2 if hh_size >=3 & hh_size<=5
replace hh_total_cat=3 if hh_size >=6 & hh_size<=10
replace hh_total_cat=4 if hh_size >=11
		
/* Rohini code - I think I want to drop them completely rather than just not include in a derived household variable
Note that U=private home, PC=care home, PN=nursing home, PS=care or nursing home, ""=unknown
*remove people from hh_cat if they live in a care home
replace hh_total_cat=. if care_home_type!="U"
*/
*keep only private homes
drop if care_home_type!="U"
			
label define hh_total_cat 1 "1-2" ///
						2 "3-5" ///
						3 "6-10" ///
						4 "11+"
											
label values hh_total_cat hh_total_cat

safetab hh_total_cat,m
safetab hh_total_cat care_home_type,m

safetab hh_size hh_total_cat,m

*drop households we don't need i.e. 1 or smaller or larger than 10
drop if hh_size<=1
drop if hh_size>10
safetab hh_size





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
recode ageCatHHRisk 0=1 18=2 30=3 67=4 
label define ageCatHHRiskLabel 1 "0-17" 2 "18-29" 3 "30-66" 4 "67+"
label values ageCatHHRisk ageCatHHRiskLabel
safetab ageCatHHRisk, miss
la var ageCatHHRisk "Age categorised for HH risk analysis"

preserve
	*keep only the variables I need to work this out
	keep hh_id patient_id ageCatHHRisk
	sort hh_id ageCatHHRisk

	*mark whether hh has each age category using egen max which returns true (1) or false (0) (see https://www.stata.com/support/faqs/data-management/create-variable-recording/)
	egen hasUnder18=max(ageCatHHRisk==1), by(hh_id)
	egen has18_29=max(ageCatHHRisk==2), by(hh_id)
	egen has30_66=max(ageCatHHRisk==3), by(hh_id)
	egen has67Plus=max(ageCatHHRisk==4), by(hh_id)

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
	label define hhRiskCatLabel 0 "Only <18"  1 "Only 18-29" 2 "Only 30-66" 3 "Only 67+" 4 "0-17 with 18-29" 5 "0-17 with 30-66" 6 "0-17 with 67+" 7 "18-29 with 30-66" 8 "18-29 with 67+" 9 "30-66 with 67+" 10 "0-17, 18-29 and 30-66" 11 "0-17, 18-29 and 67+" 12 "0-17, 30-66 and 67+" 13 "18-29, 30-66 and 67+" 14 "0-17, 18-29, 30-66 and 67+"
	label values hhRiskCat hhRiskCatLabel
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

*now create other exposure variables related to this i.e. (a) the high level broad categories for descriptive analysis and (b) the age-stratified categories
*(a) high level broad categories from protocol
generate hhRiskCatBROAD=.
la var hhRiskCatBROAD "hhRiskCat in three categories (for descriptive work)"
replace hhRiskCatBROAD=1 if hhRiskCat>=1 & hhRiskCat<=3
replace hhRiskCatBROAD=2 if hhRiskCat>=4 & hhRiskCat<=9
replace hhRiskCatBROAD=3 if hhRiskCat>=10 & hhRiskCat<=14
*label variable
label define hhRiskCatBROADLabel 1 "HH of single generation" 2 "HH with two generations" 3 "MG household"
label values hhRiskCatBROAD hhRiskCatBROADLabel
safetab hhRiskCatBROAD hhRiskCat

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
label define hhRiskCat67PLUS 1 "Only 67+" 2 "0-17 with 67+" 3 "18-29 with 67+" 4 "30-66 with 67+" 5 "0-17, 18-29 and 67+" 6 "0-17, 30-66 and 67+" 7 "18-29, 30-66 and 67+" 8 "0-17, 18-29, 30-66 and 67+"
label values hhRiskCat67PLUS hhRiskCat67PLUS
safetab hhRiskCat hhRiskCat67PLUS 


*(b) variable for stratifying by the 30-66 year olds 
generate hhRiskCat33TO66=.
la var hhRiskCat33TO66 "hhRiskCat for the 30-66 year old age group"
replace hhRiskCat33TO66=1 if hhRiskCat==2
replace hhRiskCat33TO66=2 if hhRiskCat==5
replace hhRiskCat33TO66=3 if hhRiskCat==7
replace hhRiskCat33TO66=4 if hhRiskCat==9
replace hhRiskCat33TO66=5 if hhRiskCat==10
replace hhRiskCat33TO66=6 if hhRiskCat==12
replace hhRiskCat33TO66=7 if hhRiskCat==13
replace hhRiskCat33TO66=8 if hhRiskCat==14
*label variable
label define hhRiskCat33TO66 1 "Only 30-66" 2 "0-17 with 30-66" 3 "18-29 with 30-66" 4 "30-66 with 67+" 5 "0-17, 18-29 and 30-66" 6 "0-17, 30-66 and 67+" 7 "18-29, 30-66 and 67+" 8 "0-17, 18-29, 30-66 and 67+"
label values hhRiskCat33TO66 hhRiskCat33TO66
safetab hhRiskCat hhRiskCat33TO66 


*(c) variable for stratifying by the 18-29 year olds 
generate hhRiskCat18TO29=.
la var hhRiskCat18TO29 "hhRiskCat for the 18-29 year old age group"
replace hhRiskCat18TO29=1 if hhRiskCat==1
replace hhRiskCat18TO29=2 if hhRiskCat==4
replace hhRiskCat18TO29=3 if hhRiskCat==7
replace hhRiskCat18TO29=4 if hhRiskCat==8
replace hhRiskCat18TO29=5 if hhRiskCat==10
replace hhRiskCat18TO29=6 if hhRiskCat==11
replace hhRiskCat18TO29=7 if hhRiskCat==13
replace hhRiskCat18TO29=8 if hhRiskCat==14
*label variable
label define hhRiskCat18TO29 1 "Only 18-29" 2 "0-17 with 18-29" 3 "18-29 with 30-66" 4 "18-29 with 67+" 5 "0-17, 18-29 and 30-66" 6 "0-17, 18-29 and 67+" 7 "18-29, 30-66 and 67+" 8 "0-17, 18-29, 30-66 and 67+"
label values hhRiskCat18TO29 hhRiskCat18TO29
safetab hhRiskCat hhRiskCat18TO29 



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
recode age min/65.999999999 = 0 ///
           66/max = 1, gen(age66)

* Check there are no missing ages
cap assert age < .
cap assert agegroup < .
cap assert age66 < .

* Create restricted cubic splines for age
mkspline age = age, cubic nknots(4)


/* CONVERT STRINGS TO DATE====================================================*/
/* Comorb dates dates are given with month only, so adding day 
15 to enable  them to be processed as dates 			  */

*cr date for diabetes based on adjudicated type
gen diabetes=type1_diabetes if diabetes_type=="T1DM"
replace diabetes=type2_diabetes if diabetes_type=="T2DM"
replace diabetes=unknown_diabetes if diabetes_type=="UNKNOWN_DM"

drop type1_diabetes type2_diabetes unknown_diabetes

foreach var of varlist 	chronic_respiratory_disease ///
						chronic_cardiac_disease  ///
						cancer_haem  ///
						cancer_nonhaem ///
						permanent_immunodeficiency  ///
						temporary_immunodeficiency  ///
						chronic_liver_disease  ///
						other_neuro  ///
						stroke_dementia ///
						esrf  ///
						hypertension  ///
						asthma ///
						ra_sle_psoriasis  ///
						diabetes ///
						bmi_date_measured   ///
						bp_sys_date_measured   ///
						bp_dias_date_measured   ///
						creatinine_date  ///
						hba1c_mmol_per_mol_date  ///
						hba1c_percentage_date ///
						smoking_status_date ///					
						{
							
		capture confirm string variable `var'
		if _rc!=0 {
			cap assert `var'==.
			rename `var' `var'_date
		}
	
		else {
				replace `var' = `var' + "-15"
				rename `var' `var'_dstr
				replace `var'_dstr = " " if `var'_dstr == "-15"
				gen `var'_date = date(`var'_dstr, "YMD") 
				order `var'_date, after(`var'_dstr)
				drop `var'_dstr
		}
	
	format `var'_date %td
}

* Note - outcome dates are handled separtely below 

* Some names too long for loops below, shorten
rename permanent_immunodeficiency_date 	perm_immunodef_date
rename temporary_immunodeficiency_date 	temp_immunodef_date
rename bmi_date_measured_date  			bmi_measured_date

/* CREATE BINARY VARIABLES====================================================*/
*  Make indicator variables for all conditions where relevant 

foreach var of varlist 	chronic_respiratory_disease ///
						chronic_cardiac_disease  ///
						cancer_haem  ///
						cancer_nonhaem  ///
						perm_immunodef  ///
						temp_immunodef  ///
						chronic_liver_disease  ///
						other_neuro  ///
						stroke_dementia ///
						esrf  ///
						hypertension  ///
						asthma ///
						ra_sle_psoriasis  ///
						bmi_measured_date   ///
						bp_sys_date_measured   ///
						bp_dias_date_measured   ///
						creatinine_date  ///
						hba1c_mmol_per_mol_date  ///
						hba1c_percentage_date ///
						smoking_status_date ///
						{
						
	/* date ranges are applied in python, so presence of date indicates presence of 
	  disease in the correct time frame */ 
	local newvar =  substr("`var'", 1, length("`var'") - 5)
	gen `newvar' = (`var'!=. )
	order `newvar', after(`var')
	safetab `newvar'
	
}


/*  Body Mass Index  */
* NB: watch for missingness

* Recode strange values 
replace bmi = . if bmi == 0 
replace bmi = . if !inrange(bmi, 15, 50)

* Restrict to within 10 years of index and aged > 16 
gen bmi_time = (indexdate - bmi_measured_date)/365.25
gen bmi_age = age - bmi_time

replace bmi = . if bmi_age < 16 
replace bmi = . if bmi_time > 10 & bmi_time != . 

* Set to missing if no date, and vice versa 
replace bmi = . if bmi_measured_date == . 
replace bmi_measured_date = . if bmi == . 
replace bmi_measured = . if bmi == . 

* BMI (NB: watch for missingness)
gen 	bmicat = .
recode  bmicat . = 1 if bmi<18.5
recode  bmicat . = 2 if bmi<25
recode  bmicat . = 3 if bmi<30
recode  bmicat . = 4 if bmi<35
recode  bmicat . = 5 if bmi<40
recode  bmicat . = 6 if bmi<.
replace bmicat = .u if bmi>=.

label define bmicat 1 "Underweight (<18.5)" 	///
					2 "Normal (18.5-24.9)"		///
					3 "Overweight (25-29.9)"	///
					4 "Obese I (30-34.9)"		///
					5 "Obese II (35-39.9)"		///
					6 "Obese III (40+)"			///
					.u "Unknown (.u)"
label values bmicat bmicat

* Create more granular categorisation
recode bmicat 1/3 .u = 1 4=2 5=3 6=4, gen(obese4cat)

label define obese4cat 	1 "No record of obesity" 	///
						2 "Obese I (30-34.9)"		///
						3 "Obese II (35-39.9)"		///
						4 "Obese III (40+)"		
label values obese4cat obese4cat
order obese4cat, after(bmicat)



**generate BMI categories for south asians
*https://www.nice.org.uk/guidance/ph46/chapter/1-Recommendations#recommendation-2-bmi-assessment-multi-component-interventions-and-best-practice-standards

gen bmicat_sa=bmicat
replace bmicat_sa = 2 if bmi>=18.5 & bmi <23 & ethnicity  ==3
replace bmicat_sa = 3 if bmi>=23 & bmi < 27.5 & ethnicity ==3
replace bmicat_sa = 4 if bmi>=27.5 & bmi < 32.5 & ethnicity ==3
replace bmicat_sa = 5 if bmi>=32.5 & bmi < 37.5 & ethnicity ==3
replace bmicat_sa = 6 if bmi>=37.5 & bmi < . & ethnicity ==3

safetab bmicat_sa

label define bmicat_sa 1 "Underweight (<18.5)" 	///
					2 "Normal (18.5-24.9 / 22.9)"		///
					3 "Overweight (25-29.9 / 23-27.4)"	///
					4 "Obese I (30-34.9 / 27.4-32.4)"		///
					5 "Obese II (35-39.9 / 32.5- 37.4)"		///
					6 "Obese III (40+ / 37.5+)"			///
					.u "Unknown (.u)"
label values bmicat bmicat

* Create more granular categorisation
recode bmicat_sa 1/3 .u = 1 4=2 5=3 6=4, gen(obese4cat_sa)

label define obese4cat_sa 	1 "No record of obesity" 	///
						2 "Obese I (30-34.9 / 27.5-32.5)"		///
						3 "Obese II (35-39.9 / 32.5- 37.4)"		///
						4 "Obese III (40+ / 37.5+)"		
label values obese4cat_sa obese4cat_sa
order obese4cat_sa, after(bmicat_sa)


/*  Smoking  */

* Smoking 
label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Unknown (.u)"

gen     smoke = 1  if smoking_status == "N"
replace smoke = 2  if smoking_status == "E"
replace smoke = 3  if smoking_status == "S"
replace smoke = .u if smoking_status == "M"
replace smoke = .u if smoking_status == "" 

label values smoke smoke
drop smoking_status

* Create non-missing 3-category variable for current smoking
* Assumes missing smoking is never smoking 
recode smoke .u = 1, gen(smoke_nomiss)
order smoke_nomiss, after(smoke)
label values smoke_nomiss smoke

/* CLINICAL COMORBIDITIES */ 

/*  Cancer */
label define cancer 1 "Never" 2 "Last year" 3 "2-5 years ago" 4 "5+ years"

* malignancies
gen     cancer_cat = 4 if inrange(cancer_haem_date, d(1/1/1900), d(1/2/2015))|inrange(cancer_nonhaem_date, d(1/1/1900), d(1/2/2015))
replace cancer_cat = 3 if inrange(cancer_haem_date, d(1/2/2015), d(1/2/2019))|inrange(cancer_nonhaem_date, d(1/2/2015), d(1/2/2019))
replace cancer_cat = 2 if inrange(cancer_haem_date, d(1/2/2019), d(1/2/2020))|inrange(cancer_nonhaem_date, d(1/2/2019), d(1/2/2020))
recode  cancer_cat . = 1
label values cancer_cat cancer




/*  Immunosuppression  */

* Immunosuppressed:
* Permanent immunodeficiency ever, OR 
* Temporary immunodeficiency  last year
gen temp1  = 1 if perm_immunodef_date!=.
gen temp2  = inrange(temp_immunodef_date, (indexdate - 365), indexdate)

egen other_immuno = rowmax(temp1 temp2)
drop temp1 temp2 
order other_immuno, after(temp_immunodef)

/*  Blood pressure   */

* Categorise
gen     bpcat = 1 if bp_sys < 120 &  bp_dias < 80
replace bpcat = 2 if inrange(bp_sys, 120, 130) & bp_dias<80
replace bpcat = 3 if inrange(bp_sys, 130, 140) | inrange(bp_dias, 80, 90)
replace bpcat = 4 if (bp_sys>=140 & bp_sys<.) | (bp_dias>=90 & bp_dias<.) 
replace bpcat = .u if bp_sys>=. | bp_dias>=. | bp_sys==0 | bp_dias==0

label define bpcat 1 "Normal" 2 "Elevated" 3 "High, stage I"	///
					4 "High, stage II" .u "Unknown"
label values bpcat bpcat

recode bpcat .u=1, gen(bpcat_nomiss)
label values bpcat_nomiss bpcat

* Create non-missing indicator of known high blood pressure
gen bphigh = (bpcat==4)

/*  Hypertension  */

gen htdiag_or_highbp = bphigh
recode htdiag_or_highbp 0 = 1 if hypertension==1 


************
*   eGFR   *
************

* Set implausible creatinine values to missing (Note: zero changed to missing)
replace creatinine = . if !inrange(creatinine, 20, 3000) 
	
* Divide by 88.4 (to convert umol/l to mg/dl)
gen SCr_adj = creatinine/88.4

gen min=.
replace min = SCr_adj/0.7 if male==0
replace min = SCr_adj/0.9 if male==1
replace min = min^-0.329  if male==0
replace min = min^-0.411  if male==1
replace min = 1 if min<1

gen max=.
replace max=SCr_adj/0.7 if male==0
replace max=SCr_adj/0.9 if male==1
replace max=max^-1.209
replace max=1 if max>1

gen egfr=min*max*141
replace egfr=egfr*(0.993^age)
replace egfr=egfr*1.018 if male==0
label var egfr "egfr calculated using CKD-EPI formula with no eth"

* Categorise into ckd stages
egen egfr_cat = cut(egfr), at(0, 30, 60, 5000)

label define egfr_cat 5000 "None" 60 "Stage 3 egfr 30-6" 30 "Stage 4/5 egfr<30"
label values egfr_cat egfr_cat 
lab var  egfr_cat "CKD category"
safetab egfr_cat

gen egfr60=0
replace egfr60=1 if egfr<60
lab define egfr60 0"egfr >=60" 1"eGFR <60"
label values egfr60 egfr60
safetab egfr60

/* Hb1AC */

/*  Diabetes severity  */

* Set zero or negative to missing
replace hba1c_percentage   = . if hba1c_percentage <= 0
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol <= 0

/* Express  HbA1c as percentage  */ 

* Express all values as perecentage 
noi summ hba1c_percentage hba1c_mmol_per_mol 
gen 	hba1c_pct = hba1c_percentage 
replace hba1c_pct = (hba1c_mmol_per_mol/10.929)+2.15 if hba1c_mmol_per_mol<. 

* Valid % range between 0-20  /195 mmol/mol
replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
replace hba1c_pct = round(hba1c_pct, 0.1)


/* Categorise hba1c and diabetes  */
/* Diabetes type */
gen dm_type=1 if diabetes_type=="T1DM"
replace dm_type=2 if diabetes_type=="T2DM"
replace dm_type=3 if diabetes_type=="UNKNOWN_DM"
replace dm_type=0 if diabetes_type=="NO_DM"

safetab dm_type diabetes_type
label define dm_type 0"No DM" 1"T1DM" 2"T2DM" 3"UNKNOWN_DM"
label values dm_type dm_type

*Open safely diabetes codes with exeter algorithm
gen dm_type_exeter_os=1 if diabetes_exeter_os=="T1DM_EX_OS"
replace dm_type_exeter_os=2 if diabetes_exeter_os=="T2DM_EX_OS"
replace dm_type_exeter_os=0 if diabetes_exeter_os=="NO_DM"
label values  dm_type_exeter_os dm_type

* Group hba1c
gen 	hba1ccat = 0 if hba1c_pct <  6.5
replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.
label define hba1ccat 0 "<6.5%" 1">=6.5-7.4" 2">=7.5-7.9" 3">=8-8.9" 4">=9"
label values hba1ccat hba1ccat
safetab hba1ccat

gen hba1c75=0 if hba1c_pct<7.5
replace hba1c75=1 if hba1c_pct>=7.5 & hba1c_pct!=.
label define hba1c75 0"<7.5" 1">=7.5"
safetab hba1c75, m

* Create diabetes, split by control/not
gen     diabcat = 1 if dm_type==0
replace diabcat = 2 if dm_type==1 & inlist(hba1ccat, 0, 1)
replace diabcat = 3 if dm_type==1 & inlist(hba1ccat, 2, 3, 4)
replace diabcat = 4 if dm_type==2 & inlist(hba1ccat, 0, 1)
replace diabcat = 5 if dm_type==2 & inlist(hba1ccat, 2, 3, 4)
replace diabcat = 6 if dm_type==1 & hba1c_pct==. | dm_type==2 & hba1c_pct==.


label define diabcat 	1 "No diabetes" 			///
						2 "T1DM, controlled"		///
						3 "T1DM, uncontrolled" 		///
						4 "T2DM, controlled"		///
						5 "T2DM, uncontrolled"		///
						6 "Diabetes, no HbA1c"
label values diabcat diabcat
safetab diabcat, m

/*  Asthma  */
* Asthma  (coded: 0 No, 1 Yes no OCS, 2 Yes with OCS)
rename asthma asthmacat
recode asthmacat 0=1 1=2 2=3
label define asthmacat 1 "No" 2 "Yes, no OCS" 3 "Yes with OCS"
label values asthmacat asthmacat

gen asthma = (asthmacat==2|asthmacat==3)

/*
**care home
encode care_home_type, gen(carehometype)
drop care_home_type

gen carehome=0
replace carehome=1 if carehometype<4
safetab  carehometype carehome
*/

/* OUTCOME (AND SURVIVAL TIME)==================================================*/
/*
Outcome summary: 
 
*/

*Think we only need the outcome that is the 3 primary types of probable primary care codes

/*
*UP TO HERE WED EVENING - NEED TO UPDATE THE CASE SECTION SO IT REFLECTS THE CASE DEFINITIONS THAT I NEED IE:
1. COVID death
2. COVID hospitalisation
3. non-COVID death
4. (Fracture)
*/

/* CONVERT STRINGS TO DATE FOR OUTCOME VARIABLES =============================*/
* Recode to dates from the strings 
order first_tested_for_covid first_positive_test_date died_date_ons died_date_cpns covid_tpp_probable covid_tpp_probableclindiag covid_tpp_probabletest covid_tpp_probableseq covid_admission_date positive_covid_test_ever

foreach var of varlist first_tested_for_covid - covid_admission_date {
	confirm string variable `var'
	rename `var' `var'_dstr
	gen `var' = date(`var'_dstr, "YMD")
	drop `var'_dstr
	format `var' %td 

}



*1. COVID death outcome
generate covidDeathCase=0
replace covidDeathCase=1 if died_ons_covid_flag_any==1|died_ons_covid_flag_underlying==1|died_date_cpns!=.
la var covidDeathCase "Case based on ONS or CPNS covid death record"
generate covidDeathCaseDate=.
replace covidDeathCaseDate=min(died_date_ons, died_date_cpns) if covidDeathCase==1
la var covidDeathCaseDate "Date of case based on ONS or CPNS death record"
format covidDeathCaseDate %td

*2. COVID hospitalisation outcome
generate covidHospCase=0
replace covidHospCase=1 if covid_admission_date!=.
la var covidHospCase "Case based on hospitalisation with COVID"
generate covidHospCaseDate=.
replace covidHospCaseDate=covid_admission_date if covidHospCase==1
la var covidHospCaseDate "Date of case based COVID admission date"
format covidHospCaseDate %td

*3. Non-COVID death outcome
generate nonCOVIDDeathCase=0
replace nonCOVIDDeathCase=1 if covidDeathCase==0 & died_date_ons!=. & died_date_cpns!=.
la var nonCOVIDDeathCase "Died from non-COVID causes"
generate nonCOVIDDeathCaseDate=.
replace nonCOVIDDeathCaseDate=min(died_date_ons, died_date_cpns) if nonCOVIDDeathCaseDate==1
la var nonCOVIDDeathCaseDate "Date of non-COVID death"
format nonCOVIDDeathCaseDate %td

*3. Fracture - to do


*create a list of the outcomes for reuse
global outcomes covidDeathCase covidHospCase nonCOVIDDeathCase

/*
*create a total number of cases in the household variable
bysort hh_id:egen totCasesInHH=total(case)
la var totCasesInHH "Total number of cases in a specific household"
*/
	
/*
* Date of Covid death in ONS
gen onscoviddeath_date = onsdeath_date if died_ons_covid_flag_any == 1
gen onsconfirmeddeath_date = onsdeath_date if died_ons_confirmedcovid_flag_any ==1
gen onssuspecteddeath_date = onsdeath_date if died_ons_suspectedcovid_flag_any ==1
*/

/*
* Date of non-COVID death in ONS 
* If missing date of death resulting died_date will also be missing
gen ons_noncoviddeath_date = onsdeath_date if died_ons_covid_flag_any != 1
*/



*Date of first severe outcome
*replace severe_date = min(ae_date, icu_date, onscoviddeath_date)

*If outcome occurs on the first day of follow-up add one day
foreach i of global outcomes  {
	di "`i'"
	count if `i'Date==indexdate
	replace `i'Date=`i'Date+1 if `i'Date==indexdate
}
*date of deregistration
rename dereg_date dereg_dstr
	gen dereg_date = date(dereg_dstr, "YMD")
	drop dereg_dstr
	format dereg_date %td 

	/*
* Binary indicators for outcomes - have these already
foreach i of global outcomes {
		gen `i'=0
		replace  `i'=1 if `i'_date < .
		safetab `i'
}
*/

*order patient_id age hh_id hh_size case case_date ethnicity

*update case variable so that those wwho died of confirmed covid are also considered cases

*drop severe
*gen severe=1 if ae==1 | icu==1 | onscoviddeath==1


/* CENSORING */
/* SET FU DATES===============================================================*/ 

* Censoring dates for each outcome (last date outcome data available) - kw note: these are what were included for Rohini ethnicity (copied wed 12th Aug, may need updated).
*https://github.com/opensafely/rapid-reports/blob/master/notebooks/latest-dates.ipynb
gen censor_date = d("01/12/2020")


*******************************************************************************
format *censor_date %d
sum *censor_date, format

*******************************
*  Recode implausible values  *
*******************************


* BMI 
* Set implausible BMIs to missing:
replace bmi = . if !inrange(bmi, 15, 50)


/**** Create survival times  ****/

* For looping later, name must be stime_binary_outcome_name

* Survival time = last followup date (first: deregistration date, end study, death, or that outcome)
*Ventilation does not have a survival time because it is a yes/no flag
foreach i of global outcomes {
	gen stime_`i' = min(censor_date, died_date_ons, `i'Date, dereg_date)
}

* If outcome date occurs after censoring, set outcome to zero
foreach i of global outcomes {
	replace `i'=0 if `i'Date>stime_`i'
	safetab `i'
}

* Format date variables
format  stime* %td 

********UP TO HERE THU 21:20********


*distribution of outcome dates
foreach i of global outcomes {
	capture histogram `i'Date, discrete width(15) frequency ytitle(`i') xtitle(Date) scheme(meta) 
	capture graph export "./output/outcome_`i'_freq.svg", as(svg) replace
}



/* LABEL VARIABLES============================================================*/
*  Label variables you are intending to keep, drop the rest 

*HH variable
label var  hh_size "# people in household"
label var  hh_id "Household ID"
label var hh_total "# people in household calculated"
label var hh_total_cat "Number of people in household"

* Demographics
label var patient_id				"Patient ID"
label var age 						"Age (years)"
label var agegroup					"Grouped age"
label var age66 					"66 years and older"
label var sex 						"Sex"
label var male 						"Male"
label var bmi 						"Body Mass Index (BMI, kg/m2)"
label var bmicat 					"BMI"
label var bmicat_sa					"BMI with SA categories"
label var bmi_measured_date  		"Body Mass Index (BMI, kg/m2), date measured"
label var obese4cat					"Obesity (4 categories)"
label var obese4cat_sa				"Obesity with SA categories"
label var smoke		 				"Smoking status"
label var smoke_nomiss	 			"Smoking status (missing set to non)"
label var imd 						"Index of Multiple Deprivation (IMD)"
label var eth5						"Eth 5 categories"
label var ethnicity_16				"Eth 16 categories"
label var eth16						"Eth 16 collapsed"
label var stp 						"Sustainability and Transformation Partnership"
label var age1 						"Age spline 1"
label var age2 						"Age spline 2"
label var age3 						"Age spline 3"
lab var hh_total					"calculated No of ppl in household"
lab var region						"Region of England"
lab var rural_urban					"Rural-Urban Indicator"
*lab var carehome					"Care home y/n"
lab var hba1c_mmol_per_mol			"HbA1c mmo/mol"
lab var hba1c_percentage			"HbA1c %"
*lab var gp_consult_count			"Number of GP consultations in the 12 months prior to baseline"

* Comorbidities of interest 
label var asthma						"Asthma category"
lab var asthmacat						"Asthma detailed categories"
label var hypertension				    "Diagnosed hypertension"
label var chronic_respiratory_disease 	"Chronic Respiratory Diseases"
label var chronic_cardiac_disease 		"Chronic Cardiac Diseases"
label var dm_type						"Diabetes Type"
label var dm_type_exeter_os				"Diabetes type (Exeter definition)"
label var cancer_cat						"Cancer"
label var other_immuno					"Immunosuppressed (combination algorithm)"
label var chronic_liver_disease 		"Chronic liver disease"
label var other_neuro 					"Neurological disease"			
label var stroke_dementia		 		"Stroke or dementia"
*lab var dementia						"Dementia"							
label var ra_sle_psoriasis				"Autoimmune disease"
lab var egfr							"eGFR"
lab var egfr_cat						"CKD category defined by eGFR"
lab var egfr60							"CKD defined by egfr<60"
lab var perm_immunodef  				"Permanent immunosuppression"
lab var temp_immunodef  				"Temporary immunosuppression"
lab var  bphigh 						"non-missing indicator of known high blood pressure"
lab var bpcat 							"Blood pressure four levels, non-missing"
lab var htdiag_or_highbp 				"High blood pressure or hypertension diagnosis"
lab var esrf 							"end stage renal failure"
lab var asthma_date 						"Diagnosed Asthma Date"
label var hypertension_date			   		"Diagnosed hypertension Date"
label var chronic_respiratory_disease_date 	"Other Respiratory Diseases Date"
label var chronic_cardiac_disease_date		"Other Heart Diseases Date"
label var diabetes_date						"Diabetes Date"
*label var cancer_date 						"Cancer Date"
label var chronic_liver_disease_date  		"Chronic liver disease Date"
label var other_neuro_date 					"Neurological disease  Date"
label var stroke_dementia_date			    		"Stroke date"		
label var ra_sle_psoriasis_date 			"Autoimmune disease  Date"
lab var perm_immunodef_date  				"Permanent immunosuppression date"
lab var temp_immunodef_date   				"Temporary immunosuppression date"
lab var esrf_date 							"end stage renal failure"
lab var hba1c_percentage_date				"HbA1c % date"
lab var hba1c_pct							"HbA1c %"
lab var hba1ccat							"HbA1c category"
lab var hba1c75								"HbA1c >= 7.5%"
lab var diabcat								"Diabetes and HbA1c combined" 
lab var organ_transplant					"Organ transplant"
lab var asplenia							"Asplenia"


*medications
/*
lab var statin								"Statin in last 12 months"
lab var insulin								"Insulin in last 12 months"
lab var alpha_blockers 						"Alpha blocker in last 12 months"
lab var arbs 								"ARB in last 12 months"
lab var besafetablockers 						"Beta blocker in last 12 months"
lab var calcium_channel_blockers 			"CCB in last 12 months"
lab var combination_bp_meds 				"BP med in last 12 months"
lab var spironolactone 						"Spironolactone in last 12 months"
lab var thiazide_diuretics					"TZD in last 12 months"

lab var statin_date							"Statin in last 12 months"
lab var insulin_date						"Insulin in last 12 months"
lab var ace_inhibitors_date 				"ACE in last 12 months"
lab var alpha_blockers_date 				"Alpha blocker in last 12 months"
lab var arbs_date 							"ARB in last 12 months"
lab var besafetablockers_date 					"Beta blocker in last 12 months"
lab var calcium_channel_blockers_date 		"CCB in last 12 months"
lab var combination_bp_meds_date 			"BP med in last 12 months"
lab var spironolactone_date 				"Spironolactone in last 12 months"
*/

*Create a comorbidities variable based upon Fizz's JCVI work that has 0, 1, 2 or more of the following comorbdities: 
/*
- (1) respiratory disease, (2) severe asthma, (3) chronic cardiac disease, (4) diabetes, (5) non-haematological cancer (diagnosed in last year), (6) haematological cancer (diagnosed within 5 years), (7) liver disease, (8) stroke, (9) dementia, (10) poor kidney function, (11) organ transplant, (12) asplenia, (13) other immunosuppression.
*/


*sort out variables here ready for generation of the 0, 1 or 2 variable
*(1) respiratory disease
safetab chronic_respiratory_disease
*think I need level "3" of this, as this is asthma that requires OCS
*(2) severe asthma
safetab asthmacat
generate asthma_severe=0
replace asthma_severe=1 if asthmacat==3
safetab asthma_severe
*(3) cardiac disease
safetab chronic_cardiac_disease
*(4) diabetes
safetab dm_type
safetab dm_type, nolabel
generate dm=0
replace dm=1 if dm_type>0
safetab dm
safetab dm dm_type
*(5) non-haem cancer (in previous year)
safetab cancer_nonhaem
generate cancer_nonhaemPrevYear=0
replace cancer_nonhaemPrevYear=1 if indexdate-cancer_nonhaem_date<365
tab cancer_nonhaemPrevYear
*(6) haem cancer (within previous 5 years)
safetab cancer_haem
generate cancer_haemPrev5Years=0
replace cancer_haemPrev5Years=1 if indexdate-cancer_haem_date<1825
tab cancer_haemPrev5Years
*(7) liver disease
safetab chronic_liver_disease
*(8 and 9) stroke or dementia
safetab stroke_dementia
*(10) poor kidney function
safetab egfr60
safetab egfr60, nolabel
*(11) organ transplant
safetab organ_transplant
generate organ_transplantBin=0
replace organ_transplantBin=1 if organ_transplant!=""
drop organ_transplant
rename organ_transplantBin organ_transplant
tab organ_transplant
*(12) asplenia
safetab asplenia
generate aspleniaBin=0
replace aspleniaBin=1 if asplenia!=""
drop asplenia
rename aspleniaBin asplenia
tab asplenia
*(13) other immunosuppression
safetab other_immuno


*create a total comborb var
order chronic_respiratory_disease asthma_severe chronic_cardiac_disease dm cancer_nonhaemPrevYear cancer_haemPrev5Years chronic_liver_disease stroke_dementia egfr60 organ_transplant asplenia other_immuno
egen totComorbsOfInterest=rowtotal(chronic_respiratory_disease - other_immuno)
*create the covariate var I need
generate coMorbCat=.
replace coMorbCat=0 if totComorbsOfInterest==0
replace coMorbCat=1 if totComorbsOfInterest==1
replace coMorbCat=2 if totComorbsOfInterest>1
la var coMorbCat "Categorical number of comorbidites of interest"
label define coMorbCatLabel 	0 "No comorbidities" 	///
						1 "1 comorbidity"		///
						2 "2 or more comorbidities"			
label values coMorbCat coMorbCatLabel
safetab coMorbCat

* Outcomes and follow-up

label var indexdate			"Date of study start (Feb 1 2020)"
label var censor_date		"Date of admin censoring"


*Outcome dates
foreach i of global outcomes {
	label var `i'Date					"Failure date:  `i'"
	d `i'Date
}


* Survival times
foreach i of global outcomes {
	lab var stime_`i' 					"Survivatime (date): `i'"
	d stime_`i'
}


* binary outcome indicators
foreach i of global outcomes {
	lab var `i' 					"outcome `i'"
	safetab `i'
}

/*
*label var was_ventilated_flag		"outcome: ICU Ventilation"
la var case "Probable case"
la var case_date "Probable case_date"
la var onsdeath_date "Date of death recorded in ONS"
la var cpnsdeath_date "Date of death recorded in CPNS"
*/

/* TIDY DATA==================================================================*/
*  Drop variables that are not needed (those not labelled)
ds, not(varlabel)
drop `r(varlist)'
	

/* APPLY INCLUSION/EXCLUIONS==================================================*/ 

safecount

*drop people over the age of 110 or under 18 (I can drop the under 18 year old's now as I have already used them in the composition variable)
noi di "DROP AGE >110:"
drop if age > 110 & age != .
noi di "DROP AGE <18:"
drop if age <18 & age != .

safecount
noi di "DROP IF DIED BEFORE INDEX"

*need to sort out deathdates
/*
local vars case_date onsdeath_date cpnsdeath_date

foreach var of local vars {
	confirm string variable `var'
	rename `var' `var'_dstr
	gen `var' = date(`var'_dstr, "YMD")
	drop `var'_dstr
	format `var' %td 
}
*/

drop if covidDeathCaseDate <= indexdate
drop if nonCOVIDDeathCaseDate <= indexdate


*drop cases that are dates prior to Feb012020
foreach i of global outcomes {
	drop if `i'Date<date("20200201", "YMD")	
}



*some final tweaks to variables not handled above
*sort out sex and region etc
safetab sex
generate sex2=.
replace sex2=1 if sex=="F"
replace sex2=2 if sex=="M"
drop sex
rename sex2 sex
safetab sex
label define sexLabel 1 "F" 2 "M"
label values sex sexLabel
label var sex "Sex"

*sort out region
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
drop region
rename region2 region
label var region "region of England"
label define regionLabel 0 "East" 1 "East Midlands"  2 "London" 3 "North East" 4 "North West" 5 "South East" 6 "South West" 7 "West Midlands" 8 "Yorkshire and The Humber"
label values region regionLabel

*create an IMD variable with two categories
safetab imd
generate imdBroad=.
replace imdBroad=1 if imd==1|imd==2|imd==3
replace imdBroad=2 if imd==4|imd==5
label define imdBroadLabel 1 "Less deprived" 2 "More deprived"
label values imdBroad imdBroadLabel
la var imdBroad "IMD in two categories (1=1-3, 2=4-5)"

*label the urban rural categories
replace rural_urban=. if rural_urban<1|rural_urban>8
label define rural_urbanLabel 1 "urban major conurbation" ///
							  2 "urban minor conurbation" ///
							  3 "urban city and town" ///
							  4 "urban city and town in a sparse setting" ///
							  5 "rural town and fringe" ///
							  6 "rural town and fringe in a sparse setting" ///
							  7 "rural village and dispersed" ///
							  8 "rural village and dispersed in a sparse setting"
label values rural_urban rural_urbanLabel
safetab rural_urban, miss

*create a 4 category rural urban variable based upon meeting with Roz 21st October
generate rural_urbanFive=.
la var rural_urbanFive "Rural Urban in five categories"
replace rural_urbanFive=1 if rural_urban==1
replace rural_urbanFive=2 if rural_urban==2
replace rural_urbanFive=3 if rural_urban==3|rural_urban==4
replace rural_urbanFive=4 if rural_urban==5|rural_urban==6
replace rural_urbanFive=5 if rural_urban==7|rural_urban==8
label define rural_urbanFiveLabel 1 "Urban major conurbation" 2 "Urban minor conurbation" 3 "Urban city and town" 4 "Rural town and fringe" 5 "Rural village and dispersed"
label values rural_urbanFive rural_urbanFiveLabel
safetab rural_urbanFive, miss

*generate a binary rural urban (with missing assigned to urban)
generate rural_urbanBroad=.
replace rural_urbanBroad=1 if rural_urban<=4|rural_urban==.
replace rural_urbanBroad=0 if rural_urban>4 & rural_urban!=.
label define rural_urbanBroadLabel 0 "Rural" 1 "Urban"
label values rural_urbanBroad rural_urbanBroadLabel
safetab rural_urbanBroad rural_urban, miss
label var rural_urbanBroad "Rural-Urban"

*create a hh_size variable with 5 groups
generate hh_size5cat=.
replace hh_size5cat=1 if hh_size==2|hh_size==3
replace hh_size5cat=2 if hh_size==4|hh_size==5
replace hh_size5cat=3 if hh_size==6|hh_size==7
replace hh_size5cat=4 if hh_size==8|hh_size==9|hh_size==10

label define hh_size5catLabel 1 "2-3" 2 "4-5" 3 "6-7" 4 "8-10"
label values hh_size5cat hh_size5catLabel
safetab hh_size5cat hh_size, miss

*create smoking variable with an unknwon category
safetab smoke, miss
replace smoke=4 if smoke==.u
label define smokeLabel 1 "Never" 2 "Former" 3 "Current" 4 "Unknown"
label values smoke smokeLabel
safetab smoke


safecount 
sort patient_id
save ./output/hhClassif_analysis_dataset.dta, replace








							  










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

