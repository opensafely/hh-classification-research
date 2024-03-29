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



* Open a log file
cap log close
log using ./logs/10_hh_imd_descriptives_for_Hamish_W1.log, replace t



* Open Stata dataset
use ./output/hhClassif_analysis_dataset_ageband_3MAIN.dta, clear //age 67+ only


*% of hh category by region
tab region hhRiskCatExp_5cats, row

*%redoing household size by ethnic group to separate households of 2 and 3
tab eth5 hh_size, row


log close

*Household composition by ethnic group and IMD quintile (Q1: most affluent, Q5: most deprived)
*tab eth5 hhRiskCat67PLUS_5cats if imd==1, row

*tab eth5 hhRiskCat67PLUS_5cats if imd==5, row

/*

keep patient_id hhRiskCat hhRiskCatExp_4cats hh_size* hhRiskCatBROAD ethnicity ethnicity_16 hh_size eth5 imd eth16


tab hhRiskCat67PLUS_5cats imd if eth5==1, col 
tab hhRiskCat67PLUS_5cats imd if eth5==2, col
tab hhRiskCat67PLUS_5cats imd if eth5==3, col
tab hhRiskCat67PLUS_5cats imd if eth5==4, col
tab hhRiskCat67PLUS_5cats imd if eth5==5, col




*generate new household category which includes living alone
gen hh_rohini=hhRiskCatBROAD
replace hh_rohini=0 if hh_size==1 & hhRiskCatBROAD==1 //67+ living alone
label define hh_rohini 0"Living alone (67+ only)" 1"1 gen (67+ only)" 2"2 gens" 3"3+ gens"
label values hh_rohini hh_rohini
tab hh_rohini

label var hh_rohini "Number of generations in each household"

*add household size =1 to household size variable
tab hh_size5cat
replace hh_size5cat=0 if hh_size==1
label define  hh_size5catLabel  0 "1", modify
tab hh_size5cat

label var hh_size5cat "Number of people in each household"

*Set up output file
cap file close tablecontent
file open tablecontent using ./output/table_ethnicity_descriptivesMAIN.txt, write text replace

file write tablecontent ("Table x: Household size by ethnic group") _n

/*
* ADD ETHNICITY LABEL
label define eth5 			1 "White"  					///
							2 "South Asian"				///						
							3 "Black"  					///
							4 "Mixed"					///
							5 "Other"					///
							6 "Unknown"
					

label values eth5 eth5
safetab eth5, m
*/

local lab1: label eth5 1
local lab2: label eth5 2
local lab3: label eth5 3
local lab4: label eth5 4
local lab5: label eth5 5

di "`lab1'" "`lab2'" "`lab3'" "`lab4'" "`lab5'" 


file write tablecontent _tab ("Total")	_tab _tab ///
							 ("`lab1'")  _tab  _tab ///
							 ("`lab2'")  _tab  _tab ///
							 ("`lab3'")  _tab  _tab ///
							 ("`lab4'")  _tab   _tab ///
							 ("`lab5'")  _tab   _n _n
							 



*HOUSEHOLD GENERATIONS BROAD
tabulatevariable_eth, variable(hh_rohini) min(0) max(3) 
file write tablecontent _n _n

*HOUSEHOLD SIZE
tabulatevariable_eth, variable(hh_size5cat) min(0) max(4) 
file write tablecontent _n _n 

*IMD
tabulatevariable_eth, variable(imd) min(1) max(5) 
file write tablecontent _n _n

*HOUSEHOLD GENERATIONS DETAILED
tabulatevariable_eth, variable(hhRiskCat) min(1) max(14) 
file write tablecontent _n _n _n


file write tablecontent _n _n
file write tablecontent ("Table x: Household size by ethnic subgroup") _n



