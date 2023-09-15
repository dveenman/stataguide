global path "C:\home\dv\PROJECTS\STATA\"

	use "$path\InFiles\vvdata.dta", clear
	forvalues i=1(1)15{
		qui gen m_`i'=.
	}
	
	local varlist "qsumpess qlnmv qlnbtm qlagret1 qlagret qidvol qinst qlnn qassetgr qopprof qdqearn qes_lag*"
	
	forvalues i=1(1)360{
		di `i'
		qui logit nonneg `varlist' if ym==`i'
		qui local obs = e(N)
		qui mfx if ym==`i', var(`varlist') 
		qui mat margeff = e(Xmfx_dydx)
		qui svmat margeff 
		forvalues j=1(1)15{
			qui sum margeff`j'
			qui replace m_`j'=r(mean) if ym==`i'
		}
		qui drop margeff*
	}
	duplicates drop ym, force
	tabstat m_*, columns(statistics)
	
