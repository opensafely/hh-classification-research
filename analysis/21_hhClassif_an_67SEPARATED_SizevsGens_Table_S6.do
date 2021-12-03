/*==============================================================================
DO FILE NAME:			00_hhClassif_cr_analysis_dataset
PROJECT:				describe household composition by ethnicity and IMD
DATE: 					12th August 2020 
AUTHOR:					Rohini Mathur/Kevin Wing 
DESCRIPTION OF FILE:	program 10, descriptive variables
DATASETS USED:			main analysis dataset for each wave
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir


sysdir set PLUS "/Users/kw/Documents/GitHub/households-research/analysis/adofiles" 
sysdir set PERSONAL "/Users/kw/Documents/GitHub/households-research/analysis/adofiles" 
							
==============================================================================*/
sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles
pwd


local dataset `1' 

* Open a log file
cap log close
log using ./logs/21_hhClassif_an_67SEPARATED_SizevsGens_Table_S6_`dataset'.log, replace t

*get data
use ./output/hhClassif_analysis_dataset_STSET_covidHospOrDeath_ageband_3`dataset'.dta, clear

*create temporary hh size variable that has household sizes over 6 included in the "6" category
generate hh_size6Plus=hh_size
replace hh_size6Plus=6 if hh_size>=6

*overall
display "*************All ethnicities************ "
tab hhRiskCat67PLUS_5cats hh_size6Plus , row

*by ethnicity
sum eth5
local maxEth5=r(max) 
forvalues e=1/`maxEth5' {
		display "*************Ethnicity: `e'************ "
		tab hhRiskCat67PLUS_5cats hh_size6Plus  if eth5==`e', row
	}


log close