/*
* HOUSEHOLD SIZE BY SOUTH ASIAN SUBGROUPS
local lab1: label eth16 4
local lab2: label eth16 5
local lab3: label eth16 6



file write tablecontent _tab ("Total")	_tab 	("Total") _tab ///
							 ("`lab1'")  _tab  ("`lab1'") _tab ///
							 ("`lab2'")  _tab  ("`lab2'") _tab ///
							 ("`lab3'")  _tab  ("`lab3'") _n

*HOUSEHOLD GENERATIONS BROAD
tabulatevariable_eth16, variable(hh_rohini) min(0) max(3) 
file write tablecontent _n _n 

*HOUSEHOLD SIZE
tabulatevariable_eth16, variable(hh_size5cat) min(0) max(4) 
file write tablecontent _n _n
*IMD
tabulatevariable_eth16, variable(imd) min(1) max(5) 
file write tablecontent _n _n 

*HOUSEHOLD GENERATIONS DETAILED
tabulatevariable_eth16, variable(hhRiskCat) min(1) max(14) 
file write tablecontent _n  _n _n
*/

******************************ETH5 IMD
file write tablecontent ("Table x: Household size by ethnic group and IMD") _n
*gen eth-imd variable for all eth5 vars
gen eth_imd=1 if eth5==1 & imd==1
replace eth_imd=2 if eth5==1 & imd==5
replace eth_imd=3 if eth5==2 & imd==1
replace eth_imd=4 if eth5==2 & imd==5
replace eth_imd=5 if eth5==3 & imd==1
replace eth_imd=6 if eth5==3 & imd==5
replace eth_imd=7 if eth5==4 & imd==1
replace eth_imd=8 if eth5==4 & imd==5
replace eth_imd=9 if eth5==5 & imd==1
replace eth_imd=10 if eth5==5 & imd==5

label define eth_imd 1"White Q1" 2"White Q5" 3"SA Q1" 4"SA Q5" 5"Black Q1" 6"Black Q5" 7"Mixed Q1" 8"Mixed Q5" 9"Other Q1" 10"Other Q5" 

label values eth_imd eth_imd
tab eth_imd

local lab1: label eth_imd 1
local lab2: label eth_imd 2
local lab3: label eth_imd 3
local lab4: label eth_imd 4
local lab5: label eth_imd 5
local lab6: label eth_imd 6
local lab7: label eth_imd 7
local lab8: label eth_imd 8
local lab9: label eth_imd 9
local lab10: label eth_imd 10

file write tablecontent _tab ("Total")	_tab  _tab ///
							 ("`lab1'")  _tab _tab ///
							 ("`lab2'")  _tab _tab ///
							 ("`lab3'")  _tab _tab ///
							 ("`lab4'")  _tab _tab ///
							 ("`lab5'")  _tab _tab ///
							 ("`lab6'")  _tab _tab ///
							 ("`lab7'")  _tab _tab ///
							 ("`lab8'")  _tab _tab ///
							 ("`lab9'")  _tab _tab ///
							 ("`lab10'")  _tab _n _n

*HOUSEHOLD GENERATIONS BROAD
tabulatevariable_ethimd, variable(hh_rohini) min(0) max(3) 
file write tablecontent _n _n 

*HOUSEHOLD SIZE
tabulatevariable_ethimd, variable(hh_size5cat) min(0) max(4) 
file write tablecontent _n _n

*HOUSEHOLD GENERATIONS DETAILED
tabulatevariable_ethimd, variable(hhRiskCat) min(1) max(14) 
file write tablecontent _n _n

