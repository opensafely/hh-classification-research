/*==============================================================================
DO FILE NAME:			03a_hh_an_descriptive_plots
PROJECT:				Household classfication
AUTHOR:					K Wing
DATE: 					14th June 2021
DESCRIPTION OF FILE:	Outputs sanity checking histograms of secondary cases by household size, also by date and ethnicity

DATASETS USED:			hh_analysis_datasetREDVARS
DATASETS CREATED: 		None
OTHER OUTPUT: 			Log file: $logdir\02_an_hist_descriptive_plots

cd ${outputData}
clear all
use hh_analysis_dataset_DRAFT.dta, clear
							
==============================================================================*/
*cd ${outputData}
*clear all
*use hh_analysis_dataset.dta, clear


* Open a log file
*cap log close
*log using "02_an_hist_descriptive_plots", replace t

/*These need updated - don't need to program that removes all bins <5, only need to redact when:
	1. If the total in the histogram is <5 then don't include in the hh size histogram
	2. Always include the total number of households with 0 cases somewhere in the plot
	3. The first 3 bars of the histogram have to add up to more than 5, otherwise need to redact
Based on meeting between Roz, Amir, Stephen and Kevin 7th October 2020
*/


*========================(1) HISTOGRAMS OF TOTAL HOUSEHOLD SIZE=====================================
sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles

local dataset `1'

* Open a log file
capture log close
log using ./logs/03a_hhClassif_an_hist_hhSizebyEthnicity_`dataset'.log, replace t

*create dataset needed for this descriptive analysis
use ./output/allHH_beforeDropping_largerThan10_`dataset'.dta, clear
*there are ridiculous numbers in the data (i.e. household sizes up to 2589) so restrict to those less than 20
drop if hh_size<1
drop if hh_size>20
save ./output/allHH_sizedBetween1And20_`dataset'.dta

*reduce to one record per household id
duplicates drop hh_id, force

**bughunting**
/*
use ./output/allHH_beforeDropping_largerThan10_MAIN.dta, clear
sum hh_size, detail
hist hh_size, discrete title(Overall, size (medium))
graph save ./output/overallHHSizeDist_MAIN.gph, replace

sum hh_size if eth5==1, detail 
hist hh_size if eth5==1, discrete title(White, size (medium))  
graph save ./output/whiteHHSizeDist_MAIN.gph, replace

gr combine ./output/overallHHSizeDist_MAIN.gph ./output/whiteHHSizeDist_MAIN.gph, title (HH size distribution)
gr export ./output/HHdistHists_MAIN.pdf, replace
*/
**endofbughunting**

*set colour schemes
graph query, schemes
set scheme economist


*overall distribution of hh_sizes
la var hh_size "Household size"
sum hh_size, detail
hist hh_size, freq xtitle("Household size", size(small)) xlabel(0(5)20, labsize(small) noticks) ytitle("n (houses)", size(small)) ylabel (#3, format(%5.0f) labsize(small))  discrete title(All ethnicities, size (medium))
graph save ./output/overallHHSizeDist_`dataset'.gph, replace

program histByEth
	if `1'==1  { 
		local ethnicity="White"
	}
	else if `1'==2  { 
		local ethnicity="South Asian"
	}
	else if `1'==3  { 
		local ethnicity="Black"
	}
	hist hh_size if eth5==`1', freq xtitle("Household size", size(small)) xlabel(0(5)20, labsize(small) noticks) ytitle("n (houses)", size(small)) ylabel (#3, format(%5.0f) labsize(small))  discrete title(`ethnicity' ethnicity, size (medium)) 
end

