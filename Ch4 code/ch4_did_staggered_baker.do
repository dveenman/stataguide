global path "C:\home\dv\PROJECTS\STATA"

set seed 1234

scalar simnr=3 // 3 or 6

	use "$path\InFiles\simulation_data_baker.dta", clear	
	sum roa
	scalar sd_roa=r(sd)
	
	reghdfe roa, absorb(firm_fe=gvkey year_fe=fyear) resid
	predict res, res
	preserve
	keep res
	save "$path\OutFiles\simulation_data_res.dta", replace

	restore
	preserve
	gduplicates drop fyear, force
	keep year_fe
	save "$path\OutFiles\year_fe.dta", replace
	
	restore	
	gduplicates drop gvkey, force
	keep firm_fe
	save "$path\OutFiles\firm_fe.dta", replace
	
	use "$path\InFiles\simulation_data_baker.dta", clear
	keep gvkey fyear
	save "$path\OutFiles\shell.dta", replace
	
	use "$path\InFiles\simulation_data_baker.dta", clear
	keep gvkey
	gduplicates drop gvkey, force
	save "$path\OutFiles\firms.dta", replace
	
	use "$path\InFiles\simulation_data_baker.dta", clear
	keep fyear
	gduplicates drop fyear, force
	save "$path\OutFiles\years.dta", replace

	///////////////////////////////////////////////
	///////////////////////////////////////////////
	capture program drop simsample
	program define simsample
	
		// Sample firm FEs with replacement:
		use "$path\OutFiles\firm_fe.dta", clear
		bsample 
		merge using "$path\OutFiles\firms.dta"
		drop _merge
		order gvkey, before(firm_fe)
		gen double stateid=ceil(runiform()*50) 		
		save "$path\OutFiles\temp_firm_fe.dta", replace
		
		// Sample year FEs with replacement:
		use "$path\OutFiles\year_fe.dta", clear
		bsample 
		merge using "$path\OutFiles\years.dta"
		drop _merge
		order fyear, before(year_fe)
		save "$path\OutFiles\temp_year_fe.dta", replace

		// Sample residuals with replacement:
		use "$path\OutFiles\simulation_data_res.dta", clear
		bsample
		save "$path\OutFiles\temp_res.dta", replace
			
		// Create simulated sample:	
		use "$path\OutFiles\shell.dta", clear
		joinby gvkey using "$path\OutFiles\temp_firm_fe.dta", unmatched(master)
		drop _merge
		joinby fyear using "$path\OutFiles\temp_year_fe.dta", unmatched(master)
		drop _merge
		merge using "$path\OutFiles\temp_res.dta"
		drop _merge 		
		gen roa_sim=firm_fe+year_fe+res
		
		// Treatment indicators as assigned in BLW:
		gen treatgr=0
		replace treatgr=1 if stateid<=17
		replace treatgr=2 if stateid>17 & stateid<=35
		replace treatgr=3 if stateid>35 & stateid<=50

		gen treatyr=0 if treatgr==0
		replace treatyr=1989 if treatgr==1
		replace treatyr=1998 if treatgr==2
		replace treatyr=2007 if treatgr==3
		
		gen post_treat=0 
		replace post_treat=1 if treatgr==1 & fyear>=treatyr
		replace post_treat=1 if treatgr==2 & fyear>=treatyr
		replace post_treat=1 if treatgr==3 & fyear>=treatyr
		
		// Add treatment:
		gen roa_treat=roa_sim
		
		if simnr==6 {
			replace roa_treat=roa_treat+0.05*sd_roa*(fyear-treatyr+1) if treatgr==1 & fyear>=treatyr
			replace roa_treat=roa_treat+0.03*sd_roa*(fyear-treatyr+1) if treatgr==2 & fyear>=treatyr
			replace roa_treat=roa_treat+0.01*sd_roa*(fyear-treatyr+1) if treatgr==3 & fyear>=treatyr			
		}
		if simnr==3 {
			replace roa_treat=roa_treat+0.5*sd_roa if treatgr==1 & fyear>=treatyr
			replace roa_treat=roa_treat+0.5*sd_roa if treatgr==2 & fyear>=treatyr
			replace roa_treat=roa_treat+0.5*sd_roa if treatgr==3 & fyear>=treatyr
		}
				
		sum roa_treat, d
		winsor roa_treat, gen(roa_treat_w) p(0.01)
		sum roa_treat_w, d
	
	end
	///////////////////////////////////////////////
	///////////////////////////////////////////////
	
	simsample
	sum roa_treat_w, d

	keep gvkey fyear roa_treat_w stateid post_treat treatgr treatyr
	ren roa_treat_w roa_sim
	reghdfe roa_sim post_treat, absorb(stateid fyear) cluster(stateid) 
	reghdfe roa_sim post_treat, absorb(gvkey fyear) cluster(stateid) 	
	save "$path\OutFiles\did_sample_baker.dta", replace

	////////////////////////////////////////
	// Stacked option 1:
	use "$path\OutFiles\did_sample_baker.dta", clear
	keep if treatgr==1 | (treatgr==2 & fyear<treatyr) | (treatgr==3 & fyear<treatyr)
	gen dataset=1
	save "$path\OutFiles\did_sample_baker_sub1.dta", replace
	
	use "$path\OutFiles\did_sample_baker.dta", clear
	keep if treatgr==2 | (treatgr==3 & fyear<treatyr)
	gen dataset=2
	save "$path\OutFiles\did_sample_baker_sub2.dta", replace
	
	use "$path\OutFiles\did_sample_baker_sub1.dta", clear
	append using "$path\OutFiles\did_sample_baker_sub2.dta"
	sum dataset
	
	egen gvkey_stacked=group(gvkey dataset)
	egen fyear_stacked=group(fyear dataset)
	
	reghdfe roa_sim post_treat, cluster(stateid) absorb(gvkey_stacked fyear_stacked)
	
	////////////////////////////////////////
	// Stacked option 2:
	use "$path\OutFiles\did_sample_baker.dta", clear
	tabstat treatyr, by(treatgr) stats(N mean)
	
	sum treatgr
	scalar cohorts=r(max)
	if r(min)>0 {
		scalar cohorts=cohorts-1
	}
	di "number of cohorts: " cohorts 
	
	gen n=_n
	expand cohorts
	bysort n: gen dataset=_n
	
	gen keep=1 if treatgr==dataset
	replace keep=1 if treatgr==0
	sum dataset
	local k=r(max)
	forvalues i=1(1)`k'{
		replace keep=1 if dataset==`i' & treatgr>`i' & fyear<treatyr
	}
	keep if keep==1
	sum keep
	
	egen gvkey_stacked=group(gvkey dataset)
	egen fyear_stacked=group(fyear dataset)
	reghdfe roa_sim post_treat, cluster(stateid) absorb(gvkey_stacked fyear_stacked)
	
	
	
	
	
	
	
	
	
	
	
	
	
	