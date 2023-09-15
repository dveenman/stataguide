global path "C:\home\dv\PROJECTS\STATA"	

	use "$path\InFiles\lvdata.dta", clear	
	logit treatment timedum_* lnta btm lnage salesgr lnsdearn spdum rnd div cfo acc expsc inta depr ng_indus
	predict fit, xb
	gen pscore=exp(fit)/(1+exp(fit)) 
	sum treatment pscore 
	
	tabstat pscore, by(treatment)
	
	psmatch2 treatment timedum_* lnta btm lnage salesgr lnsdearn spdum rnd div cfo acc expsc inta depr ng_indus, n(1) common caliper(0.01) logit noreplace outc(cfop1)
	
	// Inspect distributions of propensity scores for unmatched observations:
	sum pscore if treatment==1 & _weight==.
	sum pscore if treatment==0 & _weight==.
	
	// New variables:
	sum _pscore _treated _support _weight _cfop1 _id _n1 _nn _pdif
	
	gen treat_psm=0 if _weight!=. & treatment==0
	replace treat_psm=1 if _weight!=. & treatment==1
	logit treat_psm timedum_* lnta btm lnage salesgr lnsdearn spdum rnd div cfo acc expsc inta depr ng_indus
	tabstat lnta btm lnage salesgr lnsdearn spdum rnd div cfo acc expsc inta depr ng_indus, by(treat_psm) 
	
	reghdfe lnta treat_psm, cluster(cik qid) noab
	
	reg cfop1 treat_psm
	reghdfe cfop1 treat_psm, cluster(cik qid) noab	
	reghdfe cfop1 timedum_* indusdum_* cfo acc_gaap lnta btm lnage salesgr lnsdearn spdum rnd div expsc inta depr ng_indus treat_psm, cluster(cik qid) noab
	