*plot of distrubtion of hh_sizes by ethnicity
*1 - white
sum hh_size if eth5==1, detail 
histByEth 1 
graph save ./output/whiteHHSizeDist_`dataset'.gph, replace
*2 - south asian
sum hh_size if eth5==2, detail 
histByEth 2 
graph save ./output/southAsianHHSizeDist_`dataset'.gph, replace
*3 - black
sum hh_size if eth5==3, detail 
capture noisily histByEth 3 
capture noisily graph save ./output/blackHHSizeDist_`dataset'.gph, replace

capture noisily gr combine ./output/overallHHSizeDist_`dataset'.gph ./output/whiteHHSizeDist_`dataset'.gph ./output/southAsianHHSizeDist_`dataset'.gph ./output/blackHHSizeDist_`dataset'.gph, title ("Household size distribution", size(medium))

gr export ./output/HHdistHists_`dataset'.pdf, replace

log close


/*
*========================(2) HISTOGRAMS OF HHCASES BY ETHNICITY=====================================
*PROGRAMS*
*this is the basic (vanilla) version of the hhCases histogram program
program hhCasesHist
	hist `1' if hh_size==`2', frequency addlabels discrete xlabel(1(1)`2') ylabel (, format(%5.0f)) title(Household size: `2', size (medium)) subtitle((households with no cases: `3'), size (medium)) saving(hh_size`2'', replace)
end

******************(b) Set 2 of histograms: distribution of total number of cases by household size, by ethnicity to start with******************
program hhCasesHistByEthnicity
	if `3'==1  { 
		local ethnicity="White"
	}
	else if `3'==2  { 
		local ethnicity="South_Asian"
	}
	else if `3'==3  { 
		local ethnicity="Black"
	}
	hist `1' if hh_size==`2' & eth5==`3', frequency addlabels discrete xlabel(1(1)`2') title (Household size: `2', size (medium)) subtitle(`ethnicity' "(households with no cases: `4')", size (medium)) saving(`2'_`ethnicity', replace)
end

/*
e.g. in a household size of 4, how many houses had 1 case, how many had 2, how many had 3, how many had 4
-so instead of case_date as the parameter, I want number of cases in the household
*/ 

************basic histograms (not stratified)**********
use ./output/hh_analysis_dataset.dta, clear
*NEW case definition
*use E:\high_privacy\workspaces\households\output\hh_analysis_dataset.dta

*reduce to one record per household id
duplicates drop hh_id, force

preserve
	keep if totCasesInHH==0
	save hhWithZeroCases.dta, replace
restore
 
*keep only houses with at least one case for this descriptive analysis
keep if totCasesInHH>0
count
*drop cases that are dates prior to Feb012020
*drop if case_date<date("20200201", "YMD")

tempfile forHistOutput
save `forHistOutput'


*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l'
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHist totCasesInHH `l' `hhWithNoCases'
	
	*combine into single pdfs - original case definition
	gr export totCasesinHHsize`l'.pdf, replace
	*combine into single pdfs - new case definition
	*gr export totCasesinHHsize`l'wSGSS.pdf, replace
}






**************histograms by ETHNICITY*******************
*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
use hh_analysis_dataset.dta, clear
 
*first of all, create a number of cases in the household variable
bysort hh_id:egen totCasesInHH=total(case) 
*then reduce to one record per household id
duplicates drop hh_id, force

preserve
	keep if totCasesInHH==0
	save hhWithZeroCases.dta, replace
restore
 
*keep only houses with at least one case for this descriptive analysis
keep if totCasesInHH>0
count
*drop cases that are dates prior to Feb012020
*drop if case_date<date("20200201", "YMD")

