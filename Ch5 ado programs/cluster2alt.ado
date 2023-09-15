*! version 1.0 20230808 DVeenman

program define cluster2alt, eclass sortpreserve
    syntax varlist(numeric) [in] [if], cluster(varlist) 
    
    marksample touse
    markout `touse' `varlist'
	tokenize `varlist'
    local depv `"`1'"'
    // Ensure dv is not a factor variable:
    _fv_check_depvar `depv'
    macro shift 1
    local indepv "`*'"
	
    // Ensure exactly two variables included in cluster():
    local nc: word count `cluster'
    if (`nc'!=2){
        di as text "ERROR: cluster() should include two clustering dimensions"
        exit
    }
	local clusterdim1: word 1 of `cluster'
	local clusterdim2: word 2 of `cluster'
    if ("`clusterdim1'"=="`clusterdim2'"){
        di as text "ERROR: cluster() should include two unique clustering dimensions"
        exit
    }
	tempvar intersection
	qui egen `intersection'=group(`clusterdim1' `clusterdim2') if `touse'
	qui sum `intersection'
	local nclusterdim3=r(max)
	
	// Store results from estimation in first clustering dimension:
	qui reg `depv' `indepv' if `touse', cluster(`clusterdim1')
	scalar e_N=e(N)
	scalar e_r2=e(r2)
	scalar e_r2_a=e(r2_a)
	local nclusterdim1=e(N_clust)
    matrix b=e(b)
	matrix V1=e(V)

	// Store results from estimation in second clustering dimension:
	qui reg `depv' `indepv' if `touse', cluster(`clusterdim2')
	local nclusterdim2=e(N_clust)
	matrix V2=e(V)

	// Store results from estimation in intersection of clustering dimensions:
	qui reg `depv' `indepv' if `touse', cluster(`intersection')
	matrix V3=e(V)
	
	// Get the right degrees of freedom based on smallest clustering dimension:
	if (`nclusterdim1'<`nclusterdim2') {
		scalar e_df_r=`nclusterdim1'-1
	}
	else {
		scalar e_df_r=`nclusterdim2'-1		
	}
	
	// Compute finite-sample corrections for variance matrices:
	local N=e_N
	local k=rowsof(V1)
	local factor1=(`nclusterdim1'/(`nclusterdim1'-1))*((`N'-1)/(`N'-`k'))
	local factor2=(`nclusterdim2'/(`nclusterdim2'-1))*((`N'-1)/(`N'-`k'))
	local factor3=(`nclusterdim3'/(`nclusterdim3'-1))*((`N'-1)/(`N'-`k'))
	if `nclusterdim1'<`nclusterdim2'{
		local factormin=`factor1'
	}
	else{
		local factormin=`factor2'
	}
	
	// Unadjust variance matrices for finite-sample corrections:
	matrix V1=V1/`factor1'
	matrix V2=V2/`factor2'
	matrix V3=V3/`factor3'	

	// Create combined variance matrix with finite-sample correction based on smallest clustering dimension:
	matrix V=V1+V2-V3
	matrix V=`factormin'*V            
	
	// Export and display results:
	local indepvnames "`indepv' _cons"
	matrix colnames b =`indepvnames'
    matrix colnames V =`indepvnames'
    matrix rownames V =`indepvnames'
	ereturn clear
    ereturn post b V
    ereturn scalar N=e_N
	ereturn scalar r2=e_r2
	ereturn scalar r2_a=e_r2_a
    ereturn scalar df_r=e_df_r
	ereturn local cmd "cluster2alt"

    di as text "Linear regression with two-way cluster-robust standard errors" 
    di " "
    di _column(53) as text "Number of obs.: " %10.0fc as result e(N)
    di _column(53) as text "R-squared:         " %7.4f as result e(r2)
    di _column(53) as text "Adj. R-squared:    " %7.4f as result e(r2_a)
    di as text "Number of clusters in dimension " as result "`clusterdim1'" as text ": " as result "`nclusterdim1'"
    di as text "Number of clusters in dimension " as result "`clusterdim2'" as text ": " as result "`nclusterdim2'"
	di as text "Degrees of freedom: " as result e_df_r
    ereturn display
end

