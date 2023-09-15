global path "C:\home\dv\PROJECTS\STATA\"

	use "$path\InFiles\data_ifrs_liq.dta", clear
	sum year zeroreturn

	gen post=0 if year<2005
	replace post=1 if year>2005
	
	// Matrix:
	tabulate ifrs post, summarize(zeroreturn) means
	tabulate year ifrs, summarize(zeroreturn) means

	// Interaction regression:
	gen post_ifrs=post*ifrs
	reg zeroreturn ifrs post post_ifrs, cluster(countryid) 
	reg zeroreturn ifrs##post, cluster(countryid) 
	
	// Adding time and country fixed effects:
	reg zeroreturn i.year i.countryid ifrs post post_ifrs, cluster(countryid) 
	reg zeroreturn i.year i.countryid post_ifrs, cluster(countryid) 

	// Absorbing fixed effects:
	areg zeroreturn ifrs post post_ifrs, cluster(countryid) absorb(gvkey)
	areg zeroreturn i.year i.countryid ifrs post post_ifrs, cluster(countryid) absorb(gvkey)
	reghdfe zeroreturn post_ifrs, cluster(countryid) absorb(countryid year)
	reghdfe zeroreturn post_ifrs, cluster(countryid) absorb(gvkey year)
	reghdfe zeroreturn ifrs post post_ifrs, cluster(countryid) absorb(gvkey year)
	
	// Parallel trends:
	preserve

	collapse (mean) zeroreturn, by(ifrs year)
	
	global options "xline(2005) legend(on order(1 2) label(1 "IFRS==1") label(2 "IFRS==0") cols(2) position(12))"

	sort year
	graph twoway connect zeroreturn year if ifrs==1, $options || ///
		connect zeroreturn year if ifrs==0, lpattern(dash) || ///
		lfit zeroreturn year if ifrs==1 & year<2005 || ///
		lfit zeroreturn year if ifrs==0 & year<2005 || ///
		lfit zeroreturn year if ifrs==1 & year>2005 || ///
		lfit zeroreturn year if ifrs==0 & year>2005

	set printcolor asis
	graph export "$path\Doc\fig_did_parallel.png", replace
	graph export "$path\Doc\fig_did_parallel.pdf", replace
		
	restore

	sum year
	gen time=1+year-r(min)
	reg zeroreturn i.ifrs##c.time if year<2005, cluster(countryid) 
	reg zeroreturn i.ifrs##c.time if year>2005, cluster(countryid) 

	// Placebo:
	gen placebo=0 if year<2005
	replace placebo=1 if ifrs==1 & year>2000 & year<2005
	reghdfe zeroreturn placebo, cluster(countryid) absorb(gvkey year)
		
	// Dynamic graph:
	forvalues i=2001(1)2010{
		gen p_`i'=0 
		replace p_`i'=ifrs if year==`i'
	}
	
	reghdfe zeroreturn p_* if year>=2000 & year<=2010, cluster(countryid) absorb(gvkey year) noconstant
	coefplot, vertical yline(0) 

	graph export "$path\Doc\fig_did_parallel_dyn.png", replace
	graph export "$path\Doc\fig_did_parallel_dyn.pdf", replace
	


		
		
		
		
		
	
	
	