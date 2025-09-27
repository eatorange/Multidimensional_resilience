
	
*	Shapley decomposition

	

	*do "${Programs}/Globals.do" 
	use	"${dtInt}/PSNP_resilience_const.dta", clear
	
	
	global	resil_measures	allexp_resil_normal HDDS_resil_normal TLU_IHS_resil_normal	///
							resil_uni_ae_HDDS resil_uni_ae_TLU_IHS resil_uni_HDDS_TLU_IHS	resil_uni_ae_HDDS_TLU_IHS	///
							resil_int_ae_HDDS resil_int_ae_TLU_IHS resil_int_HDDS_TLU_IHS	resil_int_ae_HDDS_TLU_IHS 

	cap	drop	year_?
	tab	year,	gen(year_)
	global	year_101214	year_2	year_3	year_4

	*	Shapley decomposition of resilience measures
		
		*	Since Shapley2 does not support factor variables, need to create dummies for each woreda
		cap	drop	woreda_dummy*
		tab	woreda_id, gen(woreda_dummy)
		
		cap	drop	village_dummy*
		tab	village_num, gen(village_dummy)
		
		ds	woreda_dummy2-woreda_dummy60
		local	woreda_dummies	`r(varlist)'
		
		ds	village_dummy*
		local	village_dummies	`r(varlist)'
		
		*	Turn on only one
		global	location_vars	${rainfallvar}	`village_dummies'
		
		*	(2025-5-7) We use four groups; (i) Head chracteristics (ii) Househol chracteristics (iii) Community and location-based (iv) Time-based
		global	shapley_groups	lnhead_age	 lnhead_age_sq malehead	headnoed	maritals_m occupation_non_farm	,	///	//	Head-based
								hhsize	electricity	IHS_dist_nt	IHS_landaeu	IHS_lvstk_real	IHS_vprodeq_realaeu,	///	//	Household-based
								${location_vars}	//	location-based
								
		
		
	*	Univariate 
	foreach	depvar	in	 allexp 	 HDDS  TLU_IHS  	{
		
		*	Pooled
		reg	`depvar'_resil_normal	${demovars} ${econvars}		${location_vars}	 	${year_101214},	cluster(village_num) 
		shapley2, stat(r2) force group(${shapley_groups}, ${year_101214}) 
		
		mat	`depvar'_shapley_pool	=	e(shapley_rel)'

		
		*	By year
		forval	year=2/2	{	//	Use 2008 only
		
			qui	reg	`depvar'_resil_normal	${demovars} ${econvars}	${location_vars}	if	year==`year',	cluster(village_num) 
			shapley2, stat(r2) force group(${shapley_groups}) 
			
			mat	`depvar'_shapley_`year'	=	e(shapley_rel)'
			mat	`depvar'_shapley_`year'	=	`depvar'_shapley_`year', J(1,1,.) //	Add a blank column for FE, to make it conformable with pooled matrix
		
			
		}	//	year
		
	}	//	depvar
	
	
	*	Combine matrices
	foreach	year	in	pool	2	{
		
		mat	uni_shapley_`year'	=	allexp_shapley_`year' \	HDDS_shapley_`year' \	TLU_IHS_shapley_`year'
		
		mat	rownames	uni_shapley_`year'	=	"Expenditure"	"Dietary"	"Livestock"
		mat	colnames	uni_shapley_`year'	=	"Head characteristics"	"Household characteristics"	"Community characteristics" "Year FE"
													
	}
	

	putexcel	set "${Output}/shapley_decomposition", sheet(univariate) replace
	putexcel	A1	=	"Shapley decomposition - univariate resilience"
	
	putexcel	A3	=	"Pooled (2008-2014)"
	putexcel	A4	=	matrix(uni_shapley_pool), names overwritefmt nformat(percent_d2)
	
	putexcel	H3	=	"2008 only"
	putexcel	I4	=	matrix(uni_shapley_2), names overwritefmt nformat(percent_d2)
		
									
	esttab	matrix(uni_shapley_pool, fmt(%12.2f))	using	"${Output}/shapley_uni_pool.tex",  cells(mean(fmt(%12.2f)) sd(par)) replace


	*	Multidimensional resilience
	foreach	type	in	avg	 uni	int 	{
	
		foreach	depvar	in	ae_HDDS	ae_TLU_IHS	 HDDS_TLU_IHS	ae_HDDS_TLU_IHS 	{
			
		*	Pooled
		reg	resil_`type'_`depvar'	${demovars} ${econvars}	${location_vars}		${year_101214},	cluster(village_num) 
		shapley2, stat(r2) force group(${shapley_groups}, ${year_101214}) 
		
		mat	`type'_`depvar'_shap_pool	=	/*e(shapley),*/	e(shapley_rel)'
			
			
		*	By year
		forval	year=2/2	{	//	Use 2008 only
		
			qui	reg	resil_`type'_`depvar'	${demovars} ${econvars}	${location_vars}	if	year==`year',	cluster(village_num) 
			shapley2, stat(r2) force group(${shapley_groups}) 
			
			mat	`type'_`depvar'_shap_`year'	=	/*e(shapley),*/	e(shapley_rel)'
			mat	`type'_`depvar'_shap_`year'	=	`type'_`depvar'_shap_`year', J(1,1,.) //	Add a blank column for FE, to make it conformable with pooled matrix
		
			
			}	//	year
			
		}	//	depvar
	
	}	//	type
	
		*	Combine matrices
		
		foreach	year	in	pool	2	{
			
			foreach	type	in	avg	uni	int	{
			
			mat	`type'_shap_`year'	=	`type'_ae_HDDS_shap_`year' \	`type'_ae_TLU_IHS_shap_`year' \	`type'_HDDS_TLU_IHS_shap_`year' \	`type'_ae_HDDS_TLU_IHS_shap_`year'	
			
			mat	rownames	`type'_shap_`year'	=	"Expenditure \& Dietary"	"Expenditure \& Livestok"	"Dietary \& Livestock" "Exp \& Diet \& Livestock"
			mat	colnames	`type'_shap_`year'	=	"Head characteristics"	"Household characteristics"	"Community characteristics" "Year FE"
			
		}	//	type
	
	}	//	year
	
	
	putexcel	set "${Output}/shapley_decomposition", sheet(multivariate) modify
	putexcel	A1	=	"Shapley decomposition - multivariate resilience"

	
	putexcel	A3	=	"Average Resilience - Pooled (2008-2014)"
	putexcel	A4	=	matrix(avg_shap_pool), names overwritefmt nformat(percent_d2)
	
	putexcel	H3	=	"Average Resilience - 2008 only"
	putexcel	I4	=	matrix(avg_shap_2), names overwritefmt nformat(percent_d2)
	
	putexcel	A20	=	"Union Resilience - Pooled (2008-2014)"
	putexcel	A21	=	matrix(uni_shap_pool), names overwritefmt nformat(percent_d2)
	
	putexcel	H20	=	"Union Resilience - 2008 only"
	putexcel	I21	=	matrix(uni_shap_2), names overwritefmt nformat(percent_d2)
	
	putexcel	A37	=	"Intersection Resilience - Pooled (2008-2014)"
	putexcel	A38	=	matrix(int_shap_pool), names overwritefmt nformat(percent_d2)
	
	putexcel	H37	=	"Intersection Resilience - 2008 only"
	putexcel	I38	=	matrix(int_shap_2), names overwritefmt nformat(percent_d2)

	
	*	Combine matrices to make a graph
	
	mat	shapley_all	=	uni_shapley_pool	\	avg_shap_pool	\	uni_shap_pool	\	int_shap_pool
	
	*	Figure x
	preserve
		
		clear
		mat	list	shapley_all
		svmat	shapley_all
		
		gen	num=_n
		
		gen		resil_type=1 	in	1/3
		replace	resil_type=2	in	4/7
		replace	resil_type=3	in	8/11
		replace	resil_type=4	in	12/15
		
		lab	define	resil_type	1	"Univariate"	2	"Multivariate-Average"	3	"Multivariate-Union"	4	"Multivariate-Intersection", replace
		lab	val	resil_type	resil_type
		
		gen		resil_name=_n	in	1/3
		replace	resil_name=4	if	inlist(num,4,8,12)
		replace	resil_name=5	if	inlist(num,5,9,13)
		replace	resil_name=6	if	inlist(num,6,10,14)
		replace	resil_name=7	if	inlist(num,7,11,15)
		
		lab	define	resil_name	1	"Expenditure"	2	"Dietary"	3	"Livestock"		///
								4	"Expenditure & Dietary"	5	"Expenditure & Livestok"	6	"Dietary & Livestock"	7 "Exp & Diet & Livestock", replace
		lab	val		resil_name	resil_name
		
		rename	(shapley_all1 shapley_all2 shapley_all3 shapley_all4)	(Head	Households	Location	Year)	
		
		graph hbar Head	Households	Location	Year, ///
			over(resil_name)	stack legend(pos(6) row(1))  blabel(bar, position(center) format(%14.2f))	///
			legend(label(1 "HH demographics")	label(2	"Household attributes")	label(3	"Location")	label(4	"Year"))	/*title(Variance Decomposition by Characteristics)	*/
		graph	export	"${Output}/Final/Figure8_shapley_decomposition_resil.png", as(png) replace
	
	restore
	
	
	
	*	Targeting
	use	"${dtInt}/PSNP_resilience_const.dta", clear
		

		*	We test it using two samples
			*	(1) All households with non-missing resilience 
			*	(2) Among (1), those who did NOT participate in PSNP

			*	Create PSNP status 2 years after
			*	This variable will capture PSNP status in 2010 of those in 2008
			cap	drop	f1_psnp	
			gen	f1_psnp	=	f1.psnp
			
			*	Generate sample indicators for (1) and (2)			
				*	(1)
				loc	var		target_sample_all
				cap	drop	`var'
				gen			`var'=0
				replace		`var'=1	if	allexp_sample_normal==1	&	!mi(f1.psnp)
				
				*	(2)
				loc	var		target_sample_nopsnp
				cap	drop	`var'
				gen			`var'=0
				replace		`var'=1	if	allexp_sample_normal==1	&	!mi(f1.psnp)	&	psnp==0
				
			*	Construct poverty indicator (will be used to compute poverty-based targeting)
			loc	var		allexp_below_PL
			cap	drop	`var'
			gen			`var'=-1*(allexp_above_PL-1)
			lab	var		`var'	"Household consumes below poverty line"
			
			
			
			*	Share of PSNP participants 2 years from base year
	
			foreach	year_base	in	2008	2010	2012	{
			
				
				loc	year_actual=`year_base'+2
			
			
				*	(1) All households with non-missing resilience in base year	
				tab		f1_psnp	if		target_sample_all==1	&	round==`year_base' ,	matcell(freq_psnp_`year_actual'_all)	
				scalar	tot_psnp_`year_actual'_all	=	freq_psnp_`year_actual'_all[1,1] + freq_psnp_`year_actual'_all[2,1]		//	# of households
				
				mat		freq_psnp_`year_actual'_all	=	freq_psnp_`year_actual'_all	/	tot_psnp_`year_actual'_all		//	% of households enrolled psnp in 2010
				scalar	pct_nonpsnp_`year_actual'_all	=	(freq_psnp_`year_actual'_all[2,1])*100		//	Save it as scalar
			
			
				*	(2) Among (1), those who did NOT participate in PSNP in 2008
				tab		f1_psnp	if		target_sample_nopsnp==1	&	round==`year_base', matcell(freq_psnp_`year_actual'_nopsnp)
				scalar	tot_psnp_`year_actual'_nopsnp	=	freq_psnp_`year_actual'_nopsnp[1,1] + freq_psnp_`year_actual'_nopsnp[2,1]	//	% of households enrolled psnp in 2010
			
				mat		freq_psnp_`year_actual'_nopsnp	=	freq_psnp_`year_actual'_nopsnp	/	tot_psnp_`year_actual'_nopsnp			
				scalar	pct_nonpsnp_`year_actual'_nopsnp	=	(freq_psnp_`year_actual'_nopsnp[2,1])*100	
			
			
		*	Determine PSNP status using outcome and resilience measures
			
			
			*	Outcome
			foreach	depvar	in	allexp	/* HDDS */	TLU_IHS	{
				
				foreach	type	in	all	nopsnp	{
				
					cap	drop	`depvar'_out_qtile_`type'_`year_base'	`depvar'_out_psnp_`type'_`year_base'
					xtile		`depvar'_out_qtile_`type'_`year_base'	=	${outcome_`depvar'} ///
						if round==`year_base' & target_sample_`type'==1, nquantiles(100)	// create 100 quantiles
					
					*	Categorize equal share of PSNP partipants as PSNP.
					*	CAUTION: DOESN'T WORK WELL WITH HDDS WHICH IS A DISCRETE VARIABLE
					cap	drop	`depvar'_out_psnp_`type'_`year_base'
					gen			`depvar'_out_psnp_`type'_`year_base'	=	0	///
						if	round==`year_base' & target_sample_`type'==1	&	inrange(`depvar'_out_qtile_`type'_`year_base',pct_nonpsnp_`year_actual'_`type',100)	//	Resilient (NOT targeted as psnp)
					replace		`depvar'_out_psnp_`type'_`year_base'	=	1	///
						if	round==`year_base' & target_sample_`type'==1	&	inrange(`depvar'_out_qtile_`type'_`year_base',1,pct_nonpsnp_`year_actual'_`type')	//	Not resilient (targeted as non-psnp)
					
				}	//	type
					
			}	//	depvar
			
			
			
			*	Univariate
			foreach	depvar	in	allexp	HDDS	TLU_IHS	{
			
				foreach	type	in	all	nopsnp	{
				
					cap	drop	`depvar'_resil_qtile_`type'_`year_base'		`depvar'_resil_psnp_`type'_`year_base'
					xtile		`depvar'_resil_qtile_`type'_`year_base'	=	`depvar'_resil_normal ///
						if round==`year_base' & target_sample_`type'==1, nquantiles(100)	// create 100 quantiles
					
					*	Categorize equal share of PSNP partipants as PSNP.
					cap	drop	`depvar'_resil_psnp_`type'_`year_base'
					gen			`depvar'_resil_psnp_`type'_`year_base'	=	0	///
						if	round==`year_base' & target_sample_`type'==1	&	inrange(`depvar'_resil_qtile_`type'_`year_base',pct_nonpsnp_`year_actual'_`type',100)	//	NOT targeted as PSNP
					replace		`depvar'_resil_psnp_`type'_`year_base'	=	1	///
						if	round==`year_base' & target_sample_`type'==1	&	inrange(`depvar'_resil_qtile_`type'_`year_base',1,pct_nonpsnp_`year_actual'_`type')		//	targeted as psnp
					
				}	//	type
			
			}	//	depvar
				
				
			
				
			*	Trivariate
			foreach	depvar	in	uni	int	{
				
				foreach	type	in	all	nopsnp	{
				
					cap	drop	`depvar'_resil_qtile_`type'_`year_base'	`depvar'_resil_psnp_`type'_`year_base'
					xtile		`depvar'_resil_qtile_`type'_`year_base'	=	resil_`depvar'_ae_HDDS_TLU_IHS ///
						if round==`year_base' & target_sample_`type'==1, nquantiles(100)	// create 100 quantiles
					
					*	Categorize equal share of PSNP partipants as PSNP.
					cap	drop	`depvar'_resil_psnp_`type'_`year_base'
					gen			`depvar'_resil_psnp_`type'_`year_base'	=	0	///
						if	round==`year_base' & target_sample_`type'==1	&	inrange(`depvar'_resil_qtile_`type'_`year_base',pct_nonpsnp_`year_actual'_`type',100)	//	NOT targeted as psnp
					replace		`depvar'_resil_psnp_`type'_`year_base'	=	1	///
						if	round==`year_base' & target_sample_`type'==1	&	inrange(`depvar'_resil_qtile_`type'_`year_base',1,pct_nonpsnp_`year_actual'_`type')	//	targeted as non-psnp
					
				}	//	type
			

			}	//	depvar
			
	
				
			*	Inclusion and exclusion error, based on acutal psnp status
			local	outvars		allexp	/* HDDS */	TLU_IHS
			local	psnpvars	allexp	 HDDS	TLU_IHS	uni	int	// pc1_uni pc1_all
			cap	mat	drop	psnp_matching_matrix
			
			mat	twobytwo_blank	=	J(2,2,.)
			mat	twobysix_blank	=	J(2,6,.)
			
			mat	rownames	twobytwo_blank	=	""	""
			mat	colnames	twobytwo_blank	=	""	""	
			mat	rownames	twobysix_blank	=	""	""
			mat	colnames	twobysix_blank	=	""	""	""	""	""	""
			
			cap	mat	drop	matching_all
			

	
			*	Poverty indicator 
			foreach	type	in	all	nopsnp	{
			
				tab	allexp_below_PL	f1_psnp	if	round==`year_base'	&	!mi(allexp_resil_psnp_`type'_`year_base'),	matcell(matpov_`type'_`year_base')
				mat			matpov_`type'_`year_base'	=	matpov_`type'_`year_base' / r(N)
				mat	list	matpov_`type'_`year_base'
						
				mat	rownames	matpov_`type'_`year_base'	=	"Non-poor"	"Poor"
				mat	colnames	matpov_`type'_`year_base'	=	"NOT participated in PSNP"	"Participated in PSNP" 
				
				*	Make 1x4 matrix for later plot.
				mat				matpov_`type'_`year_base'_r	=	matpov_`type'_`year_base'[1,1],	matpov_`type'_`year_base'[2,2], matpov_`type'_`year_base'[1,2],	matpov_`type'_`year_base'[2,1]
				mat	colnames	matpov_`type'_`year_base'_r	=	"Not-poor/non-PSNP" "Poor/PSNP"  "Not-poor/PSNP" "Poor/non-PSNP"
				
			}	//	type
			
			*	Append matrices across type
			mat	matpov_both_`year_base'		=	matpov_all_`year_base',	twobytwo_blank,	matpov_nopsnp_`year_base'
						

			*	Outcome vars
			foreach	var	of	loc	outvars	{
				
				foreach	type	in	all	 nopsnp 	{
					
					tab `var'_out_psnp_`type'_`year_base' f1_psnp, matcell(matout_`var'_`type'_`year_base')	
					mat			matout_`var'_`type'_`year_base'	=	matout_`var'_`type'_`year_base' / r(N)
					mat	list	matout_`var'_`type'_`year_base'
				
					mat	rownames	matout_`var'_`type'_`year_base'	=	"Resilent"	"Not-Resilient"
					mat	colnames	matout_`var'_`type'_`year_base'	=	"NOT participated in PSNP"	"Participated in PSNP" 
							
					*	Make 1x4 matrix for later plot.
					mat				matout_`var'_`type'_`year_base'_r	=	matout_`var'_`type'_`year_base'[1,1],	matout_`var'_`type'_`year_base'[2,2], matout_`var'_`type'_`year_base'[1,2],	matout_`var'_`type'_`year_base'[2,1]
					mat	colnames	matout_`var'_`type'_`year_base'_r	=	"Resilient/non-PSNP" "Not-resilient/PSNP"  "ResilientP/PSNP" "Not-resilient/non-PSNP"
					
				}	//	type
				
				*	Append matrices across type
				mat	matout_`var'_both_`year_base'		=	matout_`var'_all_`year_base',	twobytwo_blank,	matout_`var'_nopsnp_`year_base'
				
				if	"`var'"	==	"allexp"	{
					
					mat	matout_all_`year_base'		=	matout_`var'_both_`year_base'
					mat	matout_all_`year_base'_r	=	matout_`var'_all_`year_base'_r
				}	//	if
				else	{
					
					mat	matout_all_`year_base'		=	nullmat(matout_all_`year_base')	\	twobysix_blank	\	matout_`var'_both_`year_base'
					mat	matout_all_`year_base'_r	=	nullmat(matout_all_`year_base'_r)	\	matout_`var'_all_`year_base'_r
				}	//	else
				
			}	//	var
			
			
			*	Resilience vars
			foreach	var	of	loc	psnpvars	{
				
				foreach	type	in	all	 nopsnp 	{
					
					tab 		`var'_resil_psnp_`type'_`year_base' f1_psnp, matcell(matching_`var'_`type'_`year_base')
					mat			matching_`var'_`type'_`year_base'	=	matching_`var'_`type'_`year_base' / r(N)
					mat	list	matching_`var'_`type'_`year_base'
					
					mat	rownames	matching_`var'_`type'_`year_base'	=	"Resilent"	"Not-Resilient"
					mat	colnames	matching_`var'_`type'_`year_base'	=	"NOT participated in PSNP"	"Participated in PSNP" 
					
					*	Make 1x4 matrix for later plot.
					mat				matching_`var'_`type'_`year_base'_r	=	matching_`var'_`type'_`year_base'[1,1],	matching_`var'_`type'_`year_base'[2,2], matching_`var'_`type'_`year_base'[1,2],	matching_`var'_`type'_`year_base'[2,1]
					mat	colnames	matching_`var'_`type'_`year_base'_r	=	"Resilient/non-PSNP" "Not-resilient/PSNP"  "ResilientP/PSNP" "Not-resilient/non-PSNP"
				
				}	//	type
				
				*	Append matrices across type
				mat	matching_`var'_both_`year_base'		=	matching_`var'_all_`year_base',	twobytwo_blank,	matching_`var'_nopsnp_`year_base'
		
				if	"`var'"	==	"allexp"	{
					
					mat	matching_all_`year_base'	=	matching_`var'_both_`year_base'
					mat	matching_all_`year_base'_r	=	matching_`var'_all_`year_base'_r
				}
				else	{
					
					mat	matching_all_`year_base'	=	nullmat(matching_all_`year_base')	\	twobysix_blank	\	matching_`var'_both_`year_base'
					mat	matching_all_`year_base'_r	=	nullmat(matching_all_`year_base'_r)	\	matching_`var'_all_`year_base'_r
				}
				
	
			}	//	var
		
			*	Append poverty, outcome and resilience targeting result
			mat	mat_all_`year_base'		=	matpov_both_`year_base'	 \ 	twobysix_blank 	\	matout_all_`year_base' \	twobysix_blank \ matching_all_`year_base'
			mat	mat_all_`year_base'_r	=	matpov_all_`year_base'_r \ matout_all_`year_base'_r \	matching_all_`year_base'_r
			
			mat	rownames	mat_all_`year_base'_r	=	"log (consumption)" "TLU (IHS)" "Expenditure" "Dietary" "Livestock" "Trivariate (union)" "Trivariate (intersection)" // "PCA (univariate)" "PCA (all)"
			
	
			putexcel	set "${Output}/PSNP_targetting", sheet(target_`year_base'_`year_actual') modify
			putexcel	A1	=	"Matching by outcome and resilience measures (`year_base'_`year_actual')"
			putexcel	A5	=	"Poverty"
			putexcel	A9	=	"Consumption Expenditure"
			putexcel	A13	=	"TLU(IHS)"
			putexcel	A17	=	"CE"
			putexcel	A21	=	"Dietary"
			putexcel	A25	=	"Livestock"
			putexcel	A29	=	"Trivariate (Union)"
			putexcel	A33	=	"Trivariate (Intersection)"
			//putexcel	A37	=	"PCA score (univariate only, 1st component)"
			//putexcel	A41	=	"PCA score (uni \& multivariate, 1st component)"
			putexcel	C2	=	"All households in `year_base'"
			putexcel	G2	=	"All households who didn't participate in PSNP in `year_base'"
			
			putexcel	B4	=	matrix(mat_all_`year_base'), names overwritefmt nformat(percent_d2) //	nformat(number_d3)	
			
		}	//	year_base
		
			
		*	Figure 9 and 10
	preserve
		
		clear
		mat		mat_all_r	=	mat_all_2008_r \ mat_all_2010_r	\	mat_all_2012_r
		svmat	mat_all_r
		
		gen	num=_n
		
		gen		period=1 	in	1/8
		replace	period=2	in	9/16
		replace	period=3	in	17/24

		
		lab	define	period	1	"2008-2010"	2	"2010-2012"	3	"2012-2014", replace
		lab	val	period	period
		
		gen		resil_name=mod(_n,8)
		replace	resil_name=8	if	resil_name==0
	
		lab	define	resil_name	1	"Poverty"	2	"Consumption Expenditure"	3	"TLU"	4	"Univariate (Expenditure)"	5	"Univariate (Dietary)"	6	"Univariate (Livestock)"		///
								7	"Trivariate (union)"	8	"Trivariate (intersection)"	/*9	"PCA score (univariate)"	10 "PCA score (uni- and multi-)"*/, replace
		lab	val		resil_name	resil_name
			
			*	Drop poverty rate (as John suggested)
			drop	if	resil_name==1
		
		rename	(mat_all_r1 mat_all_r2 mat_all_r3 mat_all_r4)	(resil_nonPSNP	notresil_PSNP	resil_PSNP	notresil_nonPSNP)	
		
		*	Accuracy Rate
		egen	accuracy_rate	=	rowtotal(resil_nonPSNP	notresil_PSNP)
		
		*	Pooled
		graph	hbar resil_nonPSNP	notresil_PSNP	resil_PSNP	notresil_nonPSNP, ///
			over(resil_name)	stack legend(pos(6) row(2))  blabel(bar, position(center) format(%14.2f))	///
			bar(1, fcolor(blue) fintensity(50))	bar(2, fcolor(forest_green) fintensity(50)) bar(3, fcolor(yellow) fintensity(50)) bar(4, fcolor(red) fintensity(50)) ///
			legend(label(1 "Resilient/non-PSNP")	label(2	"Not-Resilient/PSNP")	label(3	"Resilient/PSNP")	label(4	"Not-Resilient/non-PSNP"))	/*title(Concordance between Resilience Measures and PSNP)*/	
		graph	export	"${Output}/Final/Figure9_concordance_resil_PSNP.png", as(png) replace
		graph	close
			
		*	By year (plot)
		twoway	(connected	accuracy_rate period	if	resil_name==2, lc(green) lp(solid) lwidth(medium)	msymbol(diamond) graphregion(fcolor(white)) legend(label(1 "Consumption Expenditure")))	///
				(connected	accuracy_rate period	if	resil_name==3, lc(black) lp(shortdash) lwidth(medium) msymbol(plus) graphregion(fcolor(white)) legend(label(2 "TLU")))	///
				(connected	accuracy_rate period	if	resil_name==5, lc(blue) lp(dash) lwidth(medium) msymbol(triangle) graphregion(fcolor(white)) legend(label(3 "Univariate (Dietary)")))	///
				(connected	accuracy_rate period	if	resil_name==6, lc(green) lp(dash_dot) lwidth(medium) msymbol(square) graphregion(fcolor(white)) legend(label(4 "Univariate (Livestock)")))	///
				(connected	accuracy_rate period	if	resil_name==7, lc(red) lp(dot) lwidth(medium) msymbol(X) graphregion(fcolor(white)) legend(label(5 "Trivariate (Union)") row(2) pos(6) size(small))),	///
				ytitle("Rate") xtitle("Period")	/*title(Concordance Rate by Period)*/	xlabel(1 "2008-2010" 2 "2010-2012" 3 "2012-2014", angle(0)) name(target_accuracy_by_period, replace)
		graph	export	"${Output}/Final/Figure10_Concordance_resil_PSNP_by_year.png", as(png) replace
		graph	close	
			
		
	
	restore	
		