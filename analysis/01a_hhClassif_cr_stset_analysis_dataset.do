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
pwd

local dataset `1' 



* Open a log file
cap log close
log using ./logs/01a_hhClassif_cr_stset_analysis_dataset_`dataset'.log, replace t


*(1)**nonCovidDeath**
*overall
use ./output/hhClassif_analysis_dataset_ageband_3`dataset', clear
keep stime_nonCOVIDDeathCase nonCOVIDDeathCase nonCOVIDDeathCaseDate patient_id eth5 eth16 ethnicity_16 enter_date imd smoke obese4cat rural_urbanFive ageCatfor67Plus male coMorbCat utla_group hh_id hh_total_cat hh_total_4cats hh_total_5cats hhRiskCatExp_5cats hhRiskCatExp_9cats HHRiskCatCOMPandSIZEBROAD hh_size
stset stime_nonCOVIDDeathCase, fail(nonCOVIDDeathCase) id(patient_id) enter(enter_date) origin(enter_date)
*have a look at records that ended on or before enter()
list patient_id stime_nonCOVIDDeathCase nonCOVIDDeathCase nonCOVIDDeathCaseDate eth5 imd hh_total_5cats hhRiskCatExp_9cats if nonCOVIDDeathCaseDate<=enter_date
save ./output/hhClassif_analysis_dataset_STSET_nonCovidDeath_ageband_3`dataset'.dta, replace
	
*(2)**covidHospCase**
* overall
use ./output/hhClassif_analysis_dataset_ageband_3`dataset', clear
keep stime_covidHospCase covidHospCase covidHospCaseDate patient_id eth5 eth16 ethnicity_16 enter_date imd smoke obese4cat rural_urbanFive ageCatfor67Plus male coMorbCat utla_group hh_id hh_total_cat hh_total_4cats hh_total_5cats hhRiskCatExp_5cats hhRiskCatExp_9cats HHRiskCatCOMPandSIZEBROAD hh_size
stset stime_covidHospCase, fail(covidHospCase) id(patient_id) enter(enter_date) origin(enter_date)
*have a look at records that ended on or before enter()
list patient_id stime_covidHospCase covidHospCase covidHospCaseDate eth5 imd hh_total_5cats hhRiskCatExp_9cats if covidHospCaseDate<=enter_date
save ./output/hhClassif_analysis_dataset_STSET_covidHosp_ageband_3`dataset'.dta, replace


*(3)**covidDeath**
*overall
use ./output/hhClassif_analysis_dataset_ageband_3`dataset', clear
keep stime_covidDeathCase covidDeathCase covidDeathCaseDate patient_id eth5 eth16 ethnicity_16 enter_date imd smoke obese4cat rural_urbanFive ageCatfor67Plus male coMorbCat utla_group hh_id hh_total_cat hh_total_4cats hh_total_5cats hhRiskCatExp_5cats hhRiskCatExp_9cats HHRiskCatCOMPandSIZEBROAD hh_size
stset stime_covidDeathCase, fail(covidDeathCase) id(patient_id) enter(enter_date) origin(enter_date)
*have a look at records that ended on or before enter()
list patient_id stime_covidDeathCase covidDeathCase covidDeathCaseDate eth5 imd hh_total_5cats hhRiskCatExp_9cats if covidDeathCaseDate<=enter_date
save ./output/hhClassif_analysis_dataset_STSET_covidDeath_ageband_3`dataset'.dta, replace


*(4)**covidHospOrDeathCase**
*overall
use ./output/hhClassif_analysis_dataset_ageband_3`dataset', clear
keep stime_covidHospOrDeathCase covidHospOrDeathCase covidHospOrDeathCaseDate patient_id eth5 eth16 ethnicity_16 enter_date imd smoke obese4cat rural_urbanFive ageCatfor67Plus male coMorbCat utla_group hh_id hh_total_cat hh_total_4cats hh_total_5cats hhRiskCatExp_5cats hhRiskCatExp_9cats  HHRiskCatCOMPandSIZEBROAD hh_size
stset stime_covidHospOrDeathCase, fail(covidHospOrDeathCase) id(patient_id) enter(enter_date) origin(enter_date)
*have a look at records that ended on or before enter()
list patient_id stime_covidHospOrDeathCase covidHospOrDeathCase covidHospOrDeathCaseDate eth5 imd hh_total_5cats hhRiskCatExp_9cats if covidHospOrDeathCaseDate<=enter_date
save ./output/hhClassif_analysis_dataset_STSET_covidHospOrDeath_ageband_3`dataset'.dta, replace


log close

