global path "C:\home\dv\PROJECTS\STATA"

*******************************************************
* Walkdown graph: combined
*******************************************************
	graph set window fontface "Times New Roman"
	
	use "$path\InFiles\output_walkdown_sellside.dta", clear
	joinby d using "$path\InFiles\output_walkdown_estimize.dta", unmatched(master)
	drop _merge
	
	replace low1=1-low1
	replace low2=1-low2
	replace mean1=1-mean1
	replace mean2=1-mean2
	replace high1=1-high1
	replace high2=1-high2
	
	//Panel A:
	format low1 mean1 high1 low2 mean2 high2 %6.2f
	graph set window fontface "Times New Roman"
	
	twoway ///
		rarea high1 low1 d, color("150 1 1 %15") lcolor(%0) || ///
		line mean1 d, lcolor("150 1 1 %80") || ///
		rarea high2 low2 d, fcolor("38 70 156%10") lcolor("38 70 156 %75") lpattern(shortdash) || ///
		line mean2 d, lpattern(shortdash) lcolor("38 70 156 %80") ///
		xlabel(-180(30)-30, labsize(medlarge)) ///
		ylabel(0.3(0.1)0.6,labsize(medlarge)) ///
		legend(on order(4 2) label(2 "Sell-side consensus") ///
			size(medlarge) label(4 "Crowdsourced consensus") ///
			region(lcolor(white)) ring(0) bplacement(swest) cols(1)) ///
			plotregion(m(zero)) ///
		graphregion(color(white) margin(zero)) ///
		xtitle("{bf:Calendar days relative to earnings announcement date}", size(medlarge) height(5)) ///
		ytitle("{bf:Fraction of day {it:t} consensus optimistic vs. pessimistic}", size(medlarge) height(5)) /// 
		bgcolor(white) ///
		yscale(range(0.27 0.615)) /// 
		title("{bf:Panel A:} Crowd vs. sell-side (EPS)", ring(0) size(vlarge)) ///
	saving(one, replace) 

	use "$path\InFiles\output_walkdown_estimize_sellside.dta", clear
	joinby d using "$path\InFiles\output_walkdown_estimize_excl.dta", unmatched(master)
	drop _merge
	
	replace low3=1-low3
	replace low4=1-low4
	replace mean3=1-mean3
	replace mean4=1-mean4
	replace high3=1-high3
	replace high4=1-high4
	
	//Panel B:
	format low3 mean3 high3 low4 mean4 high4 %6.2f
	graph set window fontface "Times New Roman"
	twoway ///
		rarea high3 low3 d, color("150 1 1 %15") lcolor(%0) || ///
		line mean3 d, lcolor("150 1 1 %80") || ///
		rarea high4 low4 d, fcolor("38 70 156%10") lcolor("38 70 156 %75") lpattern(shortdash) || ///
		line mean4 d, lpattern(shortdash) lcolor("38 70 156 %80") ///
		xlabel(-180(30)-30, labsize(medlarge)) ///
		ylabel(0.3(0.1)0.6,labsize(medlarge)) ///
		legend(on order(4 2) label(2 "Crowdsourced consensus: sell-side only") ///
			size(medlarge) label(4 "Crowdsourced consensus: excl. sell-side") ///
			region(lcolor(white)) ring(0) bplacement(swest) cols(1)) ///
			plotregion(m(zero)) ///
		graphregion(color(white) margin(zero)) ///
		xtitle("{bf:Calendar days relative to earnings announcement date}", size(medlarge) height(5)) ///
		bgcolor(white) ///
		yscale(range(0.27 0.615)) ///
		title("{bf:Panel B:} Crowd split by contributor type (EPS)", ring(0) size(vlarge)) ///
	saving(two, replace)
		
