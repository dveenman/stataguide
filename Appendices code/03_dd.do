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
	gen avta=(l.at+at)/2
	gen cfom1=l.oancf/avta
	gen cfo=oancf/avta
	gen cfop1=f.oancf/avta
	gen wca=(ibc-oancf+dpc)/avta
	gen dsal=(d.sale)/avta
	gen ppeg=ppegt/avta
	gen sales=sale/avta
	drop if wca==.
	drop if cfom1==.
	drop if cfo==.
	drop if cfop1==.
	drop if dsal==.
	drop if ppeg==.
	drop if sales==.
	
	tostring sic, format(%04.0f) replace
	gen sic2=substr(sic,1,2)
	egen sic2id=group(sic2 fyear)
	sort sic2id
	egen count=count(sic2id), by(sic2id)
	drop if count<20
	drop count sic2id
	egen sic2id=group(sic2 fyear)
	
	sum wca,d
	replace wca=r(p1) if wca<r(p1)
	replace wca=r(p99) if wca>r(p99) & wca!=.
	sum cfom1,d
	replace cfom1=r(p1) if cfom1<r(p1)
	replace cfom1=r(p99) if cfom1>r(p99) & cfom1!=.
	sum cfo,d
	replace cfo=r(p1) if cfo<r(p1)
	replace cfo=r(p99) if cfo>r(p99) & cfo!=.
	sum cfop1,d
	replace cfop1=r(p1) if cfop1<r(p1)
	replace cfop1=r(p99) if cfop1>r(p99) & cfop1!=.
	sum dsal,d
	replace dsal=r(p1) if dsal<r(p1)
	replace dsal=r(p99) if dsal>r(p99) & dsal!=.
	sum ppeg,d
	replace ppeg=r(p1) if ppeg<r(p1)
	replace ppeg=r(p99) if ppeg>r(p99) & ppeg!=.
	sum sales,d
	replace sales=r(p1) if sales<r(p1)
	replace sales=r(p99) if sales>r(p99) & sales!=.
	
	gen residual=.
	gen adjr2=.
	gen b0=.
	gen b1=.
	gen b2=.
	gen b3=.
	gen b4=.
	gen b5=.
	
	// Step 1: compute residuals by industry-year group:
	sum sic2id
	local k=r(max)
	forvalues i=1(1)`k'{
		qui reg wca cfom1 cfo cfop1 dsal ppeg if sic2id==`i'
		qui predict res if sic2id==`i', res
		qui replace residual=res if sic2id==`i'
		qui replace adjr2=e(r2_a) if sic2id==`i'
		qui replace b0=_b[_cons] if sic2id==`i'
		qui replace b1=_b[cfom1] if sic2id==`i'
		qui replace b2=_b[cfo] if sic2id==`i'
		qui replace b3=_b[cfop1] if sic2id==`i'
		qui replace b4=_b[dsal] if sic2id==`i'
		qui replace b5=_b[ppeg] if sic2id==`i'
		qui drop res
		di `i' " / " `k'
	}
	sort gvkey fyear
	tabstat adjr2 residual b0 b1 b2 b3 b4 b5, stats(N mean p25 median p75) columns(statistics)
	save "$path\OutFiles\ccm_annual_dd.dta", replace

	// Step 2: rolling-window standard deviations of the residuals:
	use "$path\OutFiles\ccm_annual_dd.dta", clear
	gen sdresidual=.
	gen countobs=.
	sort gvkey fyear
	egen nr=group(fyear)
	egen minnr=min(nr), by(gvkey)
	replace nr=nr-min+1	
	egen firmid=group(gvkey)
	sum firmid
	local m=r(max)
	forvalues i=1(1)`m'{
		qui sum nr if firmid==`i'
		local n=r(min)+2
		local p=r(max)
		if `p'>2 {
		forvalues j=`n'(1)`p'{
			qui gen hulpvar=1 if firmid==`i' & nr<=`j' & nr>`j'-5
			qui sum residual if hulpvar==1
			qui replace sdresidual=r(sd) if firmid==`i' & nr==`j'
			qui replace countobs=r(N) if firmid==`i' & nr==`j'
			qui drop hulpvar
			di `i' " / " `j' " / " `m'
			}
		}
	}
	replace sdresidual=. if countobs<3
	replace countobs=. if countobs<3
	sort gvkey fyear
	sum fyear sdresidual countobs
	tabstat countobs, by(countobs) stats(N)
	
	// Alternative, much faster approach:
	reghdfe wca, absorb(sic2id##c.(cfom1 cfo cfop1 dsal ppeg)) resid noconst
	predict residual_reghdfe, res
	sum residual_reghdfe residual	
	sort gvkey fyear
	gen n=_n
	gen res_1=residual_reghdfe
	gen res_2=l.residual_reghdfe
	gen res_3=l2.residual_reghdfe
	gen res_4=l3.residual_reghdfe
	gen res_5=l4.residual_reghdfe
	reshape long res_, i(n) j(j)
	egen sdresidual_alt=sd(res_), by(n)
	egen countobs_alt=count(res_), by(n)
	replace sdresidual_alt=. if countobs_alt<3
	keep if j==1
	sort gvkey fyear
	sum sdresidual sdresidual_alt
	pwcorr sdresidual sdresidual_alt
	
	keep gvkey fyear sdresidual*	
	save "$path\OutFiles\ccm_annual_dd_sdresidual.dta", replace

