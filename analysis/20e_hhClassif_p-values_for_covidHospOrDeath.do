*************************************************************************
*Do file: 08_hhClassif_an_mv_analysis_perEth5Group_HR_table.do
*
*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell table containing minimally and fully-adjusted HRs for risk factors
* of interest, across 2 outcomes 
*
*Requires: final analysis dataset (analysis_dataset.dta)
*
*Coding: K Wing, base on file from HFORBES, based on file from Krishnan Bhaskaran
*
*Date drafted: 17th June 2021
*************************************************************************


local dataset `1' 

/*for reference
capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.imd##i.eth5 i.ageCatfor67Plus##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive i.smoke  i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
*/

*global demogadjlistWInts i.imd##i.eth5 i.smoke##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive##i.eth5 i.ageCatfor67Plus##i.eth5 i.male##i.eth5 i.coMorbCat##i.eth5
global demogadjlistWInts i.imd##i.eth5 i.ageCatfor67Plus##i.eth5 i.obese4cat##i.eth5 i.rural_urbanFive i.smoke i.male i.coMorbCat
	

prog drop _all


foreach outcome in covidHospOrDeath {
   
	
	* Open a log file
	capture log close
	log using "./logs/20e_hhClassif_p-values_for_`outcome'_`dataset'", text replace
	
	*open dataset
	use ./output/hhClassif_analysis_dataset_STSET_`outcome'_ageband_3`dataset'.dta, clear
	
	**REGRESSIONS**
	*only need to do the regressions once, so putting that code here and editing the outputHRsforvar program accordingly

	
	if "`dataset'"=="MAIN" {
		*crude (only utla matched)
		*MV adjusted (without household size)
		capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 i.ageCatfor67Plus i.imd i.obese4cat i.rural_urbanFive i.smoke i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
		capture noisily estimates store mvAdj
		*(2)MV adjusted with main exposure linear
		capture noisily stcox c.hhRiskCat67PLUS_5cats##i.eth5 i.imd i.obese4cat i.rural_urbanFive i.smoke i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
		capture noisily estimates store mvAdjHHLin
		*(3)MV adusted with main exposure linear, having dropped the 67+ living alone
		*first, create a main exposure variable that doesn't have 67+ living alone (going to do this in the main analysis file)
		generate hhRiskCat67PLUS_5catsNoSingles=hhRiskCat67PLUS_5cats
		replace hhRiskCat67PLUS_5catsNoSingles=. if hhRiskCat67PLUS_5catsNoSingles==2
		recode hhRiskCat67PLUS_5catsNoSingles 1=1 3=2 4=3 5=4
		label define hhRiskCat67PLUS_5catsNoSingles  1 "Multiple 67+ year olds" 2 "67+ & 1 other gen" 3 "67+ & 2 other gens" 4 "67+ & 3 other gens"
		label values hhRiskCat67PLUS_5catsNoSingles hhRiskCat67PLUS_5catsNoSingles
		tab hhRiskCat67PLUS_5catsNoSingles
		tab hhRiskCat67PLUS_5catsNoSingles, nolabel
		tab hhRiskCat67PLUS_5catsNoSingles hhRiskCat67PLUS_5cats, miss
		*next, create another one that doesn't have 67+ living alone OR multiple 67+ year olds
		generate NoOnly67Plus=hhRiskCat67PLUS_5catsNoSingles
		replace NoOnly67Plus=. if hhRiskCat67PLUS_5catsNoSingles==1
		recode NoOnly67Plus 2=1 3=2 4=3
		label define NoOnly67Plus  1 "67+ & 1 other gen" 2 "67+ & 2 other gens" 3 "67+ & 3 other gens"
		label values NoOnly67Plus NoOnly67Plus
		tab NoOnly67Plus
		tab NoOnly67Plus, nolabel
		tab NoOnly67Plus hhRiskCat67PLUS_5catsNoSingles, miss
		*next, repeat MV adjusted linear with these variables 
		capture noisily stcox c.hhRiskCat67PLUS_5catsNoSingles##i.eth5 i.imd i.obese4cat i.rural_urbanFive i.smoke i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
		capture noisily estimates store mvAdjHHLinNoSingles
		capture noisily stcox c.NoOnly67Plus##i.eth5 $demogadjlistWInts, strata(utla_group) vce(cluster hh_id)
		capture noisily estimates store mvAdjHHLinNoOnly67Plus
	}
	else if "`dataset'"=="W2" {
		*(1)MV adjusted (without household size)
		capture noisily stcox i.hhRiskCat67PLUS_5cats##i.eth5 $demogadjlistWInts, strata(utla_group) vce(cluster hh_id)
		capture noisily estimates store mvAdj
		*(2)MV adjusted with main exposure linear
		capture noisily stcox c.hhRiskCat67PLUS_5cats##i.eth5 $demogadjlistWInts, strata(utla_group) vce(cluster hh_id)
		capture noisily estimates store mvAdjHHLin
		*(3)MV adusted with main exposure linear, having dropped the 67+ living alone
		*first, create a main exposure variable that doesn't have 67+ living alone (going to do this in the main analysis file)
		generate hhRiskCat67PLUS_5catsNoSingles=hhRiskCat67PLUS_5cats
		replace hhRiskCat67PLUS_5catsNoSingles=. if hhRiskCat67PLUS_5catsNoSingles==2
		recode hhRiskCat67PLUS_5catsNoSingles 1=1 3=2 4=3 5=4
		label define hhRiskCat67PLUS_5catsNoSingles  1 "Multiple 67+ year olds" 2 "67+ & 1 other gen" 3 "67+ & 2 other gens" 4 "67+ & 3 other gens"
		label values hhRiskCat67PLUS_5catsNoSingles hhRiskCat67PLUS_5catsNoSingles
		tab hhRiskCat67PLUS_5catsNoSingles
		tab hhRiskCat67PLUS_5catsNoSingles, nolabel
		tab hhRiskCat67PLUS_5catsNoSingles hhRiskCat67PLUS_5cats, miss
		*next, create another one that doesn't have 67+ living alone OR multiple 67+ year olds
		generate NoOnly67Plus=hhRiskCat67PLUS_5catsNoSingles
		replace NoOnly67Plus=. if hhRiskCat67PLUS_5catsNoSingles==1
		recode NoOnly67Plus 2=1 3=2 4=3
		label define NoOnly67Plus  1 "67+ & 1 other gen" 2 "67+ & 2 other gens" 3 "67+ & 3 other gens"
		label values NoOnly67Plus NoOnly67Plus
		tab NoOnly67Plus
		tab NoOnly67Plus, nolabel
		tab NoOnly67Plus hhRiskCat67PLUS_5catsNoSingles, miss
		*next, repeat MV adjusted linear with these variables 
		capture noisily stcox c.hhRiskCat67PLUS_5catsNoSingles##i.eth5 i.imd i.obese4cat i.rural_urbanFive i.smoke i.male i.coMorbCat, strata(utla_group) vce(cluster hh_id)
		capture noisily estimates store mvAdjHHLinNoSingles
		capture noisily stcox c.NoOnly67Plus##i.eth5 $demogadjlistWInts, strata(utla_group) vce(cluster hh_id)
		capture noisily estimates store mvAdjHHLinNoOnly67Plus
	}
	
	*helper variables
	sum eth5
	local maxEth5=r(max) 
	
	display "*************Ethnicity: 1************ "
	estimates restore mvAdj
	*(1) P-value for overall association of variable for white ethnicity
	capture noisily testparm i.hhRiskCat67PLUS_5cats
	*this is the linear hh lincom calculation one for when single category are still included
	display "**HH Linear - incl singles:**"
	estimates restore mvAdjHHLin
	capture noisily lincom hhRiskCat67PLUS_5cats, eform
	*this is the linear hh lincom calculation one for when single category are DROPPED
	display "**HH Linear - EXCL singles:**"
	estimates restore mvAdjHHLinNoSingles
	capture noisily lincom hhRiskCat67PLUS_5catsNoSingles, eform
	*this is the linear hh lincom calculation one for when single and multi 67+ year old category are DROPPED
	display "**HH Linear - EXCL singles and multi 67+:**"
	estimates restore mvAdjHHLinNoOnly67Plus
	capture noisily lincom NoOnly67Plus, eform
	*ethnicities other than white (using loop)
	forvalues e=2/`maxEth5' {
		display "*************Ethnicity: `e'************ "
		*next line: commented out while testing testparm etc
		*cap noisily outputHRsforvar, variable(hhRiskCat67PLUS_5cats) catLabel(hhRiskCat67PLUS_5cats) min(1) max(5) ethnicity(`e') outcome(`outcome')
		*THIS CODE: outputs p-values for hhRiskCat67PLUS_5cats variable by each ethnicity (overall association or test for trend)
		*call estimates
		estimates restore mvAdj
		*(1) P-value for overall association of variable within category of ethnicity (I think this is right??)
		capture noisily testparm i.hhRiskCat67PLUS_5cats#`e'.eth5
		*(2) P-value for test for trend - I think I need to rerun the model with main exposure continous for this to work, then lincom this
		*this is a check that I the new lincom calculation is correct
		*create counter for main exposure category
		sum hhRiskCat67PLUS_5cats
		local maxHHRiskCat=r(max)
		forvalues riskCat=1/`maxHHRiskCat' {
			capture noisily lincom `riskCat'.hhRiskCat67PLUS_5cats + `riskCat'.hhRiskCat67PLUS_5cats#`e'.eth5, eform
		}
		*this is the linear hh lincom calculation one for when single category are still included
		display "**HH Linear - incl singles:**"
		estimates restore mvAdjHHLin
		capture noisily lincom hhRiskCat67PLUS_5cats + hhRiskCat67PLUS_5cats#`e'.eth5, eform
		*this is the linear hh lincom calculation one for when single category are DROPPED
		display "**HH Linear - EXCL singles:**"
		estimates restore mvAdjHHLinNoSingles
		capture noisily lincom hhRiskCat67PLUS_5catsNoSingles + hhRiskCat67PLUS_5catsNoSingles#`e'.eth5, eform
		*this is the linear hh lincom calculation one for when single and multi 67+ year old category are DROPPED
		display "**HH Linear - EXCL singles and multi 67+:**"
		estimates restore mvAdjHHLinNoOnly67Plus
		capture noisily lincom NoOnly67Plus, eform
	}
	cap log close
}



