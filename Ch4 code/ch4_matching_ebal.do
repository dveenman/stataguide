global path "C:\home\dv\PROJECTS\STATA"	

// First moment:
	use "$path\InFiles\data_auditfees.dta", clear
	ebalance big4 lnassets aturn curr lev roa salesgr, targets(1)
    
	reg lnauditfee big4 [aw=_webal], cluster(gvkey)
	reg lnauditfee big4 lnassets aturn curr lev roa salesgr [aw=_webal], cluster(gvkey)
	reg lnauditfee big4 lnassets aturn curr lev roa salesgr [aw=_webal]
	
    tabstat _webal, by(big4)
    sum _webal if big4==0, d

    // Comparison with PSM:
    psmatch2 big4 lnassets aturn curr lev roa salesgr, n(1) common caliper(0.01) logit outc(lnauditfees)	
    
    sum _webal _weight
    sum _webal _weight if big4==0    
    pwcorr _webal _weight if big4==0
    replace _weight=0 if _weight==.
    pwcorr _webal _weight if big4==0
    
// Higher moments:
	ren _webal _webal1
	ebalance big4 lnassets aturn curr lev roa salesgr, targets(2)
	reg lnauditfee big4 lnassets aturn curr lev roa salesgr [aw=_webal], cluster(gvkey)
    
	ren _webal _webal2
	ebalance big4 lnassets aturn curr lev roa salesgr, targets(3)
	reg lnauditfee big4 lnassets aturn curr lev roa salesgr [aw=_webal], cluster(gvkey)
    sum _webal if big4==0, d
    ren _webal _webal3
	
	spearman _webal* _weight
	spearman _webal* _weight if big4==0
	
	