

	use	"${dtInt}/PSNP_resilience_const.dta", replace
		
	*	Correlation among outcomes

		*	Pearson's corr is one earlier to construct bivariate measures.
		pwcorr	${outcome_measures}, sig
		mat	pwcorr_outcome_coef	=	r(C)
		mat	pwcorr_outcome_sig	=	r(sig)
		
		*	Spearman rank correlation
		spearman	${outcome_measures}, stats(rho p)
		mat	spearman_outcome_corr_coef	=	r(Rho)
		mat	spearman_outcome_corr_sig	=	r(P)
		
		*	Kendall's rank correlation
		ktau	${outcome_measures}, stats(taua taub p)	
		mat kendall_taua_outcome_coef	=	r(Tau_a)
		mat	kendall_taub_outcome_coef	=	r(Tau_b)
		mat	kendall_outcome_sig			=	r(P)
						
		*	Correlation among resiliene measures
		pwcorr	${resil_normal}, sig
		mat	pwcorr_resil_coef	=	r(C)
		mat	pwcorr_resil_sig	=	r(sig)
		
		*	Spearman rank correlation
		spearman	${resil_normal}, stats(rho p)
		mat	spearman_outcome_resil_coef	=	r(Rho)
		mat	spearman_outcome_resil_sig	=	r(P)
		
		*	Kendall's rank correlation
		ktau	${resil_normal}, stats(taua taub p)	
		mat kendall_taua_resil_coef	=	r(Tau_a)
		mat	kendall_taub_resil_coef	=	r(Tau_b)
		mat	kendall_resil_sig			=	r(P)
						
			
		*	Summary stats of outcome variables and conditional mean (simple overview of accuracy)
		*	(2023-2-6) Note that comments I made earlier were based on full sample, not 2006 initial sample only
		*	Notable patterns
			*	(1) HDDS resilience measure under normal dist assumption do not exceed 0.82
			*	(2) Extremely high variation in TLU under gamma dist assumption
		*	We see strange and unreliable pattern in TLU under gamma distribution
		tabstat		lnrexpaeu_peryear	mean_allexp_normal	mean_allexp_gamma	///
					lnrfdxpmaeu_peryear	mean_foodexp_normal	mean_foodexp_gamma	///
					HDDS	mean_HDDS_normal	mean_HDDS_gamma	///
					tlu		mean_TLU_normal		mean_TLU_gamma	///
					TLU_IHS	mean_TLU_IHS_normal	mean_TLU_IHS_gamma	///
					/*No_Oxen	mean_Oxen_normal	mean_Oxen_gamma*/	///	
					allexp_resil_normal	allexp_resil_gamma	foodexp_resil_normal	foodexp_resil_gamma	HDDS_resil_normal	HDDS_resil_gamma	TLU_resil_normal	TLU_resil_gamma	///	
					TLU_IHS_resil_normal TLU_IHS_resil_gamma /*Oxen_resil_normal Oxen_resil_gamma*/	///
					${bivariate_resil_measures}	///
					if	!mi(mean_allexp_normal)	&	!mi(mean_foodexp_normal)	&	!mi(mean_HDDS_normal)	&	!mi(mean_TLU_normal)	&	!mi(mean_TLU_IHS_normal),	///
					statistics(count mean	sd	min	max)	save
			
		mat	summstat_outcomes	=	r(StatTotal)'
		mat	list	summstat_outcomes
		
		putexcel	set "${Output}/validation", sheet(sumstat) replace	/*modify*/
		
		putexcel	A2	=	"Summary stats"
		putexcel	A3	=	matrix(summstat_outcomes), names overwritefmt nformat(number_d1)
		
		
		
		*	Distribution of Z-scores (should be normal)
		
			*	All exp and food exp
			twoway	(kdensity thresh_allexp_normal, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "All exp")))	///
					(kdensity thresh_foodexp_normal, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Food exp"))),	///
					title("Outcome Z-scores") ytitle("Density") xtitle("Z-score")
			graph	export	"${Output}/Zscores_expendiutres.png", as(png) replace
			graph	close
			
			*	HDDS and TLU (IHS)
			twoway	(kdensity thresh_HDDS_normal, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "HDDS")))	///
					(kdensity thresh_TLU_IHS_normal, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "TLU(IHS)"))),	///
					title("Outcome Z-scores") ytitle("Density") xtitle("Z-score")
			graph	export	"${Output}/Zscores_nonexp.png", as(png) replace
			graph	close
	
		
		
		*	Prediction accuracy
		
			*	Calculate MSE (between outcome var and conditional mean)
			cap	drop	diff_*
			gen	diff_allexp_normal		=	(lnrexpaeu_peryear	-	mean_allexp_normal)^2
			gen	diff_allexp_gamma		=	(lnrexpaeu_peryear	-	mean_allexp_gamma)^2
	
			gen	diff_HDDS_normal	=	(HDDS	-	mean_HDDS_normal)^2
			gen	diff_HDDS_gamma		=	(HDDS	-	mean_HDDS_gamma)^2
			
		
			gen	diff_TLU_IHS_normal	=	(TLU_IHS	-	mean_TLU_IHS_normal)^2
			gen	diff_TLU_IHS_gamma	=	(TLU_IHS	-	mean_TLU_IHS_gamma)^2
			
			tabstat	diff_*, save
			mat	MSE_cond_mean	=	r(StatTotal)'
			
			putexcel	I2	=	"RMSE of conditional mean"
			putexcel	I3	=	matrix(MSE_cond_mean), names overwritefmt nformat(number_d1)
			
			
			
			*	Compute L2 distance between two resilience distributions
			gen	diff_CE_res_normal_gamma_sq	=	(allexp_resil_normal - allexp_resil_gamma)^2
			gen	diff_HDDS_res_normal_gamma_sq	=	(HDDS_resil_normal - HDDS_resil_gamma)^2
			gen	diff_TLU_res_normal_gamma_sq	=	(TLU_resil_normal - TLU_resil_gamma)^2
			
			egen	sum_diff_CE_resil	=	sum(diff_CE_res_normal_gamma_sq)
			egen	sum_diff_HDDS_resil	=	sum(diff_HDDS_res_normal_gamma_sq)
			egen	sum_diff_TLU_resil	=	sum(diff_TLU_res_normal_gamma_sq)
			
			gen	L2_CE_resil		=	sqrt(sum_diff_CE_resil)
			gen	L2_HDDS_resil	=	sqrt(sum_diff_HDDS_resil)
			gen	L2_TLU_resil	=	sqrt(sum_diff_TLU_resil)
			
			summ	L2_CE_resil	L2_HDDS_resil	L2_TLU_resil
			
		*	Graph outcome variable and conditional mean
		*	(2023-2-16) I disabled Gamma distribution plot just for internal discussion. I can re-activate it when we need to include in the draft as a robustness check.
			
			*	All exp
			twoway	(kdensity lnrexpaeu_peryear, 	 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Expenditure")))	///
					(kdensity mean_allexp_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Cond.mean (Normal)")))	///
					(kdensity mean_allexp_gamma, 	 lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Cond.mean (Gamma)") row(1) size(vsmall) pos(6) keygap(0.1) symxsize(5))),	///
					/*(kdensity mean_allexp_igaussian, lc(red) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "Cond.mean (Inv.Gaussian)"))),*/	///
					title("Consumption Expenditure") ytitle("Density") xtitle("Consumption Expenditure")	name(allexp_normal_gamma, replace) ysize(15) xsize(16.0)
			graph	export	"${Output}/Dist_allexp_cond_mean.png", as(png) replace
			graph	close
			
			*	Food exp
			twoway	(kdensity lnrfdxpmaeu_peryear, 		 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Food expenditure")))	///
					(kdensity mean_foodexp_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Cond.mean (Normal)")))	///
					(kdensity mean_foodexp_gamma, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Cond.mean (Gamma)"))),	///
					title("Distribution of Food Exp and conditional means") ytitle("Density") xtitle("Expenditure")
			graph	export	"${Output}/Dist_foodexp_cond_mean.png", as(png) replace
			graph	close
					
			*	HDDS
			twoway	(hist HDDS, 		 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "HDDS")))	///
					(kdensity mean_HDDS_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Cond.mean (Normal)")))	///
					(kdensity mean_HDDS_gamma, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Cond.mean (Gamma)") row(1) size(vsmall)  pos(6) keygap(0.1) symxsize(5))),	///
					title("HDDS") ytitle("Density") xtitle("Expenditure")	name(HDDS_normal_gamma, replace) ysize(15) xsize(16.0)
			graph	export	"${Output}/Dist_HDDS_cond_mean.png", as(png) replace
			graph	close
			
			*	TLU (normal only. all observations (note: not really helpful)
			twoway	(kdensity tlu, 		 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "TLU")))	///
					(kdensity mean_TLU_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Cond.mean (Normal)")))	///
					(kdensity mean_TLU_gamma, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Cond.mean (Gamma)"))),	///
					title("Distribution of TLU and conditional means") ytitle("Density") xtitle("Expenditure")
			graph	export	"${Output}/Dist_TLU_cond_mean.png", as(png) replace
			graph	close
			
			*	TLU. partial observations (Gamma only from -5 to 20)
			twoway	(kdensity tlu, 		 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "TLU")))	///
					(kdensity mean_TLU_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Cond.mean (Normal)")))	///
					(kdensity mean_TLU_gamma if inrange(mean_TLU_gamma,-5,20), lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Cond.mean (Gamma)"))),	///
					title("Distribution of TLU and conditional means") ytitle("Density") xtitle("Expenditure")
			graph	export	"${Output}/Dist_TLU_cond_mean_partial.png", as(png) replace
			graph	close
			
				
			*	TLU (IHS), partial
			twoway	(kdensity TLU_IHS, 		 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "TLU (IHS)")))	///
					(kdensity mean_TLU_IHS_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Cond.mean (Normal)")))	///
					(kdensity mean_TLU_IHS_gamma if inrange(mean_TLU_IHS_gamma,-5,20), lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Cond.mean (Gamma)") row(1) size(vsmall)  pos(6) keygap(0.1) symxsize(5))),	///
					title("TLU (IHS)") ytitle("Density") xtitle("Expenditure") name(TLU_IHS_normal_gamma, replace) ysize(15) xsize(16.0)
			graph	export	"${Output}/Dist_TLU_IHS_cond_mean_partial.png", as(png) replace
			graph	close
			
	
			*	Combine overall, HDDS and tlu(IHS) graph
				graph	combine	allexp_normal_gamma	HDDS_normal_gamma TLU_IHS_normal_gamma, ///
					/*title(Distribution of Welfare and Predicted Values)*/ ycommon	graphregion(fcolor(white))	 name(FigA1, replace) row(3)
				graph	display FigA1, ysize(40)  xsize(30.0)	
				graph	export	"${Output}/Final/FigureA1_dist_outcome_normal_gamma.png", as(png) replace
				graph	close
			
			
			*	Distribution in resilience measures
			twoway	(kdensity lnrexpaeu_peryear, 	 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Expenditure")))	///
					(kdensity mean_allexp_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Cond.mean (Normal)")))	///
					(kdensity mean_allexp_gamma, 	 lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Cond.mean (Gamma)") row(1) size(vsmall) pos(6) keygap(0.1) symxsize(5))),	///
					/*(kdensity mean_allexp_igaussian, lc(red) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "Cond.mean (Inv.Gaussian)"))),*/	///
					title("Consumption Expenditure") ytitle("Density") xtitle("Consumption Expenditure")	name(allexp_normal_gamma, replace)
			graph	export	"${Output}/Dist_allexp_cond_mean.png", as(png) replace
			graph	close
			
			
			*	Graph resilience measure
				
				*	All exp, food exp and TLU(IHS) - intersection
				twoway	(kdensity allexp_resil_normal,	 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "All expenditure")))	///
						(kdensity foodexp_resil_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Food expenditure")))	///
						(kdensity TLU_IHS_resil_normal, 	 lc(red) lp(shortdash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "TLU(IHS)")))	///
						(kdensity resil_int_ae_TLU_IHS, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "All exp and TLU (IHS)")))	///
						(kdensity resil_int_ae_fe_TLU_IHS, lc(red) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(5 "Trivariate"))),	///
						title("Multi Resilience (intersection) - all exp, food exp and TLU(IHS)") ytitle("Density") xtitle("Probability")
				graph	export	"${Output}/multi_resil_int_ae_fe_TLU_IHS.png", as(png) replace
				graph	close	
				
				*	All exp, food exp and TLU(IHS) - union
				twoway	(kdensity allexp_resil_normal,	 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "All expenditure")))	///
						(kdensity foodexp_resil_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Food expenditure")))	///
						(kdensity TLU_IHS_resil_normal, 	 lc(red) lp(shortdash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "TLU(IHS)")))	///
						(kdensity resil_uni_ae_TLU_IHS, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "All exp and TLU (IHS)")))	///
						(kdensity resil_uni_ae_fe_TLU_IHS, lc(red) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(5 "Trivariate"))),	///
						title("Multi Resilience (union) - all exp, food exp and TLU(IHS)") ytitle("Density") xtitle("Probability")
				graph	export	"${Output}/multi_resil_uni_ae_fe_TLU_IHS.png", as(png) replace
				graph	close	
				
				
				*	All exp, HDDS and TLU(IHS) - intersection
				twoway	(kdensity allexp_resil_normal,	 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "All expenditure")))	///
						(kdensity HDDS_resil_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "HDDS")))	///
						(kdensity TLU_IHS_resil_normal, 	 lc(orange) lp(shortdash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "TLU(IHS)")))	///
						(kdensity resil_int_ae_HDDS, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "All exp and HDDS")))	///
						(kdensity resil_int_HDDS_TLU_IHS, lc(red) lp(longdash) lwidth(medium) graphregion(fcolor(white)) legend(label(5 "HDDS and TLU")))	///
						(kdensity resil_int_ae_HDDS_TLU_IHS, lc(black) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(6 "Trivariate"))),	///
						title("Multi Resilience (intersection) - all exp, HDDS and TLU(IHS)") ytitle("Density") xtitle("Probability")
				graph	export	"${Output}/multi_resil_int_ae_HDDS_TLU_IHS.png", as(png) replace
				graph	close	
				
				*	All exp, food exp and TLU(IHS) - union
				twoway	(kdensity allexp_resil_normal,	 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "All expenditure")))	///
						(kdensity foodexp_resil_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Food expenditure")))	///
						(kdensity TLU_IHS_resil_normal, 	 lc(orange) lp(shortdash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "TLU(IHS)")))	///
						(kdensity resil_uni_ae_HDDS, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "All exp and HDDS")))	///
						(kdensity resil_uni_HDDS_TLU_IHS, lc(red) lp(longdash) lwidth(medium) graphregion(fcolor(white)) legend(label(5 "HDDS and TLU")))	///
						(kdensity resil_uni_ae_HDDS_TLU_IHS, lc(black) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(6 "Trivariate"))),	///
						title("Multi Resilience (union) - all exp, food exp and TLU(IHS)") ytitle("Density") xtitle("Probability")
				graph	export	"${Output}/multi_resil_uni_ae_HDDS_TLU_IHS.png", as(png) replace
				graph	close	
				
				*	TLU and TLU (IHS)
				twoway	(kdensity tlu, 		 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "TLU")))	///
						(kdensity TLU_IHS, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "TLU (IHS)"))),	///
						title("Distribution of TLU") ytitle("Density") xtitle("Expenditure")
				graph	export	"${Output}/Dist_TLU.png", as(png) replace
				graph	close
				
				*	TLU and TLU (IHS) resilience
				twoway	(kdensity TLU_resil_normal, 		 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Resilience (TLU)")))	///
						(kdensity TLU_IHS_resil_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Resilience (TLU_IHS)"))),	///
						title("Distribution of TLU resiliences") ytitle("Density") xtitle("Expenditure")
				graph	export	"${Output}/Dist_TLU_resils.png", as(png) replace
				graph	close

	
	