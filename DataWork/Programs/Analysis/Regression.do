
	/*****************************************************************
	PROJECT: 		Multidimensional Development Resilience
					
	TITLE:			Multidim_resil_analyses
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Dec 6, 2022, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	hhid round (Household ID-survey wave)

	DESCRIPTION: 	Construct dynamics measures
		
	ORGANIZATION:	Regression-based analysis
	
	INPUTS: 		* PSNP pre-cleaned data
					${data_analysis}/PSNP_resilience_const.dta ,	clear
										
	OUTPUTS: 		* Various outputs (need to write it later)

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
	loc	name_do	PSNP_resilience_analyses


	/****************************************************************
		SECTION 2: Regression analyses					
	****************************************************************/		 	
	
	use	"${dtInt}/PSNP_resilience_const.dta", clear
	
	
	*	Regression of conditinoal mean and variance of houseold characteristics
	**	They are already done and exported while constructing univariate resilience measures in "Multidim_resil_const.do" file, so I do not re-run here.
	*	Please check that code.
	
	*	Regression of univariate resilience measures on HH characteristics (Table 4 of Feb 2023)
	*	(2024-3-10) Drop program vars from regression

		cap	drop	dev_rf_mean_30yravg_m
		gen			dev_rf_mean_30yravg_m	=	dev_rf_mean_30yravg / 1000
		lab	var		dev_rf_mean_30yravg_m	"Deviation in 30-year average annual rainfall (m)"
		
		*	(2024-08-13) Label lagged variables, as they are needed in bootstrapping.
		lab	var	lag_lnrexpaeu_peryear	"Lagged log(consumption per adult)"
		lab	var	lag_HDDS				"Lagged Household Dietary Diversity Score"
		lab	var	lag_TLU_IHS				"Lagged IHS (Tropical Livestock Unit)"
		
		*	(2024-3-19) Added program vars back to regression
		*	(2024-5-12) Drop program variables
		*	(2024-8-13)	Bootstrap standard errors with 500 reps
		reg	allexp_resil_normal		lag_lnrexpaeu_peryear	${resil_RHS}		dev_rf_mean_30yravg_m  /*${demovars}	${econvars}	${rainfallvar}	${FE}	${programvars} */	,	vce(bootstrap, reps(500))
		est	store	resil_allexp_on_HH
		reg	HDDS_resil_normal		lag_HDDS	${resil_RHS}		dev_rf_mean_30yravg_m	  /*${demovars}	${econvars}	${rainfallvar}	${FE}	${programvars} */	,	vce(bootstrap, reps(500))
		est	store	resil_HDDS_on_HH
		reg	TLU_IHS_resil_normal	lag_TLU_IHS		${resil_RHS}	dev_rf_mean_30yravg_m   /*${demovars}	${econvars}	${rainfallvar}	${FE}	${programvars} */	,	vce(bootstrap, reps(500))
		est	store	resil_TLU_IHS_on_HH
		
			
		*	Output

				
				*	Selected covariates (Table 4)
				esttab	resil_allexp_on_HH resil_HDDS_on_HH	resil_TLU_IHS_on_HH		///
						using "${Output}/Final/TableA4_resil_uni_on_HH.csv", ///
						cells(b(star fmt(3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	///
						/*keep(psnp OFSP_HABP "c.psnp#c.OFSP_HABP"	log_psnp	${rainfallvar}	dev_rf_mean_30yravg_m)	order(psnp OFSP_HABP "c.psnp#c.OFSP_HABP"	log_psnp	${rainfallvar}	dev_rf_mean_30yravg_m)*/	///
						drop(*.woreda_id *.year lag_*)	///
						title(Regression of univariate resilience on household characteristics) ///
						mtitles("Expenditure" "Dietary" "Livestock") ///
						note(Standard errors bootstrapped with 500 repetitions) replace


				esttab	resil_allexp_on_HH resil_HDDS_on_HH	resil_TLU_IHS_on_HH		///
						using "${Output}/Final/TableA4_resil_uni_on_HH.tex", ///
						cells(b(star fmt(3)) se(fmt(2) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	///
						/*keep(psnp OFSP_HABP "c.psnp#c.OFSP_HABP"	log_psnp	${rainfallvar}	dev_rf_mean_30yravg_m)	order(psnp OFSP_HABP "c.psnp#c.OFSP_HABP"	log_psnp	${rainfallvar}	dev_rf_mean_30yravg_m)*/	///
						drop(*.woreda_id *.year lag_*)	///
						title(Regression of univariate resilience on household characteristics) ///
						mtitles("Expenditure" "Dietary" "Livestock") ///
						note(Standard errors bootstrapped with 500 repetitions) replace
						
				

	*	Regression of bivariate resilience measures on HH characteristics
	*	(2024-3-10) Drop program vars
	*	(2024-3-19) Added program vars back
	*	(2024-5-12) Drop program vars
	
		*	Poverty and nutrition
		reg	resil_avg_ae_HDDS		lag_lnrexpaeu_peryear		lag_HDDS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_avg_ae_HDDS
		
		reg	resil_uni_ae_HDDS		lag_lnrexpaeu_peryear		lag_HDDS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_uni_ae_HDDS
		
		reg	resil_int_ae_HDDS		lag_lnrexpaeu_peryear		lag_HDDS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_int_ae_HDDS
		

		*	Poverty and asset
		reg	resil_avg_ae_TLU_IHS		lag_lnrexpaeu_peryear		lag_TLU_IHS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_avg_ae_TLU_IHS
		
		reg	resil_uni_ae_TLU_IHS		lag_lnrexpaeu_peryear		lag_TLU_IHS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_uni_ae_TLU_IHS
		
		reg	resil_int_ae_TLU_IHS		lag_lnrexpaeu_peryear		lag_TLU_IHS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_int_ae_TLU_IHS
		
		
		
		*	Nutrition and asset
		reg	resil_avg_HDDS_TLU_IHS		lag_HDDS		lag_TLU_IHS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_avg_HDDS_TLU_IHS
		
		reg	resil_uni_HDDS_TLU_IHS		lag_HDDS		lag_TLU_IHS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_uni_HDDS_TLU_IHS
		
		reg	resil_int_HDDS_TLU_IHS		lag_HDDS		lag_TLU_IHS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_int_HDDS_TLU_IHS
		
		*	Poverty, nutrition and asset
		reg	resil_avg_ae_HDDS_TLU_IHS		lag_lnrexpaeu_peryear	lag_HDDS		lag_TLU_IHS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_avg_ae_HDDS_TLU_IHS
		
		reg	resil_uni_ae_HDDS_TLU_IHS		lag_lnrexpaeu_peryear	lag_HDDS		lag_TLU_IHS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_uni_ae_HDDS_TLU_IHS
		
		reg	resil_int_ae_HDDS_TLU_IHS		lag_lnrexpaeu_peryear	lag_HDDS		lag_TLU_IHS	///
			${resil_RHS}	dev_rf_mean_30yravg_m	/*${demovars}	${econvars}	${rainfallvar}		${FE}	${programvars} */,	vce(bootstrap, reps(500))
		est	store	resil_int_ae_HDDS_TLU_IHS
		
		
	
	
		*	Export
		
			
			*	(2024-3-10) Use bivariate (CE) and trivariate on one table.
			esttab	resil_avg_ae_HDDS		resil_uni_ae_HDDS		resil_int_ae_HDDS	///
					resil_avg_ae_HDDS_TLU_IHS		resil_uni_ae_HDDS_TLU_IHS		resil_int_ae_HDDS_TLU_IHS	///
					using "${Output}/Final/TableA5_resil_multi_on_HH_part1.csv", ///
					cells(b(star fmt(3)) se(fmt(3) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	///
					drop(lag_lnrexpaeu_peryear	lag_HDDS	lag_TLU_IHS *woreda_id* ?.year) 	///
					title(Regression of multivariate resilience on household characteristics - part 1) ///
					mtitles("Avg" "Uni" "Int" "Avg" "Uni" "Int") ///
					note(Standard errors bootstrapped with 500 repetitions) replace
	
			esttab	resil_avg_ae_HDDS		resil_uni_ae_HDDS		resil_int_ae_HDDS	///
					resil_avg_ae_HDDS_TLU_IHS		resil_uni_ae_HDDS_TLU_IHS		resil_int_ae_HDDS_TLU_IHS	///
					using "${Output}/Final/TableA5_resil_multi_on_HH_part1.tex", ///
					cells(b(star fmt(3)) se(fmt(3) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	///
					drop(lag_lnrexpaeu_peryear	lag_HDDS	lag_TLU_IHS *woreda_id* ?.year) 	///
					title(Regression of multivariate resilience on household characteristics - part 1) ///
					mtitles("Avg" "Uni" "Int" "Avg" "Uni" "Int") ///
					note(Standard errors bootstrapped with 500 repetitions) replace
	
			
			
				*	(2024-3-10) Use bivariate (CE) and trivariate on one table.
			esttab	resil_avg_ae_TLU_IHS	resil_uni_ae_TLU_IHS	resil_int_ae_TLU_IHS	///
					resil_avg_HDDS_TLU_IHS		resil_uni_HDDS_TLU_IHS		resil_int_HDDS_TLU_IHS	///
					using "${Output}/Final/TableA6_resil_multi_on_HH_part2.csv", ///
					cells(b(star fmt(3)) se(fmt(3) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	///
					drop(lag_lnrexpaeu_peryear	lag_HDDS	lag_TLU_IHS *woreda_id* ?.year) 	///
					title(Regression of multivariate resilience on household characteristics - part 1) ///
					mtitles("Avg" "Uni" "Int" "Avg" "Uni" "Int") ///
					note(Standard errors bootstrapped with 500 repetitions) replace
	
			esttab	resil_avg_ae_TLU_IHS	resil_uni_ae_TLU_IHS	resil_int_ae_TLU_IHS	///
					resil_avg_HDDS_TLU_IHS		resil_uni_HDDS_TLU_IHS		resil_int_HDDS_TLU_IHS	///
					using "${Output}/Final/TableA6_resil_multi_on_HH_part2.tex", ///
					cells(b(star fmt(3)) se(fmt(3) par)) stats(N r2) label legend nobaselevels  star(* 0.10 ** 0.05 *** 0.01)	///
					drop(lag_lnrexpaeu_peryear	lag_HDDS	lag_TLU_IHS *woreda_id* ?.year) 	///
					title(Regression of multivariate resilience on household characteristics - part 1) ///
					mtitles("Avg" "Uni" "Int" "Avg" "Uni" "Int") ///
					note(Standard errors bootstrapped with 500 repetitions) replace

	
	
		
		*	Generate livestock resilience under different thresholds.
		use	"${dtInt}/PSNP_resilience_const.dta", clear
		
		
			*	Conditional mean and variance does not change, so we just need to create resilience measures using different threshold.
			
			tab TLU_IHS_threshold // asinh(2)
			
			forval	cutoff=4(2)6	{
			
				cap	drop	thresh_TLU_IHS_normal_`cutoff'
				cap	drop	prob_below_TLU_IHS_`cutoff'
				cap	drop	TLU_IHS_resil_normal_`cutoff'
				cap	drop	TLU_IHS_resil_normal_`cutoff'_scale
				
				gen thresh_TLU_IHS_normal_`cutoff'=(asinh(`cutoff')-mean_TLU_IHS_normal)/sd_TLU_IHS_normal	// Let 2 as threshold
					
				gen prob_below_TLU_IHS_`cutoff'=normal(thresh_TLU_IHS_normal_`cutoff')
				gen TLU_IHS_resil_normal_`cutoff'		=	1-prob_below_TLU_IHS_`cutoff'
				gen	TLU_IHS_resil_normal_`cutoff'_scale	=	TLU_IHS_resil_normal_`cutoff'	*	100
					
				lab	var	TLU_IHS_resil_normal_`cutoff'_scale		"Livestock Resilience (normal) - cutoff `cutoff'"
				
		
			}
		
			
			*	Density plot under different thresholds
			
				twoway	(kdensity TLU_IHS_resil_normal,	 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "TLU = 2")))	///
						(kdensity TLU_IHS_resil_normal_4, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "TLU = 4")))	///
						(kdensity TLU_IHS_resil_normal_6, 	 lc(red) lp(shortdash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "TLU = 6") row(1) pos(6) /*size(small)*/ keygap(0.1) symxsize(5))),	///
						/*title("Livestock Resilience under Different TLU Cut-offs")*/ ytitle("Density") xtitle("Probability") name(resil_TLU_IHS_cutoffs, replace) 
				graph	export	"${Output}/Final/FigureA2_resil_TLU_IHS_cutoffs.png", as(png) replace
				graph	close
		
			*	Resilience dynamics table (Table 3) under different thresholds.
				
				*	Create a variable for easier loop
				cap	drop	TLU_IHS_resil_normal_2
				clonevar	TLU_IHS_resil_normal_2	=	TLU_IHS_resil_normal
			
			forval	cutoff=2(2)6	{
			
					*	Full sample
					estpost	tabstat	TLU_IHS_resil_normal_`cutoff',	statistics(mean) columns(statistics) by(round)
					est	store	TLU_IHS_resil_dyn_full_`cutoff'
				
			}

			
			esttab	TLU_IHS_resil_dyn_full_2	TLU_IHS_resil_dyn_full_4	TLU_IHS_resil_dyn_full_6	using	"${Output}/livestock_resilience_dynamics_cutoffs.csv",  ///
				cells("mean(fmt(%12.2f))") label	title("Livestock Resilience Dynamics under Different Cutoffs") noobs	///
				mtitles("Cutoff=2" "Cutoff=4" "Cutoff=6") replace

			esttab	TLU_IHS_resil_dyn_full_2	TLU_IHS_resil_dyn_full_4	TLU_IHS_resil_dyn_full_6	using	"${Output}/livestock_resilience_dynamics_cutoffs.tex",  ///
				cells("mean(fmt(%12.2f))") label	title("Livestock Resilience Dynamics under Different Cutoffs") noobs	///
				mtitles("Cutoff=2" "Cutoff=4" "Cutoff=6") replace
			
		
		
		
		
		
		
		
		
		
		
	
	
