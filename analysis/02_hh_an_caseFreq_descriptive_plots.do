/*==============================================================================
DO FILE NAME:			02_an_caseFreq_descriptive_plots
PROJECT:				Households and COVID
AUTHOR:					K Wing
DATE: 					25th November 2020
DESCRIPTION OF FILE:	Performs plots and descriptive stats for the following (also see https://docs.google.com/document/d/15m-ajw2glvPpqUAlUgi90V1LmNoTHRINTqiEqleMRXM/edit)

(1) HH size distribution in the data: in all hhs, in hh with an infection (2 panel figure of frequency of households of size x) - DONE
(2) Frequency of case definition types: freq of each type of case in the sample, 2 panel figure of time series of total endpoints, time series stratified by endpoint type, plot of age and different types of case definition
(3) Household size case frequency distributions: blue histograms showing hh secondary attack rate, possibly stratified by different phases
(4) Time between cases in a household: histogram showing time from first to last definition of case in a household



DATASETS USED:			hh_analysis_datasetREDVARS
DATASETS CREATED: 		None
OTHER OUTPUT: 			Log file: $logdir\02_an_hist_descriptive_plots

cd ${outputData}
clear all
use hh_analysis_dataset.dta, clear
							
==============================================================================*/

/* === Housekeeping === */

sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles
use  ./output/hh_analysis_dataset.dta, clear

cap log close
log using "./released_outputs/02_hh_an_caseFreq_descriptive_plots.log", replace t


/*Also want to do this by time periods e.g.
    Feb - end of May
    June - end of Aug
    Sep - current date
and by age over time!


1. average time from first hh infection to last hh infection in all houses - look for those longer than 4 weeks
2. could do univariable x date, y is gap between first and last
3. Thomas still wants regression to run
*/





**********************(1) HH size distribution in the data: in all hhs, in hh with an infection (2 panel figure of frequency of households of size x)***************
*helper variables
count
local totalHHCount=r(N)
count if totCasesInHH>0
local infectHHCount=r(N)