/*
******************************ETH16 IMD
file write tablecontent ("Table x: Household size by ethnic subgroup and IMD") _n
*gen eth-imd variable for white and SA
gen eth16_imd=1 if eth16==4 & imd==1
replace eth16_imd=2 if eth16==4 & imd==5
replace eth16_imd=3 if eth16==5 & imd==1
replace eth16_imd=4 if eth16==5 & imd==5
replace eth16_imd=5 if eth16==6 & imd==1
replace eth16_imd=6 if eth16==6 & imd==5

label define eth16_imd 1"Indian Q1" 2"Indian Q5" 3"Pakistani Q1" 4"Pakistani Q5" 5 "Bangladeshi Q1" 6"Bangladeshi Q5"

label values eth16_imd eth16_imd
tab eth16_imd

local lab1: label eth16_imd 1
local lab2: label eth16_imd 2
local lab3: label eth16_imd 3
local lab4: label eth16_imd 4
local lab5: label eth16_imd 5
local lab6: label eth16_imd 6

file write tablecontent _tab ("Total")	_tab  ("Total") _tab ///
							 ("`lab1'")  _tab  ("`lab1'") _tab ///
							 ("`lab2'")  _tab  ("`lab2'") _tab ///
							 ("`lab3'")  _tab  ("`lab3'") _tab ///
							 ("`lab4'")  _tab  ("`lab4'") _tab ///
							 ("`lab5'")  _tab  ("`lab5'") _tab ///
							 ("`lab6'")  _tab  ("`lab6'") _n ///



*HOUSEHOLD GENERATIONS BROAD
tabulatevariable_eth16imd, variable(hh_rohini) min(0) max(3) 
file write tablecontent _n _n 

*HOUSEHOLD SIZE
tabulatevariable_eth16imd, variable(hh_size5cat) min(0) max(4) 
file write tablecontent _n _n

*HOUSEHOLD GENERATIONS DETAILED
tabulatevariable_eth16imd, variable(hhRiskCat) min(1) max(14) 
file write tablecontent _n _n

file close tablecontent
*/


* Close log file 
log close

*check imd
insheet using ./output/table_ethnicity_descriptivesMAIN.txt, clear



/**BAR CHARTS

use ./output/hhClassif_analysis_datasetMAIN.dta, clear
keep eth5 imd hhRiskCatBROAD hh_size5cat hhRiskCat
tab  hhRiskCatBROAD, generate(broad)
tab  hh_size5cat, generate(size)
tab  hhRiskCat, generate(hhcat)

*gen eth-imd variable for white and SA
gen eth_imd=1 if eth5==1 & imd==1
replace eth_imd=2 if eth5==1 & imd==2
replace eth_imd=3 if eth5==1 & imd==3
replace eth_imd=4 if eth5==1 & imd==4
replace eth_imd=5 if eth5==1 & imd==5
replace eth_imd=6 if eth5==2 & imd==1
replace eth_imd=7 if eth5==2 & imd==2
replace eth_imd=8 if eth5==2 & imd==3
replace eth_imd=9 if eth5==2 & imd==4
replace eth_imd=10 if eth5==2 & imd==5

label define eth_imd 1"White Q1" 2"White Q2" 3"White Q3" 4"White Q4" 5"White Q5" ///
6"SA Q1" 7"SA Q2" 8"SA Q3" 9"SA Q4" 10"SA Q5" 

label values eth_imd eth_imd
tab eth_imd


*BY ETHNICITY 
graph bar broad1 broad2 broad3, over(eth5) saving(./output/rohini_hhbroad_ethMAIN.gph, replace)

cap graph bar size1 size2 size3 size4 size5, over(eth5) saving(./output/rohini_hhsize_ethMAIN.gph, replace)

graph bar hhcat1 hhcat2 hhcat3 hhcat4 hhcat5 hhcat6 hhcat7 hhcat8 hhcat9 hhcat10 hhcat11 hhcat12 hhcat13 hhcat14, over(eth5) saving(./output/rohini_hhcat_ethMAIN.gph, replace) legend(off)

*BY ETHNICITY AND IMD
						  
graph bar broad1 broad2 broad3, over(eth_imd) saving(./output/rohini_hhbroad_ethimdMAIN.gph, replace)

cap graph bar size1 size2 size3 size4 size5, over(eth_imd) saving(./output/rohini_hhsize_ethimdMAIN.gph, replace)

graph bar hhcat1 hhcat2 hhcat3 hhcat4 hhcat5 hhcat6 hhcat7 hhcat8 hhcat9 hhcat10 hhcat11 hhcat12 hhcat13 hhcat14, over(eth_imd) saving(./output/rohini_hhcat_ethimdMAIN.gph, replace) legend(off)









