global path "C:\home\dv\PROJECTS\STATA"	

	use "$path\OutFiles\monthlyret_nld_ceq.dta", clear
	drop if retm==.
	drop if lagmv==.
	drop if ceq==.
	replace ceq=ceq*1000000
	gen btm=ceq/lagmv
	sum btm,d
	gen mvq=.
	gen btmq=.
	sort gvkey year month
	egen yearmonth=group(year month)
	sum yearmonth
	scalar maxy=r(max)
	local k=maxy
	forvalues i=1(1)`k'{
		qui xtile xmv=mv if yearmonth==`i', nq(5)
		qui replace mvq=xmv if yearmonth==`i'
		qui drop xmv
		qui xtile xbtm=btm if yearmonth==`i', nq(5)
		qui replace btmq=xbtm if yearmonth==`i'
		qui drop xbtm
		di `i' " / " `k'	
	}

	gen ret12=retm if mvq==1 | mvq==2
	gen ret45=retm if mvq==4 | mvq==5
	egen ewret12=mean(ret12),by(yearmonth)
	egen ewret45=mean(ret45),by(yearmonth)
	gen smb=ewret12-ewret45
	drop ret12 ret45 ewret12 ewret45
	gen ret12=retm if btmq==1 | btmq==2
	gen ret45=retm if btmq==4 | btmq==5
	egen ewret12=mean(ret12),by(yearmonth)
	egen ewret45=mean(ret45),by(yearmonth)
	gen hml=ewret45-ewret12
	drop ret12 ret45 ewret12 ewret45
	sum smb hml
	save "$path\OutFiles\monthlyret_factors1.dta", replace

	use "$path\OutFiles\monthlyret_factors1.dta", clear
	egen summv=sum(lagmv),by(year month)
	gen weight=lagmv/summv
	sum weight, d
	gen wret=weight*retm
	egen mktret=sum(wret), by(year month)
	duplicates drop year month, force
	sum mktret smb hml
	save "$path\OutFiles\monthlyret_factors2.dta", replace
	
	use "$path\OutFiles\monthlyret_nld_ceq.dta", clear
	joinby year month using "$path\OutFiles\monthlyret_factors2.dta", unmatched(master)
	drop _merge
	sum retm mktret smb hml
	reg retm mktret smb hml
	
	keep gvkey year month retm mktret smb hml
	sort gvkey year month
	egen fid=group(gvkey)
	by gvkey: gen nr=_n
	gen nr2=nr-18
	replace nr2=. if nr2<1
	egen maxnr2=max(nr2),by(fid)
	drop if maxnr2==.
	drop fid maxnr2
	egen fid=group(gvkey)
	save "$path\OutFiles\monthlyret_nld_ceq2.dta", replace

	use "$path\OutFiles\monthlyret_nld_ceq2.dta", clear
	gen beta0=.
	gen beta1=.
	gen beta2=.
	gen beta3=.
	gen countobs=.
	sum fid
	scalar maxp=r(max)
	local p=maxp
	forvalues i=1(1)`p'{
		qui sum nr2 if fid==`i'
		scalar maxn=r(max)
		local n=maxn
		forvalues j=1(1)`n'{
			qui reg retm mktret smb hml if fid==`i' & nr<=`j'+17 & nr>`j'-43
			qui replace beta0=_b[_cons] if fid==`i' & nr2==`j'
			qui replace beta1=_b[mktret] if fid==`i' & nr2==`j'
			qui replace beta2=_b[smb] if fid==`i' & nr2==`j'
			qui replace beta3=_b[hml] if fid==`i' & nr2==`j'
			qui replace countobs=e(N) if fid==`i' & nr2==`j'
			di `i' " /// " `p' " : " `j' " \\\ " `n'
		}
	}
	sum beta*
	gen abret=ret-beta0-beta1*mktret-beta2*smb-beta3*hml
	sum abret,d
	save "$path\OutFiles\monthlyret_ff3.dta", replace