tempfile forHistOutput
save `forHistOutput'


*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	

	
	*histogram showing distribution of total number of cases in household by ethnicity
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==1
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 1 `hhWithNoCases' 	/*white*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==2
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 2 `hhWithNoCases'  /*south asian*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==3
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 3 `hhWithNoCases'	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph
	gr export totCasesinHHsize`l'ByEthnicity.pdf, replace
}





**************repeat above by RURAL URBAN broad categories*******************
use hh_analysis_dataset.dta, clear
numlabel, add
 
*first of all, create a number of cases in the household variable
bysort hh_id:egen totCasesInHH=total(case) 
*then reduce to one record per household id
duplicates drop hh_id, force

*keep only households in conurbations
tab rural_urbanFive
keep if rural_urbanFive==1|rural_urbanFive==2
tab rural_urbanFive

preserve
	keep if totCasesInHH==0
	save hhWithZeroCases.dta, replace
restore
 
*keep only houses with at least one case for this descriptive analysis
keep if totCasesInHH>0
count
*drop cases that are dates prior to Feb012020
*drop if case_date<date("20200201", "YMD")

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==1
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 1 `hhWithNoCases' 	/*white*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==2
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 2 `hhWithNoCases'  /*south asian*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==3
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 3 `hhWithNoCases'	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (Urban (major or minor conurbation))
	gr export totCasesinHHsize`l'ByEthnicity_Conurbations.pdf, replace
}





**************repeat above by RURAL URBAN broad categories*******************
use hh_analysis_dataset.dta, clear
numlabel, add
 
*first of all, create a number of cases in the household variable
bysort hh_id:egen totCasesInHH=total(case) 
*then reduce to one record per household id
duplicates drop hh_id, force

*keep only households outside of conurbations
tab rural_urbanFive
keep if rural_urbanFive==3|rural_urbanFive==4|rural_urbanFive==5
tab rural_urbanFive

preserve
	keep if totCasesInHH==0
	save hhWithZeroCases.dta, replace
restore
 
*keep only houses with at least one case for this descriptive analysis
keep if totCasesInHH>0
count
*drop cases that are dates prior to Feb012020
*drop if case_date<date("20200201", "YMD")

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==1
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 1 `hhWithNoCases' 	/*white*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==2
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 2 `hhWithNoCases'  /*south asian*/
	use hhWithZeroCases.dta, clear
	keep if hh_size==`l' & eth5==3
	count
	local hhWithNoCases=r(N)
	use `forHistOutput', clear
	hhCasesHistByEthnicity totCasesInHH `l' 3 `hhWithNoCases'	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (More rural)
	gr export totCasesinHHsize`l'ByEthnicity_More_Rural.pdf, replace
}






**************repeat above by rural urban broad categories*******************
*=========RURAL LOCATION===============
*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
use hh_analysis_dataset.dta, clear
numlabel, add

*keep only cases for this descriptive analysis
keep if case==1
*drop cases that are dates prior to Feb012020
drop if case_date<date("20200201", "YMD")

*keep only the more well off househholds
tab rural_urbanBroad
keep if rural_urbanBroad==0

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 1	/*white*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 2   /*south asian*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 3	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (Rural)
	gr export totCasesinHHsize`l'ByEthnicity_Rural.pdf, replace
}




*=========URBAN LOCATION===============
*now all ethnicities - I want single pdfs each with three graphs on: white, black, south asian for each household size
use hh_analysis_dataset.dta, clear
numlabel, add

*keep only cases for this descriptive analysis
keep if case==1
*drop cases that are dates prior to Feb012020
drop if case_date<date("20200201", "YMD")

*keep only the more well off househholds
tab rural_urbanBroad
keep if rural_urbanBroad==1

tempfile forHistOutput
save `forHistOutput'

*create a single combined pdf of all the (<5 redacted) histograms (with histograms showing number of houses with specific numbers of cases by household size)
*macro for number of houshold sizes
levelsof hh_size, local(levels)
foreach l of local levels {
	
	*histogram showing distribution of total number of cases in household by ethnicity
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 1	/*white*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 2   /*south asian*/
	use `forHistOutput', clear
	redactedHHCasesHistByEthnicity totCasesInHH `l' 3	/*black*/
	
	*combine into single pdfs
	gr combine `l'_white.gph `l'_south_asian.gph `l'_black.gph, title (Urban)
	gr export totCasesinHHsize`l'ByEthnicity_Urban.pdf, replace
}














