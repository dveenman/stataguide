global path "C:\home\dv\PROJECTS\STATA"	

	use "$path\InFiles\data_auditfees.dta", clear

    sum fyear
    tabstat fyear, by(fyear) stats(N)
    sum big4 
    sum big4 if big4==1
    sum big4 if big4==0

	psmatch2 big4 lnassets aturn curr lev roa salesgr, n(1) logit noreplace outc(lnauditfees)	
    sum _weight
    sum big4 if big4==0 & _weight==.

    // Propensity scores before matching:
    tabstat _pscore, by(big4)
	
    // Propensity scores after matching:
    tabstat _pscore if _weight!=., by(big4)

    gen big4_matched=0 if big4==1
    replace big4_matched=1 if big4==1 & _weight!=.
    tabstat lnassets, by(big4_matched)
    drop big4_matched
	
    // With common support:
    psmatch2 big4 lnassets aturn curr lev roa salesgr, n(1) common logit noreplace outc(lnauditfees)	
    sum _weight
    sum big4 if big4==0 & _weight==.
    tabstat _pscore if _weight!=., by(big4)

    // With common support and caliper:
    psmatch2 big4 lnassets aturn curr lev roa salesgr, n(1) common caliper(0.01) logit noreplace outc(lnauditfees)	
    tabstat _pscore if _weight!=., by(big4)
    reg lnauditfees big4 if _weight!=.
    reg lnauditfees big4 if _weight!=., cluster(gvkey)
    
    // Doubly-robust:
    reg lnauditfee big4 lnassets aturn curr lev roa salesgr if _weight!=., cluster(gvkey)
	
    // With replacement:
    psmatch2 big4 lnassets aturn curr lev roa salesgr, n(1) common caliper(0.01) logit outc(lnauditfees)	
    tabstat _pscore [aw=_weight], by(big4)

	sum _weight if big4==1, d
    sum _weight if big4==0, d
    sum _weight if big4==0 & _weight<=2
    
    tabstat lnauditfees [aw=_weight], by(big4)
    reg lnauditfees big4 [aw=_weight]
    reg lnauditfees big4 [aw=_weight], r
    reg lnauditfees big4 [aw=_weight], cluster(gvkey)
   
    // Doubly-robust:
    reg lnauditfee big4 lnassets aturn curr lev roa salesgr [aw=_weight], cluster(gvkey)
    
    // Same results when expanding the sample first:
    preserve
    expand _weight
    reg lnauditfee big4 lnassets aturn curr lev roa salesgr if _weight!=., cluster(gvkey)
    restore
    
