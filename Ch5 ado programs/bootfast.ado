*! version 1.0 20230808 DVeenman

program define bootfast, eclass sortpreserve
    syntax varlist(numeric) [in] [if], cluster(varlist) nboot(integer)
    
    tokenize `varlist'
    marksample touse
    markout `touse' `varlist'
    local depv `"`1'"'
    // Ensure dv is not a factor variable:
    _fv_check_depvar `depv'
    macro shift 1
    local indepv "`*'"
	
    // Ensure only one variable included in cluster():
    local nc: word count `cluster'
    if (`nc'!=1){
        di as text "ERROR: You can define only one cluster dimension"
        exit
    }

	// Create temporary variable and local lists for variables to be read in Mata:
    tempvar clusterid
    egen `clusterid'=group(`cluster') if `touse'
    local y "`depv'"
    local xlist "`indepv'"
    local xlistname "`indepv' _cons"
    local cvar "`clusterid'"

    // Mata's panelsetup requires sorting on the cluster variable:
    sort `clusterid' 
    
	// Run Mata program (defined at the bottom):
	di ""
    mata: _bootfast(`nboot')
    matrix colnames b =`xlistname'
    matrix colnames V =`xlistname'
    matrix rownames V =`xlistname'    

	// Apply finite-sample correction following Cameron/Miller (2015, p. 12)
	local k=rowsof(V) 
	local N=e_N
    local c=(nc/(nc-1))*((`N'-1)/(`N'-`k'))	
	matrix V=`c'*V
	
	// Export and display results:
    ereturn clear
    ereturn post b V
    ereturn scalar df_r=e_df_r
    ereturn scalar N=e_N
    di " "
    di as text "Regression with cluster-robust bootstrapped standard errors" 
    di as text "Number of bootstrap resamples: " as result `nboot'
    di as text "Cluster dimension: " as result "`cluster'"
    di as text "Number of clusters: " as result nc
    di " "
    di _column(53) as text "Number of obs.: " %10.0fc as result e(N)
    ereturn display
end

mata:
    mata clear
	
    void _bootfast(real scalar B){		
        // Declare variables:
        real vector y, cvar, b, coef, bsample_c, Xyb, V
        real matrix X, XXinv, info, xg, yg, beta, XXb, XXbinv
        real scalar n, nc, dfr, k, cluster
        pointer(real matrix) rowvector xxp, xyp
        
        // Load the data:
        y=st_data(., st_local("y"), st_local("touse"))
        X=st_data(., tokens(st_local("xlist")), st_local("touse"))
        cvar=st_data(., st_local("cvar"), st_local("touse"))
        
        // Obtain coefficients and info for the full sample:
        n=rows(X)
        X=(X,J(n,1,1))
        XXinv=invsym(cross(X,X))
        b=XXinv*cross(X,y)
        coef=b'
        info=panelsetup(cvar, 1)
        nc=rows(info)        
        dfr=nc-1
        k=cols(X)
        
        // Obtain the relevant information from the clusters and store in lower-dimensional matrices;
        // These lower-dimensional matrices are stored using pointers in pointer-vectors xxp and xyp:
        xxp=J(1, nc, NULL)
        xyp=J(1, nc, NULL)        
        for(i=1; i<=nc; i++) {
            xg=panelsubmatrix(X,i,info)
            xxp[i]=&(cross(xg,xg))
            yg=panelsubmatrix(y,i,info)
            xyp[i]=&(cross(xg,yg))
        }
        
        // Obtain and store coefficients for each bootstrap sample:
        beta=J(0,k,0)
        bcounter=0
        bcounter2=0
        pct=0
        for(b=1; b<=B; b++) {
            bsample_c=mm_sample(nc,nc)
            XXb=J(k,k,0)
            Xyb=J(k,1,0)
            for(i=1; i<=nc; i++) {
                cluster=bsample_c[i]
                XXb=XXb+*xxp[cluster]
                Xyb=Xyb+*xyp[cluster]            
            }            
            XXbinv=invsym(XXb)
            beta=(beta \ cross(XXbinv,Xyb)')
			
            // Display status of bootstrap:
            _bootcounter(b, B, bcounter, bcounter2, pct)			
        }
        
        // Store variance of each coefficient and push info back to Stata matrices:
        V=variance(beta)
        st_matrix("b", coef)
        st_matrix("V", V)
        st_numscalar("e_N", n)
        st_numscalar("e_df_r", dfr)
        st_numscalar("nc", nc)		
    }
	
	void _bootcounter(real scalar b, B, bcounter, bcounter2, pct){
        if (b==1) {
            printf("   Status of bootstrap procedure: 0%%")
            displayflush()                
        }
        bcounter++
        bcounter2++
        if (floor(5*bcounter/B)==1) {
            pct=pct+20
            printf("%f", pct)
            printf("%%")
            displayflush()
            bcounter=0
            bcounter2=0
        }
        else{
            if (b==B) {
                printf("100%%")
                displayflush()                
            }    
            if (floor(25*bcounter2/B)==1) {
                printf(".")
                displayflush()                                    
                bcounter2=0
            }
        }
        if (b==B) {
            printf("\n")
            displayflush()                
        }    
    }	
end
    