*******************************************************
* Walkdown graph: combined - sales forecasts
*******************************************************
	use "$path\InFiles\output_walkdown_sellside_sales.dta", clear
	joinby d using "$path\InFiles\output_walkdown_estimize_sales.dta", unmatched(master)
	drop _merge
	
	replace low1=1-low1
	replace low2=1-low2
	replace mean1=1-mean1
	replace mean2=1-mean2
	replace high1=1-high1
	replace high2=1-high2
	
	//Panel C:
	format low1 mean1 high1 low2 mean2 high2 %6.2f
	graph set window fontface "Times New Roman"
	twoway ///
		rarea high1 low1 d, color("150 1 1 %15") lcolor(%0) || ///
		line mean1 d, lcolor("150 1 1 %80") || ///
		rarea high2 low2 d, fcolor("38 70 156%10") lcolor("38 70 156 %75") lpattern(shortdash) || ///
		line mean2 d, lpattern(shortdash) lcolor("38 70 156 %80") ///
		xlabel(-180(30)-30, labsize(medlarge)) ///
		ylabel(0.3(0.1)0.6,labsize(medlarge)) ///
		legend(on order(4 2) label(2 "Sell-side consensus") ///
			size(medlarge) label(4 "Crowdsourced consensus") ///
			region(lcolor(white)) ring(0) bplacement(swest) cols(1)) ///
			plotregion(m(zero)) ///
		graphregion(color(white) margin(zero)) ///
		xtitle("{bf:Calendar days relative to earnings announcement date}", size(medlarge) height(5)) ///
		ytitle("{bf:Fraction of day {it:t} consensus optimistic vs. pessimistic}", size(medlarge) height(5)) /// 
		bgcolor(white) ///
		ysize(3) ///
		yscale(range(0.27 0.615)) /// 
		title("{bf:Panel C:} Crowd vs. sell-side (SAL)", ring(0) size(vlarge)) ///
	saving(three, replace) 

	use "$path\InFiles\output_walkdown_estimize_sales_sellside.dta", clear
	joinby d using "$path\InFiles\output_walkdown_estimize_sales_excl.dta", unmatched(master)
	drop _merge
	
	replace low3=1-low3
	replace low4=1-low4
	replace mean3=1-mean3
	replace mean4=1-mean4
	replace high3=1-high3
	replace high4=1-high4
	
	//Panel D:
	format low3 mean3 high3 low4 mean4 high4 %6.2f
	graph set window fontface "Times New Roman"
	twoway ///
		rarea high3 low3 d, color("150 1 1 %15") lcolor(%0) || ///
		line mean3 d, lcolor("150 1 1 %80") || ///
		rarea high4 low4 d, fcolor("38 70 156%10") lcolor("38 70 156 %75") lpattern(shortdash) || ///
		line mean4 d, lpattern(shortdash) lcolor("38 70 156 %80") ///
		xlabel(-180(30)-30, labsize(medlarge)) ///
		ylabel(0.3(0.1)0.6,labsize(medlarge)) ///
		legend(on order(4 2) label(2 "Crowdsourced consensus: sell-side only") ///
			size(medlarge) label(4 "Crowdsourced consensus: excl. sell-side") ///
			region(lcolor(white)) ring(0) bplacement(swest) cols(1)) ///
			plotregion(m(zero)) ///
		graphregion(color(white) margin(zero)) ///
		xtitle("{bf:Calendar days relative to earnings announcement date}", size(medlarge) height(5)) ///
		bgcolor(white) ///
		ysize(3) ///
		yscale(range(0.27 0.615)) ///
		title("{bf:Panel D:} Crowd split by contributor type (SAL)", ring(0) size(vlarge)) ///
	saving(four, replace)
	
	graph combine one.gph two.gph, graphregion(color(white) margin(zero) lpattern(none)) ysize(2.5)
	set printcolor asis
	graph export "$path\Doc\fig_walkdown_stata_combined.pdf", replace

	graph combine three.gph four.gph, graphregion(color(white) margin(zero) lpattern(none)) ysize(2.5)
	set printcolor asis
	graph export "$path\Doc\fig_walkdown_stata_combined_sales.pdf", replace
	
