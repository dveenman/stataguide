global path "C:\home\dv\PROJECTS\STATA"	

* FIGURE 2 VV2022

use "$path\InFiles\vvdata_table6.dta", clear
xtile quintile1=qdispann, nq(5)
keep surp_ibes quintile1
	
graph set window fontface "Times New Roman"
	
twoway ///
	(kdensity surp_ibes if abs(surp_ibes)<=20 & quintile1==1, ///
		lcolor("150 1 1") ///
		lwidth(medthick) ///
		lpattern(solid) ///
		kernel(gaussian) ///
		bwidth(1)) ||  ///
	(kdensity surp_ibes if abs(surp_ibes)<=20 & quintile1==5, ///
		lcolor("38 70 156") ///
		lwidth(medthick) ///
		lpattern(dash) ///
		kernel(gaussian) ///
		bwidth(1)), ///
	xlabel(-20(2)20, labsize(medium)) ///
	yscale(range(.00 .17)) ///
	ylabel(0(0.05).15, labsize(medium) format(%6.2fc)) ///
	legend(on order(1 2) ///
		label(1 "Frequency for low dispersion firms (Q1)") ///
		label(2 "Frequency for high dispersion firms (Q5)") ///
		size(medium) ///
		region(lcolor(white)) ///
		ring(0) ///
		bplacement(north) ///
		cols(2)) ///
	graphregion(color(white) margin(zero)) ///
	bgcolor(white) ///
	xtitle("{bf:Earnings surprise bin (cents per share)}", ///
		size(medium) height(5)) ///
	ytitle("{bf:Frequency}", ///
		size(medium) height(5))

set printcolor asis
graph export "$path\Doc\fig_vv.png", replace
graph export "$path\Doc\fig_vv.pdf", replace
	