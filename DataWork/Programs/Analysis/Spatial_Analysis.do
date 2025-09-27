*	Spatial correlation


	*	(i) Diagnose spatial correlation of Cisse and Barrett measure
		*	Reference:	Scognamillo, Antonio, Chun Song, and Adriana Ignaciuk. "No Man Is an Island: A Spatially Explicit Approach to Measure Development Resilience." World Development 171 (November 1, 2023): 106358. https://doi.org/10.1016/j.worlddev.2023.106358.


	*	Construct weighting matrix
	*	Reference: https://stats.oarc.ucla.edu/stata/faq/how-can-i-calculate-morans-i-in-stata/
	*	Since constructing weighting matrix on the entire smaple is too computatioanlly intensive to be done, we do MCS
	
		
	*	Gemerate weighting matrix each year where each woreda has 10 obs
	*	NOTE: NOT all rounds have 60 woreda available, so need to create matrix per round
	
	foreach	round	in	2008	2010	2012	2014	{
	
		use	"${dtInt}/PSNP_resilience_const.dta", clear	
		keep	if	!mi(allexp_resil_normal)
		keep	if	round==`round'
		keep	adm3_pcode	latitude	longitude
		duplicates	drop
		expand	10
		sort	adm3_pcode
		
		spatwmat, name(resilweights) xcoord(longitude) ycoord(latitude) band(0 11) standardize	// bin
		
			*	Save
		clear	
		svmat	resilweights
		save	"${dtInt}/Woreda_GPS_wmat_10obs_`round'.dta", replace
		
		
	}
	
	
	*	Simulate 20 times and test spatial correlation per each simulation.
	
		*	Define the simulation to be done
		set	seed	20250605
		cap	program	drop	spatialcuster
		program spatialcuster,	rclass
		
			args	allexpvar	HDDSvar	TLU_IHSvar	year	
			cap	drop	_all
			use	"${dtInt}/PSNP_resilience_const.dta", clear	
			keep	if	!mi(allexp_resil_normal)

			
			gen	rannum=rnormal()	//	Generate random number
			
			sort	adm3_pcode	round	rannum
			by		adm3_pcode	round:	gen	ID_within_woreda=_n
			
			keep	latitude	longitude	round	adm3_pcode	ID_within_woreda	rannum	`allexpvar'	`HDDSvar'	`TLU_IHSvar'
			keep	if	round==`year'
			keep	if	inrange(ID_within_woreda,1,10)
			drop	round adm3_pcode ID_within_woreda		rannum

			*spatwmat, name(resilweights) xcoord(longitude) ycoord(latitude) band(0 11) // bin
			spatwmat	using	"${dtInt}/Woreda_GPS_wmat_10obs_`year'.dta",	name(resilweights)
		
		
			spatgsa `allexpvar', weights(resilweights) moran
			return	scalar	moran_i_allexp	= r(Moran)[1,1]
			return	scalar	pval_allexp		= r(Moran)[1,5]
			
			spatgsa `HDDSvar', weights(resilweights) moran
			return	scalar	moran_i_HDDS	= r(Moran)[1,1]
			return	scalar	pval_HDDS		= r(Moran)[1,5]
			
			spatgsa `TLU_IHSvar', weights(resilweights) moran
			return	scalar	moran_i_TLU_IHS	= r(Moran)[1,1]
			return	scalar	pval_TLU_IHS	= r(Moran)[1,5]
			
			
		end
		
		
		*	Simulate 20 times
		*	CAUTION: TAKES LONG TIME
			
		*tempfile	simul_data
		*save		`simul_data'
		
		*	Set up argument (In case of variables)
			local	outcomes	${outcome_allexp}		${outcome_HDDS}	${outcome_TLU_IHS} // outcome variables (step 1)
			local	meanresid	e_allexp_normal	e_HDDS_normal	e_TLU_IHS_normal	//	Mean residual (step 2)
			local	varresid	vare_allexp_normal vare_HDDS_normal vare_TLU_IHS_normal	//	variance residual (step 3)
		
		
		foreach	round	in	2008	2010	2012	2014	{
			
			*local	round=2014	//	Set which round to test
			
			simulate 	moran_i_allexp=r(moran_i_allexp) pval_allexp=r(pval_allexp)	///		
						moran_i_HDDS=r(moran_i_HDDS) pval_HDDS=r(pval_HDDS)	///
						moran_i_TLU_IHS=r(moran_i_TLU_IHS) pval_TLU_IHS=r(pval_TLU_IHS), reps(20) nodots: spatialcuster `varresid'	`round'
			
			gen	round=`round'
			tempfile	result_`round'
			save		`result_`round''
			
			*use	`simul_data', clear
		}
		
		use		`result_2008', clear
		
		append	using	`result_2010'
		append	using	`result_2012'
		append	using	`result_2014'
		
		*	Replace	moran's I to absolute value
		gen	moran_i_allexp_abs	=	abs(moran_i_allexp)
		gen	moran_i_HDDS_abs	=	abs(moran_i_HDDS)
		gen	moran_i_TLU_IHS_abs	=	abs(moran_i_TLU_IHS)
		
		summ	*_abs	pval*
	
		*save	"${dtInt}/spatial_diagnosis_var_noFE.dta", replace
	
	
	


*	Generate lagged variable of outcome variables (needed to re-construct resilience from the same sample)
	use	"${dtInt}/PSNP_resilience_const.dta", clear

	
	gen	l_lnrexpaeu_peryear	=	l1.lnrexpaeu_peryear
	gen	l_HDDS	=	l1.HDDS
	gen	l_TLU_IHS	=	l1.TLU_IHS
	
	keep	if	!mi(allexp_resil_normal)
	
	*	To make coordinates to HH-level, I add a very small disturbance to geocoordinates
	set	seed	20250605
	gen small_GPS_error = rnormal() * 0.00001
	replace	longitude	=	longitude	+	small_GPS_error
	replace	latitude	=	latitude	-	small_GPS_error
	
	xtset hhid round, delta(2)
	bys	hhid:	gen	surveynum=_N
	keep	if	surveynum==4	//	keeping only balanced houseohlds.
	
	spbalance
	
	*cd	"E:\Dropbox\Multidimensional resilience\data_preparation\Climate\Shapefiles"
	spset	hhid,	coord(longitude latitude)  coordsys(latlong, kilometers)
			
	spmatrix create idistance W	if	round==2008, replace
	
	*	Re-construct resilience measures using (i) cross-sectional data with spregress (original method) (ii) panel data structure spxtregress
		
		
		*	We run 4 different models for each survey round
			*	We use the model with woreda fixed effect (same as resilience construction) as default model
		global	resil_RHS_noyFE	 ${demovars}	${econvars}	${rainfallvar}	${woreda_FE}	//		${communityvars}	// 	
		cap	drop	allexp
		cap	drop	l_allexp	
		clonevar	allexp		=	lnrexpaeu_peryear
		clonevar	l_allexp	=	l_lnrexpaeu_peryear
		
		cap	drop	thresh_allexp
		cap	drop	thresh_HDDS
		cap	drop	thresh_TLU_IHS
		gen			thresh_allexp	=	poverty_line
		gen			thresh_HDDS		=	5
		gen			thresh_TLU_IHS	=	TLU_IHS_threshold
			
			foreach	outcome	in	allexp	HDDS	TLU_IHS	{		
		
			cap	drop	mean_`outcome'_ols
			cap	drop	mean_`outcome'_sar
			cap	drop	`outcome'_resil_ols
			cap	drop	`outcome'_resil_sar
			
			gen		mean_`outcome'_ols=.
			gen		mean_`outcome'_sar=.
			gen		`outcome'_resil_ols=.
			gen		`outcome'_resil_sar=.
			
			
					
				foreach	round	in	2008	 2010	2012	2014 	{
							
		
					cap	drop	mean_`outcome'_*_`round'
					cap	drop	e_`outcome'_*_`round'
					cap	drop	e_`outcome'_*_`round'_sq
					cap	drop	temp_`round'
					cap	drop	var_`outcome'_*_`round'
					cap	drop	sd_`outcome'_*_`round'
					cap	drop	tr_`outcome'_*_`round'
					cap	drop	prob_below_`outcome'_*_`round'
					cap	drop	`outcome'_resil_*_`round'
				
					*	OLS, spatial autocorrelation unadjusted
						
						*	Conditional mean
						reg		`outcome'	c.l_`outcome'##c.l_`outcome'	${resil_RHS_noyFE} if	round==`round'
						predict	mean_`outcome'_ols_`round'	if	round==`round',	xb
						predict	e_`outcome'_ols_`round'		if	round==`round', resid
						gen		e_`outcome'_ols_`round'_sq	=	(e_`outcome'_ols_`round')^2	if	round==`round'
					
						replace	mean_`outcome'_ols	=	mean_`outcome'_ols_`round'	if	round==`round'
						
						*	Conditional variance
						reg		e_`outcome'_ols_`round'_sq	c.l_lnrexpaeu_peryear##c.l_lnrexpaeu_peryear	${resil_RHS_noyFE} if	round==`round'
						predict	var_`outcome'_ols_`round'	if	round==`round', xb
						gen		sd_`outcome'_ols_`round'	=	sqrt(abs(var_`outcome'_ols_`round'))	if	round==`round'	//	Take square root of absolute value, since predicted value can be negative which does not have square root.
					
						*	Resilience
						gen tr_`outcome'_ols_`round'=(thresh_`outcome'-mean_`outcome'_ols_`round')/sd_`outcome'_ols_`round'	if	round==`round'
						gen prob_below_`outcome'_ols_`round'=normal(tr_`outcome'_ols_`round')	if	round==`round'
						gen `outcome'_resil_ols_`round'	=	1-prob_below_`outcome'_ols_`round'	if	round==`round'
						
						replace	`outcome'_resil_ols	=	`outcome'_resil_ols_`round'	if	round==`round'
					
					*	SARAR
						
						*	Conditional mean
						spregress	`outcome'	c.l_`outcome'##c.l_`outcome'	${resil_RHS_noyFE}	if	round==`round', gs2sls dvarlag(W)
						predict	mean_`outcome'_sar_`round'	if	round==`round',	xb
						predict	e_`outcome'_sar_`round'		if	round==`round', resid
						gen		e_`outcome'_sar_`round'_sq	=	(e_`outcome'_sar_`round')^2	if	round==`round'
						
						replace	mean_`outcome'_sar	=	mean_`outcome'_sar_`round'	if	round==`round'
						
						*	Conditional variance
						reg		e_`outcome'_sar_`round'_sq	c.l_lnrexpaeu_peryear##c.l_lnrexpaeu_peryear	${resil_RHS_noyFE} if	round==`round'
						predict	var_`outcome'_sar_`round'	if	round==`round', xb
						gen		sd_`outcome'_sar_`round'	=	sqrt(abs(var_`outcome'_sar_`round'))	if	round==`round'	//	Take square root of absolute value, since predicted value can be negative which does not have square root.
					
						*	Resilience
						gen tr_`outcome'_sar_`round'=(thresh_`outcome'-mean_`outcome'_sar_`round')/sd_`outcome'_sar_`round'	if	round==`round'
						gen prob_below_`outcome'_sar_`round'=normal(tr_`outcome'_sar_`round')	if	round==`round'
						gen `outcome'_resil_sar_`round'	=	1-prob_below_`outcome'_sar_`round'	if	round==`round'
						
						replace	`outcome'_resil_sar	=	`outcome'_resil_sar_`round'	if	round==`round'
						
				}	//	round
				
			
			}	//	outcome
			
			*	Compute difference
			foreach	outcome	in	allexp	HDDS	TLU_IHS	{
				
				
				cap	drop	diff_m_`outcome'_ols_sar
				gen			diff_m_`outcome'_ols_sar	=	abs(mean_`outcome'_ols	-	mean_`outcome'_sar)
				summ		diff_m_`outcome'_ols_sar
				
				cap	drop	diff_r_`outcome'_ols_sar
				gen			diff_r_`outcome'_ols_sar	=	abs(`outcome'_resil_ols	-	`outcome'_resil_sar)
				summ		diff_r_`outcome'_ols_sar
				
			}
			
			*	Distribution in resilience between OLS and SARAR
			twoway	(kdensity allexp_resil_ols, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "OLS")))	///
					(kdensity allexp_resil_sar, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(pos(6) row(1) label(2 "SARAR"))), 	///
					ytitle("Density") xtitle("Probability")	title("Consumption Expenditure") name(allexp_resil_ols_SAR, replace)	
					
			twoway	(kdensity HDDS_resil_ols, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "OLS")))	///
					(kdensity HDDS_resil_sar, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(pos(6) row(1) label(2 "SARAR"))), 	///
					ytitle("Density") xtitle("Probability")	title("HDDS") name(HDDS_resil_ols_SAR, replace)	
					
			twoway	(kdensity TLU_IHS_resil_ols, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "OLS")))	///
					(kdensity TLU_IHS_resil_sar, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(pos(6) row(1) label(2 "SARAR"))), 	///
					ytitle("Density") xtitle("Probability")	title("TLU (IHS)") name(TLU_IHS_resil_ols_SAR, replace)	
				
			graph	combine	allexp_resil_ols_SAR	HDDS_resil_ols_SAR TLU_IHS_resil_ols_SAR, ///
						title(Distribution of Resilience Measures) ycommon	graphregion(fcolor(white))	
			graph	export	"${Output}/resil_dist_OLS_SAR.png", as(png) replace
			graph	close		
					
		