*****(a)Side by side version*******
*distribution of hh size overall
*hist hh_size, frequency addlabels discrete xlabel(1(1)`2') title (Household size: `2', size (medium)) subtitle(`ethnicity' "(households with no cases: `4')", size (medium)) saving(`2'_`ethnicity', replace)
*see: https://www.stata.com/manuals13/g-4colorstyle.pdf
hist hh_size, frequency discrete barw(0.99) xlabel(2(1)9) ylabel (, format(%5.0f)) bcolor(eltgreen) title ("{bf:All households} (n=`totalHHCount')", size(medium))  saving(hh_Hist_Overall, replace)


*distribution of hh size in those with an infection
preserve
	keep if totCasesInHH>0
	*hist hh_size, frequency discrete barw(0.99) xlabel(2(1)9) yscale(off) bcolor(erose) title ("{bf:Households with COVID-19}", size(medium)) saving(hh_Hist_withAtLeastOneInfection, replace)
	hist hh_size, frequency discrete barw(0.99) xlabel(2(1)9) ylabel (, format(%5.0f)) bcolor(erose) title ("{bf:Households with COVID-19} (n=`infectHHCount')", size(medium)) saving(hh_Hist_withAtLeastOneInfection, replace)
restore

gr combine hh_Hist_Overall.gph hh_Hist_withAtLeastOneInfection.gph, title("Distribution of household sizes in OpenSAFELY", size(medium))
graph export ./released_outputs/an_caseFreq_descr_overall_HH_Histogram.svg, as(svg) replace
erase hh_Hist_Overall.gph
erase hh_Hist_withAtLeastOneInfection.gph


*****(b)Overlay version*******

twoway (histogram hh_size,  frequency discrete barw(0.99) xlabel(2(1)9) bcolor(eltgreen)) (histogram hh_size if totCasesInHH>0, frequency discrete barw(0.99) xlabel(2(1)9) bcolor(erose)), legend(size (small) order(1 "All households (n=`totalHHCount')" 2 "Households with COVID-19 (n=`infectHHCount')") ) title(Distribution of household sizes in OpenSAFELY, size(medium))

graph export ./released_outputs/an_caseFreq_descr_overall_HH_HistogramOverlay.svg, as(svg) replace





**************2 % OF PEOPLE WHO HAVE (1) A PRIMARY CARE CLIN DIAGNOSIS FOLLOWED BY (2) A MORE DEFINITE EVENT (e.g. TEST RESULT, HOSP, DEATH)***********
*keep only those people who have ANY of the probable case definitions for this dataset (primary care pos test, prim care diag, prim care seq, covid hosp, covid death)
use  ./output/hh_analysis_dataset.dta, clear


*what proportion of the people who were clinCases, went onto become any of testCase, hospCase or deathCase?
*proportion that were any of these
safetab case

*what proportion of people were clin case and also one of the more definite cases?
display "**************Type of cases in data (over entire time period)**************"
*all types of case
display "All cases:"
safetab case

generate sgssCaseDefine=0
replace sgssCaseDefine=1 if sgssCase==1 & sgssCaseDate==case_date
display "Cases defined by sgss positive test"
safetab sgssCaseDefine

generate testCaseDefine=0
replace testCaseDefine=1 if testCase==1 & testCaseDate==case_date
display "Cases defined by primary care positive test"
safetab testCaseDefine

generate hospCaseDefine=0
replace hospCaseDefine=1 if hospCase==1 & hospCaseDate==case_date
display "Cases defined by hosp with COVID"
safetab hospCaseDefine

generate deathCaseDefine=0
replace deathCaseDefine=1 if deathCase==1 & deathCaseDate==case_date
display "Cases defined by COVID on death certificate"
safetab deathCaseDefine

generate clinCaseDefine=0
replace clinCaseDefine=1 if clinCase==1 & clinCaseDate==case_date
display "Cases defined by clin diag in primary care"
safetab clinCaseDefine

*proportion of clinCases that also had a more definite outcome
display "Proportion of clin diag in primary care cases who also had a more definite case event"
safetab clinCase moreCertainCase if clinCase==1, row



cap prog drop generaterow
program define generaterow
syntax, variable(varname) condition(string) 
	
	*put the varname and condition to left so that alignment can be checked vs shell
	
	file write tablecontent ("`variable'") _tab 
	*safecount if `variable' `condition' & hiv==`hivlevel'
	safecount
	local total=r(N)
	safecount if `variable'==0
	local totalZero=r(N)
	local totalZeropct=`totalZero'/`total'*100
	safecount if `variable'==1
	local totalOne=r(N)
	local totalOnepct=`totalOne'/`total'*100
	file write tablecontent (`totalZero')  (" (") %3.1f (`totalZeropct') (")") _tab (`totalOne')  (" (") %3.1f (`totalOnepct') (")") 
	file write tablecontent _n
	
end

*******************************************************************************
*Generic code to output one section (varible) within table (calls above)
cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) start(real) end(real) [missing] 

	generaterow, variable(`variable') condition("==`varlevel'") 

end

*******************************************************************************


*Set up output file
cap file close tablecontent
file open tablecontent using ./released_outputs/an_caseDescrTable.txt, write text replace
file write tablecontent _tab ("No") _tab ("Yes") _tab _n
file write tablecontent ("Total recorded") _n
tabulatevariable, variable(clinCase) start(0) end(1)
tabulatevariable, variable(testCase) start(0) end(1)
tabulatevariable, variable(sgssCase) start(0) end(1)
tabulatevariable, variable(hospCase) start(0) end(1)
tabulatevariable, variable(deathCase) start(0) end(1)
file write tablecontent ("Recorded as first case event") _n
tabulatevariable, variable(clinCaseDefine) start(0) end(1)
tabulatevariable, variable(testCaseDefine) start(0) end(1)
tabulatevariable, variable(sgssCaseDefine) start(0) end(1)
tabulatevariable, variable(hospCaseDefine) start(0) end(1)
tabulatevariable, variable(deathCaseDefine) start(0) end(1)
file write tablecontent ("% of people with clin case diagnosis who also had a more definite case event") _n
preserve
	keep if clinCase==1
	generate displayVar=0
	replace displayVar=1 if moreCertainCase==1
	tabulatevariable, variable(displayVar) start(0) end(1)
restore



file write tablecontent _n 


file close tablecontent







log close


/*

**************code from Dan to adapt************
/*

* Keep test variables
keep patient_id age sgss_covid_test_ever* covid_anytest* covid_negtest covid_tpp_probable

set linesize 200

list in 1/40, clean header(10) ab(30) noobs

* How many covid_anytests?
summ covid_anytest_count, d


/* === Age groups === */ 

* Create categorised age 
recode age 0/9.9999 = 1 ///
		   10/17.9999 = 2 ///
		   18/29.9999 = 3 /// 
		   30/39.9999 = 4 /// 
           40/49.9999 = 5 ///
		   50/59.9999 = 6 ///
	       60/69.9999 = 7 ///
		   70/79.9999 = 8 ///
		   80/max = 9, gen(agegroup) 

label define agegroup 	1 "<10" ///
						2 "10-<18" ///
						3 "18-<30" ///
						4 "30-<40" ///
						5 "40-<50" ///
						6 "50-<60" ///
						7 "60-<70" ///
						8 "70-<80" ///
						9 "80+"
						
label values agegroup agegroup

tab agegroup


/* === Dates === */

ds, has(type string)

* Recode to dates from the strings 
foreach var of varlist `r(varlist)' {
						
	confirm string variable `var'
	rename `var' `var'_dstr
	gen `var' = date(`var'_dstr, "YMD")
	format `var' %td
	
	*Week of year
	datacheck inlist(year(`var'),2020,.), nolist
	gen `var'_week=week(`var') if year(`var')==2020
		
}


/* === Frequency of covid tests === */

* ##### COVID TPP positive tests #####
table covid_tpp_probable_week agegroup, contents(count covid_tpp_probable) row col

preserve

	gen count=1 if covid_tpp_probable !=.
	collapse (count) count, by(agegroup covid_tpp_probable_week)
	export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\tpp_count.xlsx", first(var) replace

restore

* ##### COVID antigen negative tests #####
table covid_negtest_week agegroup, contents(count covid_negtest) row col

preserve

	gen count=1 if covid_negtest !=.
	collapse (count) count, by(agegroup covid_negtest_week)
	export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\negtest_count.xlsx", first(var) replace

restore

* ##### COVID first anytest #####
table covid_anytest_first_week agegroup, contents(count covid_anytest_first) row col

preserve

	gen count=1 if covid_anytest_first !=.
	collapse (count) count, by(agegroup covid_anytest_first_week)
	export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\anytest_first_count.xlsx", first(var) replace

restore

* ##### COVID last anytest #####
table covid_anytest_last_week agegroup, contents(count covid_anytest_last) row col

preserve

	gen count=1 if covid_anytest_last !=.
	collapse (count) count, by(agegroup covid_anytest_last_week)
	export excel using "C:\Users\EIDEDGRI\Filr\My Files\OpenSafely\Non-specific immunity\Outputs\anytest_last_count.xlsx", first(var) replace

restore


log close
