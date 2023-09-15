global path "C:\home\dv\PROJECTS\STATA"

	**************************************************************************
	* Get information on databases and tables on WRDS server
	**************************************************************************
	odbc load, exec("select distinct frname from wrds_lib_internal.friendly_schema_mapping;") dsn("wrds-pgdata-64") clear
	list	
	
	odbc load, exec("select distinct table_name from information_schema.columns where table_schema='comp' order by table_name;") dsn("wrds-pgdata-64") clear
	list

	odbc load, exec("select distinct table_name from information_schema.columns where table_schema='ibes' order by table_name;") dsn("wrds-pgdata-64") clear
	list
	
	**************************************************************************
	* Get Compustat accounting data
	**************************************************************************
	odbc load, exec("select * from comp.company") noquote dsn("wrds-pgdata-64") clear
	save "$path\InFiles\company.dta"	

	odbc load, exec("select at from comp.funda where fyear>='2001' and fyear<='2020'") noquote dsn("wrds-pgdata-64") clear
	save "$path\InFiles\compdata.dta"	
	
	global query ///
		select gvkey, fyear, fic, datadate, fyr, at, ib, xrd, ///
		sale, oancf, indfmt, consol, popsrc, datafmt, sich, /// 
		capx, ceq, xsga, intan, ppent, ppegt ///
		from comp.g_funda ///
		where datadate>'20201231' ///
		and datadate<'20230101' ///
		and at>0

	odbc load, exec("$query") noquote dsn("wrds-pgdata-64") clear
	sum fyear at
	save "$path\InFiles\g_funda.dta"	

	**************************************************************************
	* Get Compustat Global stock price data per country
	**************************************************************************
	use "$path\InFiles\g_funda.dta", clear
	egen count=count(fyear), by(fic fyear)
	sum count, d
	drop if count<100
	
	levelsof fic, clean
	local countrylist=r(levels)

	local j=1
	foreach cntry in `countrylist'{
		di `j' ": `cntry'" 
		global query ///
			select gvkey, iid, datadate, prccd ///
				from comp_global_daily.g_secd ///
			where datadate>='20220101' ///
			and datadate<='20220131' ///
			and fic in ('`cntry'')

		odbc load, exec("$query") noquote dsn("wrds-pgdata-64") clear
		save "$path\InFiles\g_secd_`cntry'.dta", replace	
		local `j++'
	}

	**************************************************************************
	* Append the separate files (optional)
	**************************************************************************
	use "$path\InFiles\g_funda.dta", clear
	egen count=count(fyear), by(fic fyear)
	sum count, d
	drop if count<100
	
	levelsof fic, clean
	local countrylist=r(levels)

	local j=1
	foreach cntry in `countrylist'{
		di `j' ": `cntry'" 
		if (`j'==1) {
			use "$path\InFiles\g_secd_`cntry'.dta", clear
		}
		else {
			append using "$path\InFiles\g_secd_`cntry'.dta"
		}	
		local `j++'
	}
	
	sum prccd
	
	**************************************************************************
	* Compress example:
	**************************************************************************
	global query ///
	select * ///
	from comp.company
	
	odbc load, exec("$query") noquote dsn("wrds-pgdata-64") clear

	memory
	/*
	
	*/
	compress
	memory
	
	
	global query ///
	select * ///
	from comp_global_daily.g_secd ///
	where datadate>='20220101' ///
	and datadate<='20220131' 
	
	odbc load, exec("$query") noquote dsn("wrds-pgdata-64") clear

	memory
	/*
	
	*/
	compress
	memory
	
	