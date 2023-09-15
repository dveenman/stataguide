global path "C:\home\dv\PROJECTS\STATA"	

*****************************************************************
* Compute discretionary accruals using CRSP/Compustat merged file
*****************************************************************
	use "$path\InFiles\ccm_annual.dta", clear	
	destring gvkey, replace
	ren lpermno permno
	drop if at==. | at<=0
	keep if fic=="USA"
	destring sic, replace
	replace sic=sich if sich!=.
	drop if sic==.
	drop if sic>5999 & sic<7000
	
	// This requires more careful inspection:
	duplicates report gvkey fyear
	gsort gvkey fyear -datadate
	duplicates drop gvkey fyear, force
	tsset gvkey fyear

	// Compute variables:
	gen lagta=l.at
	gen tacc=(ibc-oancf)/lagta
	gen drev=(d.sale-d.rect)/lagta
	gen inverse_a=1/lagta
	gen ppe=ppegt/lagta
	drop if tacc==.
	drop if drev==.
	drop if ppe==.
	
	tostring sic, format(%04.0f) replace
	gen sic2=substr(sic,1,2)
	egen sic2id=group(sic2 fyear)
	sort sic2id
	egen count=count(sic2id), by(sic2id)
	drop if count<20
	drop count sic2id
	egen sic2id=group(sic2 fyear)
	
	sum tacc,d
	replace tacc=r(p1) if tacc<r(p1)
	replace tacc=r(p99) if tacc>r(p99) & tacc!=.
	sum drev,d
	replace drev=r(p1) if drev<r(p1)
	replace drev=r(p99) if drev>r(p99) & drev!=.
	sum inverse_a,d
	replace inverse_a=r(p99) if inverse_a>r(p99) & inverse_a!=.
	sum ppe,d
	replace ppe=r(p99) if ppe>r(p99) & ppe!=.
	
	gen dac=.
	gen r2a=.
	gen b1=.
	gen b2=.
	gen b3=.
	
	// Estimation by separate OLS estimations for each group:
	timer clear
	timer on 1
	sum sic2id
	local k=r(max)
	forvalues i=1(1)`k'{
		qui reg tacc inverse_a drev ppe if sic2id==`i'
		qui predict res if sic2id==`i', res
		qui replace dac=res if sic2id==`i'
		qui replace r2a=e(r2_a) if sic2id==`i'
		qui replace b1=_b[inverse_a] if sic2id==`i'
		qui replace b2=_b[drev] if sic2id==`i'
		qui replace b3=_b[ppe] if sic2id==`i'
		qui drop res
		di `i' " / " `k'
	}
	timer off 1
	tabstat r2a dac b1 b2 b3, stats(N mean p25 median p75) columns(statistics)

	// Alternative usingr rangestat:
	timer on 2
	rangestat (reg) tacc inverse_a drev ppe, interval(fyear 0 .) by(sic2id)
	gen dac_rangestat=tacc-b_cons-(b_inverse_a*inverse_a)-(b_drev*drev)-(b_ppe*ppe)
	timer off 2
	sum dac dac_rangestat
	pwcorr dac dac_rangestat
	
	// Estimation using one-step estimation:
	timer on 3
	reghdfe tacc, absorb(sic2id##c.(inverse_a drev ppe)) resid noconst
	predict dac_reghdfe, res
	timer off 3
	sum dac dac_reghdfe
	pwcorr dac dac_reghdfe
	timer list

	// Create and include random test variable for illustration:
	set seed 1234
	gen part=0
	replace part=1 if runiform()<.25
	reghdfe tacc part, absorb(sic2id##c.(inverse_a drev ppe)) resid noconst
	
	keep gvkey fyear dac*
	save "$path\OutFiles\ccm_annual_da.dta", replace

	
	
