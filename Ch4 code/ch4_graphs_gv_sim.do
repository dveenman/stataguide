global path "C:\home\dv\PROJECTS\STATA"

*****************************************************************************
*****************************************************************************
	graph set window fontface "Times New Roman"
	
	//Create mixture distribution of firms in different ``life cycles'':
	set seed 1234
	clear
	
	set obs 1000000
	gen lc=ceil(_n/(_N/3))
	gen lc1=0
	replace lc1=1 if lc==1
	
	gen double roa=.
	replace roa=.0055+rnormal()*.117 if lc==1
	replace roa=.0241+rnormal()*.085 if lc==2
	replace roa=.0396+rnormal()*.052 if lc==3
	sum roa, d
	gen roanormal=r(mean)+r(sd)*rnormal()
	
	gen double bin=round(roa*20)/20 if abs(roa)<.5
	sum bin, d
	replace bin=-0.5 if roa<-0.5
	replace bin=0.5 if roa>0.5	
	egen meanlc1=mean(lc1), by(bin)
	bysort bin: gen n=_n
	
	//Create first figure:
	twoway ///
		hist roa, dens color(navy%10) lcolor(navy%30) ///
			lwidth(thin) width(0.01) yaxis(1) || ///
		kdensity roanormal, bw(.01) lcolor(maroon) ///
			yaxis(1) yscale(lstyle(none) axis(1)) || ///
		scatter meanlc1 bin if n==1, msymbol(D) msize(medsmall) mlcolor(maroon) mcolor(none) mlwidth(medthin) ///
			yaxis(2) yscale(range(0 1) lstyle(none) axis(2)) ///
		title("{bf:Panel A:} Contaminated normal distribution", size(medium)) ///
		graphregion(color(white) margin(zero)) ///
		bgcolor(white) ///
		ylabel("", axis(1)) ///
		ylabel("", axis(2)) ///
		xlabel(-.5(.25).5, labsize(medium) format(%6.2fc)) ///
		xscale(range(-.6 .6)) ///
		legend(on order(1 2 3) ///
			label(1 "Pooled sample") ///
			label(2 "Normal density") ///
			label(3 "Fraction young firms") ///
			size(medium) ///
			region(lcolor(white)) ///
			cols(1) ///
            position(6)) ///
		ytitle("", axis(1)) ///
		ytitle("", axis(2)) ///
		xtitle("") ///
	saving(one, replace) 
	
*****************************************************************************
*****************************************************************************
	
	// Simulate data to demonstrate effects of using a noisy scale proxy
	set seed 1234
	clear

	matrix C=(1,.95\.95,1)
	corr2data lnscale0 lnscale, corr(C) n(1000000) double
	replace lnscale0=5.5+lnscale0*2.3
	replace lnscale=5.5+lnscale*2.3
	
	gen double roa=0.026+rnormal()*0.080
	gen double scale0=exp(lnscale0)
	gen double ni=scale0*roa
	gen double scale=exp(lnscale)
	gen double roa2=ni/scale
	replace roa2=-.5 if roa2<-.5
	replace roa2=.5 if roa2>.5
	
	gen double bin=round(roa2*20)/20
	xtile size=scale, nq(10)
	gen small=0
	replace small=1 if size==1
	egen meansmall=mean(small), by(bin)
	bysort bin: gen n=_n
	
	//Create second figure:
	twoway ///
		hist roa2 if abs(roa2)<=1, dens color(navy%10) ///
			lcolor(navy%30) lwidth(thin) width(0.01) || ///
		kdensity roa, bw(.01) lcolor(maroon) ///
			yaxis(1) yscale(lstyle(none) axis(1)) || ///
		scatter meansmall bin if n==1, msymbol(D) msize(medsmall) mlcolor(maroon) mcolor(none) mlwidth(medthin) ///
			yaxis(2) yscale(range(0 .2) lstyle(none) axis(2)) ///
		ylabel("", axis(1)) ///
		ylabel("", axis(2)) ///
		title("{bf:Panel B:} Effects of scaling by a noisy proxy", size(medium)) ///
		graphregion(color(white) margin(zero)) ///
		bgcolor(white) ///
		xscale(range(-.52 .52)) ///
		xlabel(-.5(.25).5, labsize(medium) format(%6.2fc)) ///
		legend(on order(1 2 3) ///
			label(1 "Scaled earnings") ///
			label(2 "True profitability (unobserved)") ///
			label(3 "Fraction smallest firms") ///
			size(medium) ///
			region(lcolor(white)) ///
			cols(1) ///
            position(6)) ///
		ytitle("", axis(1)) ///
		ytitle("", axis(2)) ///
		xtitle("") ///
	saving(two, replace)

*****************************************************************************
*****************************************************************************
	
	graph combine one.gph two.gph, graphregion(color(white) margin(zero) lpattern(none)) 

	set printcolor asis
	graph export "$path\Doc\gv_sim_combined.png", replace
	graph export "$path\Doc\gv_sim_combined.pdf", replace

	

