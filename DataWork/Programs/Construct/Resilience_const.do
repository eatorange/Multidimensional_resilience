
	/*****************************************************************
	PROJECT: 		Multidimensional Development Resilience
					
	TITLE:			Resilience_const
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Dec 6, 2022, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	hhid round (Household ID-survey wave)

	DESCRIPTION: 	Clean data and construct multidimensional resilience measures
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Additional cleaning from the cleaned data
					2 - Construct resilience measures
					X - Save and Exit
					
	INPUTS: 		* PSNP pre-cleaned data
					${data_analysis}/PSNP_social_protection_and_resilience_analysisdata.dta ,	clear
										
	OUTPUTS: 		* PSNP data with multidimensional resilience measures							
					${data_analysis}/PSNP_resilience_const.dta

	NOTE:			*
	******************************************************************/

	/****************************************************************
		SECTION 0: Preamble			 									
	****************************************************************/		 
		
	/* 0.1 - Environment setup */
	
	* Clear all stored values in memory from previous projects
	clear			all
	cap	log			close

	* Set version number
	version			16

	* Set basic memory limits
	set maxvar 		32767
	set matsize		11000

	* Set default options
	set more		off
	pause			on
	set varabbrev	off
	
	* Filename and log
	loc	name_do	Resilience_const
	
	

	/****************************************************************
		SECTION 2: Construct univariate and multivariate measures
	****************************************************************/		
	
	*	Generate univariate resilience measures
	*local	gen_resil	1

		use	"${dtInt}/PSNP_resilience_cleaned.dta", clear
		sort	hhid	year
		
		*	(2024-4-9) We limit households with non-missing outcome values, as John suggested
		*	This limitation will make all resilience measures non-missing as well.
		keep	if	!mi(lnrexpaeu_peryear)	&	!mi(HDDS)	&	!mi(tlu)
		summ	lnrexpaeu_peryear	HDDS	TLU_IHS
		
		*	Define programs that generate resilience measures under Normal and Gamma distribution
		*	Note: Some dependent variables will NOT use this program, as their outcome names will be different to make consistent with older codes (that are NOT written by Min)
				
		*summ	 share_foodexp_allexp pdcals fs_months, d
		
			*	Normal distribution
			cap	program	drop	resil_normal
			program	resil_normal
				args	depvar	depvarname	threshold	//	Outcome variable, name of outcome variable, and thresholds.
				
				*	Step 0: Observe outcome variable distribution
				summ	`depvar',d
				hist	`depvar'
				kdensity	`depvar'
			
				cap	drop	`depvarname'_sample_normal
				cap	drop	mean_`depvarname'_normal
				cap	drop	e_`depvarname'_normal
				cap	drop	e_`depvarname'_normal_sq
				cap	drop	e_`depvarname'_normal_sd
				cap	drop	var_`depvarname'_normal
				cap	drop	sd_`depvarname'_normal
				cap	drop	thresh_`depvarname'_normal
				cap	drop	prob_below_`depvarname'
				cap	drop	 `depvarname'_resil_normal
				cap	drop	 `depvarname'_resil_normal_scale
				
				
				*	Step 1: Conditional mean
					*	(2025-03-03) Exclude PSNP vars (program vars) and district-FE (done in "globals.do") from construction
				reg	`depvar'	cl.`depvar'##cl.`depvar'	${resil_RHS},	cluster(village_num)
				est	sto	m1_`depvarname'_normal
				
				
				gen	`depvarname'_sample_normal=1	if	e(sample)
				predict	double	mean_`depvarname'_normal	if	`depvarname'_sample_normal==1,	xb
				predict	double	e_`depvarname'_normal		if	`depvarname'_sample_normal==1,	residuals
						
				gen	e_`depvarname'_normal_sq	=	(e_`depvarname'_normal)^2
				gen	e_`depvarname'_normal_sd	=	abs(e_`depvarname'_normal)
				
				
				*	Step 2: Conditional variance
				reg	e_`depvarname'_normal_sq	cl.`depvar'##cl.`depvar'	${resil_RHS} 	if	`depvarname'_sample_normal==1,	cluster(village_num)
				
				est	store	m2_`depvarname'_normal
				predict	var_`depvarname'_normal	if	`depvarname'_sample_normal==1, xb
				*predict	vare_`depvarname'_normal, residuals	//	(2025-6-6) Added to compute Moran's I in variance residual
				gen		sd_`depvarname'_normal	=	sqrt(abs(var_`depvarname'_normal))	//	Take square root of absolute value, since predicted value can be negative which does not have square root.
				
				
				*	Step 3: Construct the resilience measure
				gen thresh_`depvarname'_normal=(`threshold'-mean_`depvarname'_normal)/sd_`depvarname'_normal	// Let 2 as threshold
				gen prob_below_`depvarname'=normal(thresh_`depvarname'_normal)
				gen `depvarname'_resil_normal		=	1-prob_below_`depvarname'
				gen	`depvarname'_resil_normal_scale	=	`depvarname'_resil_normal	*	100
				
				lab	var	`depvarname'_resil_normal		"`depvarname' Resilience (normal)"
				lab	var	`depvarname'_resil_normal_scale	"`depvarname' Resilience (normal scaled)"
				
				reg	`depvarname'_resil_normal	cl.`depvar'##cl.`depvar'	${resil_RHS},	cluster(village_num)
				est	store	m3_`depvarname'_normal
				
				summ	mean_`depvarname'_normal	var_`depvarname'_normal	thresh_`depvarname'_normal	prob_below_`depvarname'	`depvarname'_resil_normal	`depvarname'_resil_normal_scale	
				
				
			end
			
			*	Gamma distribution
			cap	program	drop	resil_gamma
			program	resil_gamma
				args	depvar	depvarname	threshold	//	Outcome variable, name of outcome variable, and thresholds.
				
				*	Step 1: generate conditional mean
				glm	`depvar'	cl.`depvar'##cl.`depvar'	${resil_RHS},	cluster(village_num)	family(gamma)

				gen	`depvarname'_sample_gamma	=	1	if	e(sample)
				predict	double	mean_`depvarname'_gamma	if	`depvarname'_sample_gamma==1
				predict	double	e_`depvarname'_gamma	if	`depvarname'_sample_gamma==1,r
				gen	e_`depvarname'_gamma_sq	=	(e_`depvarname'_gamma)^2
				gen	e_`depvarname'_gamma_sd	=	abs(e_`depvarname'_gamma)
				
				eststo	m1_`depvarname'_gamma:	margins, dydx(*)	post
				
				*	Step 2: generate conditional variance
				reg	e_`depvarname'_gamma_sq	cl.`depvar'##cl.`depvar'	${resil_RHS} 	if	`depvarname'_sample_gamma==1,	cluster(village_num)
				*glm	e_`depvarname'_gamma_sq	cl.`depvar'##cl.`depvar' ${resil_RHS} if	`depvarname'_sample_gamma==1,	cluster(village_num) family(gamma)
				
				est	store	m2_`depvarname'_gamma
				predict	var_`depvarname'_gamma	if	`depvarname'_sample_gamma==1
				*predict	vare_`depvarname'_gamma, residuals	//	(2025-6-6) Added to compute Moran's I in variance residual
				gen		var_`depvarname'_gamma_abs	=	abs(var_`depvarname'_gamma)	//	absolute value of variance, since predicted value can be negative which shouldn't be the case for variance
				
				*	Step 3: Construct the resilience measure
				gen alpha1_`depvarname'_gamma	= (mean_`depvarname'_gamma)^2 / var_`depvarname'_gamma_abs	//	shape parameter of Gamma (alpha)
				gen beta1_`depvarname'_gamma	= var_`depvarname'_gamma_abs / mean_`depvarname'_gamma	//	scale parameter of Gamma (beta)

				gen `depvarname'_resil_gamma	= gammaptail(alpha1_`depvarname'_gamma, `threshold'/beta1_`depvarname'_gamma)	//	2 is the external threshold.
				gen	`depvarname'_resil_gamma_scale	=	`depvarname'_resil_gamma*100
				
				lab	var	`depvarname'_resil_gamma			"`depvarname' Resilience (gamma)"
				lab	var	`depvarname'_resil_gamma_scale	"`depvarname' Resilience (gamma scaled)"
				
				reg	`depvarname'_resil_gamma	cl.`depvar'##cl.`depvar'	${resil_RHS},	cluster(village_num)
				est	store	m3_`depvarname'_gamma
				
				summ	mean_`depvarname'_gamma	var_`depvarname'_gamma_abs	alpha1_`depvarname'_gamma	beta1_`depvarname'_gamma	`depvarname'_resil_gamma	`depvarname'_resil_gamma_scale

			end
			
			*	Inverse Gaussian distribution
			cap	program	drop	resil_igaussian
			program	resil_igaussian
				args	depvar	depvarname	threshold	//	Outcome variable, name of outcome variable, and thresholds.
			
				*	Step 1: Conditional mean
				*glm	`depvar'	l.`depvar'	${demovars}	${econvars}	${rainfallvar}	${programvars}	${FE},	cluster(village_num) family(gamma)
				glm		`depvar'	cl.`depvar'##cl.`depvar'${resil_RHS},	cluster(village_num) family(igaussian)
					
				gen	`depvarname'_sample_igaussian	=	1	if	e(sample)
				predict	mean_`depvarname'_igaussian	if	`depvarname'_sample_igaussian	=	1
				predict	e_`depvarname'_igaussian	if	`depvarname'_sample_igaussian	=	1,r
				gen	e_`depvarname'_igaussian_sq	=	(e_`depvarname'_igaussian)^2
				gen	e_`depvarname'_igaussian_sd	=	abs(e_`depvarname'_igaussian)
				
				eststo	m1_`depvarname'_igaussian:	margins, dydx(*)	post
							
				*	Step 2: generate conditional variance
				loc	depvar	lnrexpaeu_peryear	
				reg		e_`depvarname'_igaussian_sq	cl.`depvar'##cl.`depvar'	${resil_RHS}	if	`depvarname'_sample_igaussian==1,	cluster(village_num)
				
				est	store	m2_`depvarname'_igaussian
				predict	var_`depvarname'_igaussian	if	`depvarname'_sample_igaussian	=	1
				*predict	vare_`depvarname'_igaussian, residuals	//	(2025-6-6) Added to compute Moran's I in variance residual
				gen		var_`depvarname'_igaussian_abs	=	abs(var_`depvarname'_igaussian)	//	absolute value of variance, since predicted value can be negative which shouldn't be the case for variance
				
				*	Step 3: Construct the resilience measure
				gen mu_`depvarname'_igaussian		= mean_`depvarname'_igaussian	//	mean parameter of igaussian
				gen lambda_`depvarname'_igaussian	= (mu_`depvarname'_igaussian)^3 / var_`depvarname'_igaussian_abs	//	shape parameter of igaussian (lambda). Variance is mu^3 / lambda, thus lambda = mu^3/variance

				
				gen `depvarname'_resil_igaussian			= 	igaussiantail(mu_`depvarname'_igaussian,lambda_`depvarname'_igaussian,poverty_line)
				gen	`depvarname'_resil_igaussian_scale	=	`depvarname'_resil_igaussian*100
							
				lab	var	`depvarname'_resil_igaussian			"All Expenditure Resilience (igaussian)"
				lab	var	`depvarname'_resil_igaussian_scale	"All Expenditure Resilience (igaussian scaled)"
				
				*reg	`depvarname'_resil_igaussian l.`depvar'	${demovars}	${econvars}	${rainfallvar}	${programvars}	${FE},	cluster(village_num)	//	a modified version with linearity in lagged outcome
				reg		`depvarname'_resil_igaussian cl.`depvar'##cl.`depvar'	${resil_RHS} /* ${programvars}	${demovars}	${econvars}	${rainfallvar}	${FE} */,	cluster(village_num)	//	a modified version with non-linearity in lagged outcome
				
				estimate store m3_`depvarname'_igaussian
			
			end
			

			
			*	Construct measures with the program above
				{
				*	Overall expenditure (Table 4)
					resil_normal	lnrexpaeu_peryear	allexp	poverty_line	//	Normal
					resil_gamma		lnrexpaeu_peryear	allexp	poverty_line	//	Gamma
					//resil_igaussian	lnrexpaeu_peryear	allexp	poverty_line	//	Inverse Gaussian
			
					
				*	Output
				esttab	m1_allexp_normal /*m1_allexp_gamma	m1_allexp_igaussian*/	m2_allexp_normal	/*m2_allexp_gamma	m2_allexp_igaussian*/	m3_allexp_normal	/*m3_allexp_gamma	m3_allexp_igaussian*/	///
						using "${Output}/Allexp_resil_const.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop(/* *woreda_id* */ ?.year) 	///
						title(Regression of consumption expenditure, variance and resilience on household characteristics) ///
						mtitles("Log (consumption per adult)" "Variance" "Resilience") ///
						replace
						
				esttab	m1_allexp_normal /*m1_allexp_gamma	m1_allexp_igaussian*/	m2_allexp_normal	/*m2_allexp_gamma	m2_allexp_igaussian*/	m3_allexp_normal	/*m3_allexp_gamma	m3_allexp_igaussian*/	///
						using "${Output}/Allexp_resil_const.tex", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop(/* *woreda_id* */ ?.year) 	///
						title(Regression of consumption expenditure, variance and resilience on household characteristics) ///
						mtitles("Log (consumption per adult)" "Variance" "Resilience") ///
						replace
				
				*	Construct a dummy determining above or below threshold.
				*	For now, let 0.5 as benchmark threshold for resilience. We can update it later.
					loc	var	allexp_nonresil
					cap	drop	`var'
					gen	`var'=.
					replace	`var'=0	if	!mi(allexp_resil_normal)	&	inrange(allexp_resil_normal,0.5,1.0)
					replace	`var'=1	if	!mi(allexp_resil_normal)	&	inrange(allexp_resil_normal,0,0.5)
					lab	var	`var'	"HH is all exp non-resilient"
					
					loc	var	allexp_resil
					cap	drop	`var'
					clonevar	`var'	=	allexp_nonresil
					recode	`var'	(0=1)	(1=0)
					lab	var	`var'	"HH is all exp resilient"
					
				*	Generate dummy variable whether resilience status changed
					loc	var	allexpresil_change
					cap	drop	`var'
					gen		`var'=.
					replace	`var'=0	if	!mi(allexp_resil_normal)	&	!mi(l.allexp_resil_normal)
					replace	`var'=1	if	(allexp_nonresil==0	&	l.allexp_nonresil==1) | (allexp_nonresil==1	&	l.allexp_nonresil==0)
					lab	var	`var'	"=1	if overall exp resilience changed"
				}
				
				
				
				*	Food expenditure
				{
					resil_normal	lnrfdxpmaeu_peryear	foodexp	poverty_line_food
					resil_gamma		lnrfdxpmaeu_peryear	foodexp	poverty_line_food
					
							
				*	Output
				esttab	m1_foodexp_normal /*m1_foodexp_gamma*/	m2_foodexp_normal	/*m2_foodexp_gamma*/	m3_foodexp_normal	/*m3_foodexp_gamma	*/	///
						using "${Output}/Foodexp_resil_const.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop(/* *woreda_id* */ ?.year) 	///
						title(PSNP transfers and households' resilience: using overall consumption and national poverty line) ///
						mtitles("Log (consumption per adult)" "Variance of log(consumption per adult)" "Resilience") ///
						replace
						
				esttab	m1_allexp_normal /*m1_allexp_gamma	m1_allexp_igaussian*/	m2_allexp_normal	/*m2_allexp_gamma	m2_allexp_igaussian*/	m3_allexp_normal	/*m3_allexp_gamma	m3_allexp_igaussian*/	///
						using "${Output}/Foodexp_resil_const.tex", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop(/* *woreda_id* */ ?.year) 	///
						title(PSNP transfers and households' resilience: using food consumption and national food poverty line) ///
						mtitles("Log (food consumption per adult)" "Variance of log(food consumption per adult)" "Resilience") ///
						replace
					
				}
				
				
				*	HDDS
				{
					resil_normal	HDDS	HDDS	5	//	Normal
					resil_gamma		HDDS	HDDS	5	//	Gamma
					*resil_igaussian	HDDS	HDDDS	5	//	Inverse Gaussian
				

							
				*	Output
				esttab	m1_HDDS_normal /*m1_HDDS_gamma*/	m2_HDDS_normal	/*m2_HDDS_gamma*/	m3_HDDS_normal	/*m3_HDDS_gamma	*/	///
						using "${Output}/HDDS_resil_const.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop(/* *woreda_id* */ ?.year) 	///
						title(Regression of HDDS, variance and resilience on household characteristics) ///
						mtitles("HDDS" "Variance" "Resilience") ///
						replace
						
				esttab	m1_HDDS_normal /*m1_HDDS_gamma*/	m2_HDDS_normal	/*m2_HDDS_gamma*/	m3_HDDS_normal	/*m3_HDDS_gamma	*/	///
						using "${Output}/HDDS_resil_const.tex", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop(/* *woreda_id* */ ?.year) 	///
						title(Regression of HDDS, variance and resilience on household characteristics) ///
						mtitles("HDDS" "Variance" "Resilience") ///
						replace
				
				}
				
		
				
				*	TLU
				{
					
					resil_normal	tlu	TLU	2	//	Normal
					resil_gamma		tlu	TLU	2	//	Gamma
					

					*	Output
					esttab	m1_TLU_normal /*m1_TLU_gamma*/	m2_TLU_normal	/*m2_TLU_gamma*/	m3_TLU_normal	/*m3_TLU_gamma	*/	///
							using "${Output}/TLU_resil_const.csv", ///
							cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop(/* *woreda_id* */ ?.year) 	///
							title(PSNP transfers and households' resilience: using Tropical Livestock Index) ///
							mtitles("TLU" "Variance of TLU" "Resilience") ///
							replace
						
					esttab	m1_TLU_normal /*m1_TLU_gamma*/	m2_TLU_normal	/*m2_TLU_gamma*/	m3_TLU_normal	/*m3_TLU_gamma	*/	///
							using "${Output}/TLU_resil_const.tex", ///
							cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop(/* *woreda_id* */ ?.year) 	///
							title(PSNP transfers and households' resilience: using Tropical Livestock Index) ///
							mtitles("TLU" "Variance of TLU" "Resilience") ///
							replace
					
					
					*	TLU (inverse hyperbolic transformation)
					resil_normal	TLU_IHS	TLU_IHS	TLU_IHS_threshold
					resil_gamma		TLU_IHS	TLU_IHS	TLU_IHS_threshold
					*resil_igaussian	TLU_IHS	TLU_IHS	TLU_IHS_threshold	//	Inverse Gaussian
					
						*	Output
						esttab	m1_TLU_IHS_normal /*m1_TLU_IHS_gamma*/	m2_TLU_IHS_normal	/*m2_TLU_IHS_gamma*/	m3_TLU_IHS_normal	/*m3_TLU_IHS_gamma	*/	///
							using "${Output}/TLU_IHS_resil_const.csv", ///
							cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop(/* *woreda_id* */ ?.year) 	///
							title(Regression of TLU (IHS), variance and resilience on household characteristics) ///
							mtitles("TLU (IHS)" "Variance" "Resilience") ///
							replace
							
						*	Output
						esttab	m1_TLU_IHS_normal /*m1_TLU_IHS_gamma*/	m2_TLU_IHS_normal	/*m2_TLU_IHS_gamma*/	m3_TLU_IHS_normal	/*m3_TLU_IHS_gamma	*/	///
							using "${Output}/TLU_IHS_resil_const.tex", ///
							cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop(/* *woreda_id* */ ?.year) 	///
							title(Regression of TLU (IHS), variance and resilience on household characteristics) ///
							mtitles("TLU (IHS)" "Variance" "Resilience") ///
							replace
				
				}
		
				
				*	Combine step (1) and (2) results across (1) consumption expenditure (2) HDDS (3) TLU (IHS) (Appendix Table 2 of Feb 2023 draft)
				esttab	m1_allexp_normal	m2_allexp_normal	///
						m1_HDDS_normal		m2_HDDS_normal			///
						m1_TLU_IHS_normal	m2_TLU_IHS_normal		///
						using "${Output}/Final/TableA3_Resil_const_all.csv", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop(*woreda_id* ?.year) 	order(L.* cL.*)	///	
						title(Regression of welfare indicator, conditional variance and resilience on household characteristics) ///
						mtitles("Welfare outcome" "Cond.var" "Welfare outcome" "Cond.var" "Welfare outcome" "Cond.var") ///
						replace
						
				esttab	m1_allexp_normal	m2_allexp_normal	///
						m1_HDDS_normal		m2_HDDS_normal			///
						m1_TLU_IHS_normal	m2_TLU_IHS_normal		///
						using "${Output}/Final/TableA3_Resil_const_all.tex", ///
						cells(b(star fmt(a3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	drop( *woreda_id*  ?.year) 	order(L.* cL.*)	///
						title(Regression of welfare indicator, conditional variance and resilience on household characteristics) ///
						mtitles("Welfare outcome" "Cond.var" "Resilience" "Welfare outcome" "Cond.var" "Resilience" "Welfare outcome" "Cond.var" "Resilience") ///
						replace
				
				
				
				
			*	Construct bivariate normal
			*	"binormal(z1,z2,rho)" function constructs binormal cdf. We use it to construct bivariate resilience measure
			
				*	First, get correlations among "predicted outcome measures"
				**** Important: (2023-2-12) Chris told that the multivariate measures should be based upon "predicted" values, not "realized" vlaues.
				pwcorr		mean_allexp_normal 	mean_foodexp_normal mean_HDDS_normal 	mean_TLU_normal mean_TLU_IHS_normal /* mean_Oxen_normal */, sig star(0.05) // predicted outcome values
				* pwcorr	lnrexpaeu_peryear	lnrfdxpmaeu_peryear	HDDS				tlu				TLU_IHS				No_Oxen, sig star(0.05) // realized outcome values
				mat	pearson_outcome_corr_coef	=	r(C)
				mat	pearson_outcome_corr_sig	=	r(sig)
				
								
				mat	list	pearson_outcome_corr_coef
				*mat	list	pearson_resil_corr_coef
				
				*	Retrieve correlation coefficient to construct bivariate normal cdf later.
				scalar	corr_allexp_foodexp		=	pearson_outcome_corr_coef[2,1]
				scalar	corr_allexp_HDDS		=	pearson_outcome_corr_coef[3,1]
				scalar	corr_allexp_TLU			=	pearson_outcome_corr_coef[4,1]
				scalar	corr_allexp_TLU_IHS		=	pearson_outcome_corr_coef[5,1]
				scalar	corr_foodexp_HDDS		=	pearson_outcome_corr_coef[3,2]
				scalar	corr_foodexp_TLU		=	pearson_outcome_corr_coef[4,2]
				scalar	corr_foodexp_TLU_IHS	=	pearson_outcome_corr_coef[5,2]
				scalar	corr_HDDS_TLU			=	pearson_outcome_corr_coef[4,3]
				scalar	corr_HDDS_TLU_IHS		=	pearson_outcome_corr_coef[5,3]
				

				*	Bivariate normal cdf using outcome correlation
				*	(2023-11-20) As noted earlier, use correlations from "predicted" values.
				loc	var	jcdf_ae_fe	
				cap	drop	`var'
 				*corr	lnrexpaeu_peryear	lnrfdxpmaeu_peryear
 				*gen `var'	=	binormal(thresh_allexp_normal,thresh_foodexp_normal,r(rho))
				gen `var'	=	binormal(thresh_allexp_normal,thresh_foodexp_normal,corr_allexp_foodexp)
				lab	var	`var'	"Joint CDF (all exp and food exp)"
				
				loc	var	jcdf_ae_HDDS	
				cap	drop	`var'
				*corr	lnrexpaeu_peryear	HDDS
				*gen `var'	=	binormal(thresh_allexp_normal,thresh_HDDS_normal,r(rho))
				gen `var'	=	binormal(thresh_allexp_normal,thresh_HDDS_normal,corr_allexp_HDDS)
				lab	var	`var'	"Joint CDF (all exp and HDDS)"
				
				loc	var	jcdf_ae_TLU_IHS
				cap	drop	`var'
				*corr	lnrexpaeu_peryear	TLU_IHS
				*gen `var'	=	binormal(thresh_allexp_normal,thresh_TLU_IHS_normal,r(rho))
				gen `var'	=	binormal(thresh_allexp_normal,thresh_TLU_IHS_normal,corr_allexp_TLU_IHS)
				lab	var	`var'	"Joint CDF (all exp and TLU(IHS))"
				
				loc	var	jcdf_fe_HDDS	
				cap	drop	`var'
				*corr	lnrfdxpmaeu_peryear	HDDS
				*gen `var'	=	binormal(thresh_foodexp_normal,thresh_HDDS_normal,r(rho))
				gen `var'	=	binormal(thresh_foodexp_normal,thresh_HDDS_normal,corr_foodexp_HDDS)
				lab	var	`var'	"Joint CDF (food exp and HDDS)"
				
				loc	var	jcdf_fe_TLU
				cap	drop	`var'
				*corr	HDDS	tlu
				*gen `var'	=	binormal(thresh_HDDS_normal,thresh_TLU_normal,r(rho))
				gen `var'	=	binormal(thresh_HDDS_normal,thresh_TLU_normal,corr_HDDS_TLU)
				lab	var	`var'	"Joint CDF (food exp and TLU)"
				
				loc	var	jcdf_fe_TLU_IHS
				cap	drop	`var'
				*corr	lnrfdxpmaeu_peryear	TLU_IHS
				*gen `var'	=	binormal(thresh_foodexp_normal,thresh_TLU_IHS_normal,r(rho))
				gen `var'	=	binormal(thresh_foodexp_normal,thresh_TLU_IHS_normal,corr_foodexp_TLU_IHS)
				lab	var	`var'	"Joint CDF (food exp and TLU(IHS))"
				
				loc	var	jcdf_HDDS_TLU_IHS
				cap	drop	`var'
				*corr	HDDS	TLU_IHS
				*gen `var'	=	binormal(thresh_HDDS_normal,thresh_TLU_IHS_normal,r(rho))
				gen `var'	=	binormal(thresh_HDDS_normal,thresh_TLU_IHS_normal,corr_HDDS_TLU_IHS)
				lab	var	`var'	"Joint CDF (HDDS and TLU(IHS))"
								
									
				
				*	Trivariate normal CDF
				*	Requires "mvnormal()" which can be run only in Mata
				*	(2023-2-12) Also, make usre to use "predicted" outcome, not "realized" outcome.
				
					*	(all exp, food exp and TLU(IHS)) 	  - outcome correlation
					pwcorr	mean_allexp_normal mean_foodexp_normal mean_TLU_IHS_normal	//	correlation matrix of three "predicted" outcomes
					*pwcorr	lnrexpaeu_peryear	lnrfdxpmaeu_peryear	TLU_IHS	//	correlation matrix of three "realized" outcomes (wrong)
					mat corrmat	=	r(C)
					putmata	thresh_allexp_normal thresh_foodexp_normal thresh_TLU_IHS_normal, replace
					
					mata
					
						U = (thresh_allexp_normal, thresh_foodexp_normal, thresh_TLU_IHS_normal)
						W= st_matrix("corrmat")
						W
						R	=	vech(W)'
						R
						jcdf_ae_fe_TLU_IHS	=	mvnormal(U, R)	//	Trivariate normal cdf
						
					end
					
					*	Import Mata matrix back to main data
					getmata	jcdf_ae_fe_TLU_IHS, replace
				
				
									
					
					*	(all exp, HDDS  and TLU(IHS)) 	  - outcome correlation
					pwcorr	mean_allexp_normal mean_HDDS_normal mean_TLU_IHS_normal	//	correlation matrix of three "predicted" outcomes
					*pwcorr	lnrexpaeu_peryear	HDDS	TLU_IHS	//	correlation matrix of three "realized" outcomes (wrong)
					mat corrmat	=	r(C)
					putmata	thresh_allexp_normal thresh_HDDS_normal thresh_TLU_IHS_normal, replace
					
					mata
					
						U = (thresh_allexp_normal, thresh_HDDS_normal, thresh_TLU_IHS_normal)
						W= st_matrix("corrmat")
						W
						R	=	vech(W)'
						R
						jcdf_ae_HDDS_TLU_IHS	=	mvnormal(U, R)	//	Trivariate normal cdf
						
					end
					
					*	Import Mata matrix back to main data
					getmata	jcdf_ae_HDDS_TLU_IHS, replace
						
		
		*	Compute conditional variance residual
		*	I can't do this inside "Multidim_resil_const.do" as it causes an error while computing mata, thus I do this after mata
		gen	vare_allexp_normal	=	e_allexp_normal_sq-var_allexp_normal
		gen	vare_HDDS_normal	=	e_HDDS_normal_sq-var_HDDS_normal
		gen	vare_TLU_IHS_normal	=	e_TLU_IHS_normal_sq	-	var_TLU_IHS_normal
		
		lab	var	vare_allexp_normal 	"Conditional variance residual (CE)"
		lab	var	vare_HDDS_normal 	"Conditional variance residual (HDDS)"
		lab	var	vare_TLU_IHS_normal	"Conditional variance residual (TLU_IHS)"
		
		*	Construct multivariate resilience measure
		
			*	Intersection measure (both thresholds should be satisfied) - outcome correlation
			*	Bivariate: F(x1>x1_bar, x2>x2_bar) = 1 - F(x1<x1_bar) - F(x2<x2_bar) + F(x1<x1_bar,x2<x2_bar)
			*	Trivariate: F(x1>x_bar, x2>x2_bar, x3>x3_bar) = 1 - F(x1<x1_bar) - F(x2<x2_bar) - F(x3<x3_bar) + F(x1<x1_bar, x2<x2_bar) + F(x1<x1_bar, x3<x3_bar) + F(x2<x2_bar, x3<x3_bar) - F(x1<x1_bar, x2<x2_bar, x3<x3_bar) (Double-check!)
			
				*	All exp and food exp
				loc	var	resil_int_ae_fe
				cap	drop	`var'
				gen	`var'	=	1	-	prob_below_allexp	-	prob_below_foodexp	+	jcdf_ae_fe
				lab	var	`var'		"Intersection resilience (all exp and food exp)"
				
				*	All exp and HDDS
				loc	var	resil_int_ae_HDDS
				cap	drop	`var'
				gen	`var'	=	1	-	prob_below_allexp	-	prob_below_HDDS	+	jcdf_ae_HDDS
				lab	var	`var'		"Intersection resilience (all exp and HDDS)"
				
				*	All exp and tlu(IHS)
				loc	var	resil_int_ae_TLU_IHS
				cap	drop	`var'
				gen	`var'	=	1	-	prob_below_allexp	-	prob_below_TLU_IHS	+	jcdf_ae_TLU_IHS
				lab	var	`var'		"Intersection resilience (all exp and TLU(IHS))"
				
				*	Food exp and HDDS
				loc	var	resil_int_fe_HDDS
				cap	drop	`var'
				gen	`var'	=	1	-	prob_below_foodexp	-	prob_below_HDDS	+	jcdf_fe_HDDS
				lab	var	`var'		"Intersection resilience (food exp and HDDS)"
				
				*	Food exp and tlu(IHS)
				loc	var	resil_int_fe_TLU_IHS
				cap	drop	`var'
				gen	`var'	=	1	-	prob_below_foodexp	-	prob_below_TLU_IHS	+	jcdf_fe_TLU_IHS
				lab	var	`var'		"Intersection resilience (food exp and TLU(IHS))"
				
			
				*	HDDS and TLU (IHS)
				loc	var	resil_int_HDDS_TLU_IHS
				cap	drop	`var'
				gen	`var'	=	1	-	prob_below_HDDS	-	prob_below_TLU_IHS	+	jcdf_HDDS_TLU_IHS
				lab	var	`var'		"Intersection resilience (HDDS and TLU(IHS))"
		
				
				*	All exp, food exp and TLU(IHS) (trivariate)
				loc	var	resil_int_ae_fe_TLU_IHS
				cap	drop	`var'
				gen	`var'	=	1	-	prob_below_allexp	-	prob_below_foodexp	-	prob_below_TLU_IHS	///
									+	jcdf_ae_fe	+	jcdf_ae_TLU_IHS	+	jcdf_fe_TLU_IHS	///
									-	jcdf_ae_fe_TLU_IHS
				lab	var	`var'	"Intersection resilience (all exp \& food exp and TLU(IHS))"
				
				*	All exp, HDDS and TLU(IHS) (trivariate)
				loc	var	resil_int_ae_HDDS_TLU_IHS
				cap	drop	`var'
				gen	`var'	=	1	-	prob_below_allexp	-	prob_below_HDDS	-	prob_below_TLU_IHS	///
									+	jcdf_ae_HDDS	+	jcdf_ae_TLU_IHS	+	jcdf_HDDS_TLU_IHS	///
									-	jcdf_ae_HDDS_TLU_IHS
				lab	var	`var'	"Intersection resilience (all exp \& HDDS and TLU(IHS))"
				
				
			*	Union measure (at least one measure should be satisfied) - outcome correlation
			*	Bivariate: F(x1>x1_bar, x2>x2_bar) = 1 - F(x1<x1_bar,x2<x2_bar)
			*	Trivariate: F(x1>x_bar, x2>x2_bar, x3>x3_bar) = 1 -  - F(x1<x1_bar, x2<x2_bar, x3<x3_bar) (Double-check!)
			
				*	All exp and food exp
				loc	var	resil_uni_ae_fe
				cap	drop	`var'
				gen	`var'	=	1	-	jcdf_ae_fe
				lab	var	`var'		"Union resilience (all exp and food exp)"
				
				*	All exp and HDDS
				loc	var	resil_uni_ae_HDDS
				cap	drop	`var'
				gen	`var'	=	1	-	jcdf_ae_HDDS
				lab	var	`var'		"Union resilience (all exp and HDDS)"
				
				*	All exp and tlu(IHS)
				loc	var	resil_uni_ae_TLU_IHS
				cap	drop	`var'
				gen	`var'	=	1	-	jcdf_ae_TLU_IHS
				lab	var	`var'		"Union resilience (all exp and TLU(IHS))"
				
				*	Food exp and HDDS
				loc	var	resil_uni_fe_HDDS
				cap	drop	`var'
				gen	`var'	=	1	-	jcdf_fe_HDDS
				lab	var	`var'		"Union resilience (food exp and HDDS)"
				
				
				*	Food exp and tlu(IHS)
				loc	var	resil_uni_fe_TLU_IHS
				cap	drop	`var'
				gen	`var'	=	1	-	jcdf_fe_TLU_IHS
				lab	var	`var'		"Union resilience (food exp and TLU(IHS))"
				
				
				*	HDDS and TLU (IHS)
				loc	var	resil_uni_HDDS_TLU_IHS
				cap	drop	`var'
				gen	`var'	=	1	-	jcdf_HDDS_TLU_IHS
				lab	var	`var'		"Union resilience (HDDS and TLU(IHS))"
		
				
				*	All exp, food exp and TLU (trivariate)
				loc	var	resil_uni_ae_fe_TLU_IHS
				cap	drop	`var'
				gen	`var'	=	1	-	jcdf_ae_fe_TLU_IHS
				lab	var	`var'	"Union resilience (all exp \& food exp and TLU(IHS))"
				
				*	All exp, HDDS and TLU (trivariate)
				loc	var	resil_uni_ae_HDDS_TLU_IHS
				cap	drop	`var'
				gen	`var'	=	1	-	jcdf_ae_HDDS_TLU_IHS
				lab	var	`var'	"Union resilience (all exp \& HDDS and TLU(IHS))"
		
		
			*	Re-Label resilience measures 
			lab	var	allexp_resil_normal		"Resilience (Exp)"
			lab	var	HDDS_resil_normal		"Resilience (HDDS)"
			lab	var	TLU_IHS_resil_normal	"Resilience (TLU)"
			
			lab	var	resil_int_ae_HDDS	"Resilience (Exp \& HDDS - All)"
			lab	var	resil_uni_ae_HDDS	"Resilience (Exp \& HDDS - Any)"
			lab	var	resil_int_ae_TLU_IHS	"Resilience (Exp \& TLU - All)"
			lab	var	resil_uni_ae_TLU_IHS	"Resilience (Exp \& TLU - Any)"
			lab	var	resil_int_HDDS_TLU_IHS	"Resilience (HDDS \& TLU - All)"
			lab	var	resil_uni_HDDS_TLU_IHS	"Resilience (HDDS \& TLU - Any)"
			
			lab	var	resil_int_ae_HDDS_TLU_IHS	"Resilience (Exp \& HDDS \& TLU - All)"
			lab	var	resil_uni_ae_HDDS_TLU_IHS	"Resilience (Exp \& HDDS \& TLU - Any)"
		
		
		*	Construct additional resilience measures
		
			*	Average measure across different resiliences
			loc	var		resil_avg_ae_HDDS
			cap	drop	`var'
			gen	`var'	=	(allexp_resil_normal + HDDS_resil_normal)/2
			lab	var	`var'	"Average Resilience (Poverty \& Nutritional)"
			
			loc	var		resil_avg_ae_TLU_IHS
			cap	drop	`var'
			gen	`var'	=	(allexp_resil_normal + TLU_IHS_resil_normal)/2
			lab	var	`var'	"Average Resilience (Poverty \& Asset)"
			
			loc	var		resil_avg_HDDS_TLU_IHS
			cap	drop	`var'
			gen	`var'	=	(HDDS_resil_normal + TLU_IHS_resil_normal)/2
			lab	var	`var'	"Average Resilience (Nutritional \& Asset)"
			
			loc	var		resil_avg_ae_HDDS_TLU_IHS
			cap	drop	`var'
			gen	`var'	=	(allexp_resil_normal + HDDS_resil_normal + TLU_IHS_resil_normal)/3	
			lab	var	`var'	"Average Resilience (Poverty \& Nutritional \& Asset)"
			
			*	Alkire-Foster Multidimentional measure
				*	(Reference: https://ophi.org.uk/research/multidimensional-poverty/how-to-apply-alkire-foster/)
			*	We use three univariate resilience measures to construct multidimensional resilience measures
			*	We use 0.5 as a benchmark cut-off for each measure
				
				summ allexp_resil_normal HDDS_resil_normal TLU_IHS_resil_normal
				
				*	Construct binary indicators whether HH is resilient or not per each univariate resilient measure
				foreach	var	in allexp HDDS TLU_IHS	{
					
					cap	drop	HH_resilient_`var'
					gen		HH_resilient_`var'=0	if	!mi(`var'_resil_normal)	&	`var'_resil_normal<0.5
					replace	HH_resilient_`var'=1	if	!mi(`var'_resil_normal)	&	`var'_resil_normal>=0.5
					lab	var	HH_resilient_`var'	"HH is resilient (`var')"
					
				}
				
				*	Number of non-resilience per HH
				loc	var	num_nonresil
				cap	drop	`var'
				egen	`var'	=	anycount(HH_resilient_allexp	HH_resilient_HDDS	HH_resilient_TLU_IHS), values(0)
				replace	`var'=.	if	inlist(.,HH_resilient_allexp,HH_resilient_HDDS,HH_resilient_TLU_IHS)	//	replace with missing if any indicator is misisng
				lab	var	`var'	"Number of non-resilient measures"
				
					*	Generate dummies for the intensity of non-resilience measures (used to construct the adjusted headcount ratio)
					forval	k=1/3	{
					    
						cap	drop	nonresil_inten_`k'
						loc	j=`k'-1
						gen		nonresil_inten_`k'=0	if	!mi(num_nonresil)	&	inrange(num_nonresil,0,`j')
						replace	nonresil_inten_`k'=1	if	!mi(num_nonresil)	&	inrange(num_nonresil,`k',3)
						lab	var	nonresil_inten_`k'	"Non-resilience intensity: `k'"
					}

					
							
			
			*	define study sample				
			*	(2022-12-7) I am not using these indicators. This is something I can check with Kibrom
			*	For now(2022-7-21), I define study sample as households with all resilience measures available (constructed)
			*	Note: This study sample construction is not perfect, as it include some observation that do not have actual outcome observed but its expected value predicted (ex. tlu)
			*	We can modify this code later if we want to fix it.
			*	Note: Number of oxens have about 3,500 missing obs. In order not to drop them, I include those missing obs in the sample
			*	(2022-11-6) I use households with 3 non-missing resiliences (all exp, dietary score and TLU)
			
			/*
			
				*	Outcome missing status
				loc	var	outcome_missing
				cap	drop	`var'
				egen	`var'	=	rowmiss(lnrexpaeu_peryear	HDDS	TLU_IHS)
				
				*	Resilience missing status
				loc	var	resil_missing
				cap	drop	`var'
				egen	`var'	=	rowmiss(allexp_resil_normal HDDS_resil_normal TLU_IHS_resil_normal)
				
				*di	"resile measusres are ${resil_measures}"
				
			loc	var		study_sample
			cap	drop	`var'
			gen			`var'=0
			
			*	(1) Outcome non-missing in 2006, or resilience non-missing from 2008 to 2014
			replace		`var'=1 if (outcome_missing==0 &  round==2006) | (resil_missing==0 & inrange(round,2008,2014)) // First include observations satisfying t
			
			*	(2) From (1), exclude missing outcomes from 2008 to 2014
			replace		`var'=0 if outcome_missing!=0 & inrange(round,2008,2014)
	
			lab	var		`var'	"=1 if study sample (outcome and resilience non-missing)"
			
			
			*/
			
		*	Drop households whose resilience measures are missing across all periods (ex. surveyed in round 2 and 5 only)
		*	(2024-6-29) 604 households fall under this category.
		foreach	type	in	allexp	HDDS	TLU_IHS	{
			
			cap	drop	num_resil_`type'
			bys	hhid:	egen	num_resil_`type'	=	count(`type'_resil_normal)
			
			drop	if	num_resil_`type'==0
			drop	num_resil_`type'
		}
		

		*	Save
		compress	
		save	"${dtInt}/PSNP_resilience_const.dta", replace
			
		
