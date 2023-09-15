global path "C:\home\dv\PROJECTS\STATA"

	clear all
	use "$path\InFiles\icc.dta", clear
	gen g=0.01
	gen icc=.
	gen returncode=.

	mata:
		st_view(p=., ., "p")
		st_view(bv0=., ., "bv0")
		st_view(bv1=., ., "bv1")
		st_view(bv2=., ., "bv2")
		st_view(eps1=., ., "eps1")
		st_view(eps2=., ., "eps2")
		st_view(eps3=., ., "eps3")
		st_view(g=., ., "g")
		n=rows(p)

		solutions=J(n,1,.)
		rcode=J(n,1,.)
		function myfunc(x, p_i, bv0_i, bv1_i, bv2_i, eps1_i, eps2_i, eps3_i, g_i){ ///
			return(-p_i+bv0_i+ ///
			(eps1_i-x*bv0_i)/(1+x)+ ///
			(eps2_i-x*bv1_i)/(1+x)^2+ ///
			(eps3_i-x*bv2_i)/(1+x)^3+ ///
			((eps3_i-x*bv2_i)*(1+g_i))/((x-g_i)*(1+x)^3))
		}

		for(i=1; i<=n; i++) {
			p_i=p[i]
			bv0_i=bv0[i]
			bv1_i=bv1[i]
			bv2_i=bv2[i]
			eps1_i=eps1[i]
			eps2_i=eps2[i]
			eps3_i=eps3[i]
			g_i=g[i]
			rc=mm_root(x=., &myfunc(), .01001, .5, 1e-9, 1000, p_i, bv0_i, bv1_i, bv2_i, eps1_i, eps2_i, eps3_i, g_i)
			solutions[i,1]=x
			rcode[i,1]=rc
		}
		st_store(., "icc", solutions[.,1])
		st_store(., "returncode", rcode[.,1])
	end

	sum icc, d

	tabstat icc, by(returncode) stats(N mean)