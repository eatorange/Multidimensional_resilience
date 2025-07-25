
	/*****************************************************************
	PROJECT: 		Multidimensional Development Resilience
					
	TITLE:			Multidim_resil_analyses
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Dec 6, 2022, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	hhid round (Household ID-survey wave)

	DESCRIPTION: 	Construct dynamics measures
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Additional cleaning
					2 - Descriptive analyses
					3 - Regression analyses
					4 - Dynamics analyses
					X - Save and Exit
					
	INPUTS: 		* PSNP pre-cleaned data
					${data_analysis}/PSNP_resilience_dyn.dta ,	clear
										
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
		SECTION 1: Descriptive analyses					
	****************************************************************/		 	
		
			
	use	"${dtInt}/PSNP_resilience_const.dta", clear
	 	
		
		
	*	Correlation 
		pwcorr	lnrexpaeu_peryear	HDDS	tlu, sig	//	outcomes, in-text
		pwcorr	allexp_resil_normal	HDDS_resil_normal	TLU_IHS_resil_normal, sig	//	resilience, Table 3
		
		
		*	Spearman Rank correlation
		
			*	Univariate 
			spearman 	allexp_resil_normal	HDDS_resil_normal	TLU_IHS_resil_normal,  star(0.05) 
			mat	corr_uni_across	=	r(Rho)
			mat	corr_uni_across	=	corr_uni_across[2...,1..2]
			mat list corr_uni_across		
			esttab	matrix(corr_uni_across, fmt(2)) using "${Output}/corr_uni_across.tex",  replace
					
			*	Bivariate - average 
			spearman 	resil_avg_ae_HDDS	resil_avg_ae_TLU_IHS	resil_avg_HDDS_TLU_IHS	resil_avg_ae_HDDS_TLU_IHS,  star(0.05) 
			mat	corr_multi_avg	=	r(Rho)
			matrix rownames corr_multi_avg = "CE \& Dietary" "CE \& Livestock" "Dietary \& Livestock" "CE \& Dietary \& Livestock"
			matrix colnames corr_multi_avg = "CE \& Dietary" "CE \& Livestock" "Dietary \& Livestock" "CE \& Dietary \& Livestock"
			mat	corr_multi_avg	=	corr_multi_avg[2...,1..3]
			mat list corr_multi_avg
			esttab	matrix(corr_multi_avg, fmt(2)) using "${Output}/corr_multi_avg.tex",  replace
			
			*	Bivariate - union 
			spearman 	resil_uni_ae_HDDS	resil_uni_ae_TLU_IHS	resil_uni_HDDS_TLU_IHS	resil_uni_ae_HDDS_TLU_IHS,  star(0.05) 
			mat	corr_multi_uni	=	r(Rho)
			matrix rownames corr_multi_uni = "CE \& Dietary" "CE \& Livestock" "Dietary \& Livestock" "CE \& Dietary \& Livestock"
			matrix colnames corr_multi_uni = "CE \& Dietary" "CE \& Livestock" "Dietary \& Livestock" "CE \& Dietary \& Livestock"
			mat	corr_multi_uni	=	corr_multi_uni[2...,1..3]
			mat list corr_multi_uni
			esttab	matrix(corr_multi_uni, fmt(2)) using "${Output}/corr_multi_uni.tex",  replace
			
			*	Bivariate - intersection 
			spearman 	resil_int_ae_HDDS	resil_int_ae_TLU_IHS	resil_int_HDDS_TLU_IHS	resil_int_ae_HDDS_TLU_IHS,  star(0.05) 
			mat	corr_multi_int	=	r(Rho)
			matrix rownames corr_multi_int = "CE \& Dietary" "CE \& Livestock" "Dietary \& Livestock" "CE \& Dietary \& Livestock"
			matrix colnames corr_multi_int = "CE \& Dietary" "CE \& Livestock" "Dietary \& Livestock" "CE \& Dietary \& Livestock"
			mat	corr_multi_int	=	corr_multi_int[2...,1..3]
			mat list corr_multi_int
			esttab	matrix(corr_multi_int, fmt(2)) using "${Output}/corr_multi_int.tex",  replace
			
	
			*	Combine average, union and intersection
			mat	define nullrow	=J(1,3,.)
			mat corr_multi_combined = corr_multi_avg \ nullrow \  corr_multi_uni \ nullrow \ corr_multi_int
			mat list corr_multi_combined
			esttab	matrix(corr_multi_combined, fmt(2)) using "${Output}/corr_multi_combined.tex",  replace
			
		
			*	By measures
				
				*	Bivariate - Expenditure and Dietary
				spearman 	resil_avg_ae_HDDS	resil_uni_ae_HDDS	resil_int_ae_HDDS,  star(0.05) 
				mat	corr_biv_ae_HDDS	=	r(Rho)
				matrix rownames corr_biv_ae_HDDS = "Average" "Union" "Intersection"
				matrix colnames corr_biv_ae_HDDS = "Average" "Union" "Intersection"
				mat	corr_biv_ae_HDDS	=	corr_biv_ae_HDDS[2...,1..2]
				mat list corr_biv_ae_HDDS			
				
				*	Bivariate - Expenditure and Livestock
				spearman 	resil_avg_ae_TLU_IHS	resil_uni_ae_TLU_IHS	resil_int_ae_TLU_IHS,  star(0.05) 
				mat	corr_biv_ae_TLU_IHS	=	r(Rho)
				matrix rownames corr_biv_ae_TLU_IHS = "Average" "Union" "Intersection"
				matrix colnames corr_biv_ae_TLU_IHS = "Average" "Union" "Intersection"
				mat	corr_biv_ae_TLU_IHS	=	corr_biv_ae_TLU_IHS[2...,1..2]
				mat list corr_biv_ae_TLU_IHS		
				
				*	Bivariate - DFietary and Livestock
				spearman 	resil_avg_HDDS_TLU_IHS	resil_uni_HDDS_TLU_IHS	resil_int_HDDS_TLU_IHS,  star(0.05) 
				mat	corr_biv_HDDS_TLU_IHS	=	r(Rho)
				matrix rownames corr_biv_HDDS_TLU_IHS = "Average" "Union" "Intersection"
				matrix colnames corr_biv_HDDS_TLU_IHS = "Average" "Union" "Intersection"
				mat	corr_biv_HDDS_TLU_IHS	=	corr_biv_HDDS_TLU_IHS[2...,1..2]
				mat list corr_biv_HDDS_TLU_IHS		
				
				*	Trivariate
				spearman 	resil_avg_ae_HDDS_TLU_IHS		resil_uni_ae_HDDS_TLU_IHS	resil_int_ae_HDDS_TLU_IHS,  star(0.05) 
				mat	corr_tri_ae_HDDS_TLU_IHS	=	r(Rho)
				matrix rownames corr_tri_ae_HDDS_TLU_IHS = "Average" "Union" "Intersection"
				matrix colnames corr_tri_ae_HDDS_TLU_IHS = "Average" "Union" "Intersection"
				mat	corr_tri_ae_HDDS_TLU_IHS	=	corr_tri_ae_HDDS_TLU_IHS[2...,1..2]
				mat list corr_tri_ae_HDDS_TLU_IHS		

				
				*	Combine
				mat	define nullrow_4	=J(1,4,.)
				mat	define nullcol_3	=J(3,1,.)
				mat	corr_multi_combined_2	=	(corr_biv_ae_HDDS,	corr_biv_ae_TLU_IHS) \ nullrow_4 \  (corr_biv_HDDS_TLU_IHS, corr_tri_ae_HDDS_TLU_IHS)
				mat list corr_multi_combined_2
				esttab	matrix(corr_multi_combined_2, fmt(2)) using "${Output}/corr_multi_combined_2.tex",  replace
				
				
					
				putexcel	set "${Output}/Final/Table4_Corr_multi_combined", sheet(Table4) replace
				putexcel	B4	=	matrix(corr_multi_combined), names overwritefmt nformat(number_d2) 	
				putexcel	B20	=	matrix(corr_multi_combined_2), names overwritefmt nformat(number_d2) 	
				
				*	All at once
				spearman 	resil_avg_ae_HDDS	resil_uni_ae_HDDS	resil_int_ae_HDDS	///
							resil_avg_ae_TLU_IHS	resil_uni_ae_TLU_IHS	resil_int_ae_TLU_IHS	///
							resil_avg_ae_TLU_IHS	resil_uni_ae_TLU_IHS	resil_int_ae_TLU_IHS	///
							resil_avg_ae_HDDS_TLU_IHS		resil_uni_ae_HDDS_TLU_IHS	resil_int_ae_HDDS_TLU_IHS,  star(0.05) 
							
				
			mat	corr_multi_all = r(Rho)
			matrix rownames corr_multi_all = "aa" "bb" "cc"
			matrix colnames corr_multi_all = "dd" "ee" "cc"
			esttab	matrix(corr_multi_all) using "${Output}/Corr_multi_all.tex",  replace
			
						
	cap	drop	rexpaeu_peryear_USD
	gen	rexpaeu_peryear_USD	=	rexpaeu_peryear/17 // USD conversion, 1 USD=17birr (2014)
	cap	drop	psnp_amt_USD
	gen	psnp_amt_USD	=	psnp_amt / 17
	lab	var	psnp_amt	"PSNP benefit amount per capita (birr)"
	lab	var	psnp_amt_USD	"PSNP benefit amount per capita (USD)"
	
	*	Summary statistics
	
		*	Modify some variable labels
		lab	var	vlvstk_real		"Livestock asset value"
		lab	var	vprodeq_realaeu	"Production asset value per aeu"
		lab	var	dist_nt			"Distance to the nearest town"
		lab	var	psnp_amt		"PSNP benefit amount per capita (birr)*"
	
		*	Variable macros	
			local	hhvars		malehead	head_age	headnoed	maritals_m	hhsize
			local	econvars	occupation_farm	/*occupation_non_farm*/	///
								landaeu vlvstk_real vprodeq_realaeu	electricity 	dist_nt	/* rainfall*/ rf_annual
			local	programvars	psnp	DS PW	OFSP_HABP	PSNP_HABP	psnp_amt	/* psnp_amt_USD */
			local	depvars		rexpaeu_peryear	/*rexpaeu_peryear_USD*/	HDDS	tlu
		
		*	Pooled data  (Table 1)
		
			estpost tabstat	`hhvars'	`econvars'	`programvars'	`depvars',	statistics(count	mean	sd) columns(statistics)	// save
			est	store sumstat
			
			
			*	By program participation
			estpost tabstat	`hhvars'	`econvars'	`programvars'	`depvars' if psnp==0,	///
				statistics(count	mean	sd) columns(statistics)	
			est	store sumstat_nopsnp
			
			estpost tabstat	`hhvars'	`econvars'	`programvars'	`depvars' if psnp==1,	///
				statistics(count	mean	sd) columns(statistics)	
			est	store sumstat_psnp
			
			*	By round 
			*iebaltab `hhvars'	`econvars'	`programvars'	`depvars', grpvar(round) rowvarlabels nottest save("${Output}/round_baltab.xlsx") replace
			*estpost tabstat	`hhvars'	`econvars'	`programvars'	`depvars',	statistics(count	mean	sd) columns(statistics) by(round)
			
			forval	year=2006(2)2014	{
					
					estpost	tabstat		`hhvars'	`econvars'	`programvars'	`depvars'	if	round==`year',	///
						statistics(count	mean	sd) columns(statistics)	// save
					est	store	sumstat_`year'
				}
				
			*	Export
			
				*	Pooled and 2008 - Table 1 (2006 is added in June 2024 as John suggested)
			
			
			esttab	sumstat	sumstat_2006	using	"${Output}/Final/Table1_Summary_Statistics.csv",  ///
				cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace

			esttab	sumstat	sumstat_2006	using	"${Output}/Final/Table1_Summary_Statistics.tex",  ///
				cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f))") label	title("Summary Statistics") noobs 	 note(All monetary variables are in birr, 2014 contant price) replace
				

		*	By program participation and 2008-2014 (Appendix Table 1 of Feb 2023 draft)
		*	(2024-7-5) Drop PSNP and non-PSNP columns
			
			*	Export
		
			esttab	/* sumstat_nopsnp	sumstat_psnp */	sumstat_2006	sumstat_2008	sumstat_2010	sumstat_2012	sumstat_2014	///
				using	"${Output}/Final/TableA1_subgroup_summary_stats.csv",  ///
				cells(/*count(fmt(%12.0f))*/ mean(fmt(%12.2f)) sd(par fmt(%12.2f))) label	///
				mtitle("2006"  "2008" "2010" "2012" "2014") title("Summary statistics by PSNP status and survey round") noobs 	  replace
					
			
			esttab	/* sumstat_nopsnp	sumstat_psnp*/	sumstat_2006	sumstat_2008 	sumstat_2010	sumstat_2012	sumstat_2014	///
				using	"${Output}/Final/TableA1_subgroup_summary_stats.tex",  ///
				cells(/*count(fmt(%12.0f))*/ mean(fmt(%12.2fc)) sd(par fmt(%12.2f))) label	///
				mtitle("2006" "2008" "2010" "2012" "2014") title("Summary statistics by PSNP status and survey round") noobs  note(All monetary variables are in birr, 2014 constant price)	  replace
				
		
		
		*	Local polynomial graph of TLU and consumption (Figure 1)
		*	Food expenditure and TLU has positive association since TLU>=2.5. I use it as the TLU threshold.
		twoway	 (lpolyci lnrexpaeu_peryear tlu if tlu<=15,	///
				bwidth (1) degree(1) legend(order(1  2 "Consumption expenditure") pos(6) row(1)) /*title("Distribution of consumption expenditure over TLU", color(black))*/ name(Fig2, replace)	///
				xline(2, lp(dash)lwidth(vthin)) xlabel(2 "TLU threshold (2)" 5 10 15) ytitle("log(consumption expenditure)") xtitle("TLU") note(Top 1 percentile (TLU>15) omitted)) 
		*graph	display Fig2, ysize(12) xsize(13.0)	
		graph	export	"${Output}/Final/Figure2_Allexp_TLU_lpoly.png", as(png) replace
		graph	close	
				
			
	

		*	Welfare Dynamics (Table 2 of June 2025 draft)
			
			*	Expenditure

				*	Generate a binary indicator if HH consume "below" PL
				loc	var	allexp_below_PL
				cap	drop	`var'
				gen		`var'=.
				replace	`var'=0	if	allexp_above_PL==1
				replace	`var'=1	if	allexp_above_PL==0
				lab	var	`var'	"Consumption expenditure below poverty line"
				order	allexp_below_PL,	after(allexp_above_PL)
				
					*	Full sample
					estpost	tabstat	allexp_below_PL,	statistics(mean) columns(statistics) by(round)
					est	store	poverty_dyn_full
					
					*	non-PSNP
					estpost	tabstat	allexp_below_PL	if	psnp==0,	statistics(mean) columns(statistics) by(round)
					est	store	poverty_dyn_nonpsnp
					
					*	PSNP
					estpost	tabstat	allexp_below_PL	if	psnp==1,	statistics(mean) columns(statistics) by(round)
					est	store	poverty_dyn_psnp
			
			*	HDDS
			
				*	Generate a binary indicator if HHDS is below 5
				loc	var	HDDS_below_5
				cap	drop	`var'
				gen		`var'=.
				replace	`var'=0	if	HDDS>=5
				replace	`var'=1	if	HDDS<5
				lab	var	`var'	"HDDS below 5"
				
					*	Full sample
					estpost	tabstat	HDDS_below_5,	statistics(mean) columns(statistics) by(round)
					est	store	HDDS_dyn_full
					
					*	non-PSNP
					estpost	tabstat	HDDS_below_5	if	psnp==0,	statistics(mean) columns(statistics) by(round)
					est	store	HDDS_dyn_nonpsnp
					
					*	PSNP
					estpost	tabstat	HDDS_below_5	if	psnp==1,	statistics(mean) columns(statistics) by(round)
					est	store	HDDS_dyn_psnp
			
			*	TLU
				
					*	Generate a binary indicator if HHDS is below 5
					loc	var	TLU_below_2
					cap	drop	`var'
					gen		`var'=.
					replace	`var'=0	if	tlu>=2
					replace	`var'=1	if	tlu<2
					lab	var	`var'	"TLU below 2"
					
						*	Full sample
						estpost	tabstat	TLU_below_2,	statistics(mean) columns(statistics) by(round)
						est	store	TLU_dyn_full
						
						*	non-PSNP
						estpost	tabstat	TLU_below_2	if	psnp==0,	statistics(mean) columns(statistics) by(round)
						est	store	TLU_dyn_nonpsnp
						
						*	PSNP
						estpost	tabstat	TLU_below_2	if	psnp==1,	statistics(mean) columns(statistics) by(round)
						est	store	TLU_dyn_psnp
				
			
				
				esttab	poverty_dyn_full	poverty_dyn_nonpsnp	poverty_dyn_psnp	///
						HDDS_dyn_full		HDDS_dyn_nonpsnp	HDDS_dyn_psnp	///
						TLU_dyn_full		TLU_dyn_nonpsnp		TLU_dyn_psnp	///
						using	"${Output}/welfare_dynamics.csv",  ///
					cells("mean(fmt(%12.2f))") label	title("Welfare Dynamics - Consumption Expenditure, HDDS and TLU") noobs	///
					mtitles("Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries") replace

				esttab	poverty_dyn_full	poverty_dyn_nonpsnp	poverty_dyn_psnp	///
						HDDS_dyn_full		HDDS_dyn_nonpsnp	HDDS_dyn_psnp	///
						TLU_dyn_full		TLU_dyn_nonpsnp		TLU_dyn_psnp	///
						using	"${Output}/welfare_dynamics.tex",  ///
					cells("mean(fmt(%12.2f))") label	title("Welfare Dynamics - Consumption Expenditure, HDDS and TLU") noobs	///
					mtitles("Full sample" "non-PSNP" "PSNP"	"Full sample" "non-PSNP" "PSNP") replace
				
				*	(2024-3-19) Report total dynamics only
				esttab	poverty_dyn_full	HDDS_dyn_full	TLU_dyn_full	using	"${Output}/Final/Table2_welfare_dynamics.csv",  ///
					cells("mean(fmt(%12.2f))") label	title("Welfare Dynamics - Consumption Expenditure, HDDS and TLU") noobs	///
				/*	mtitles("Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries")*/ replace	
				
				esttab		poverty_dyn_full	HDDS_dyn_full	TLU_dyn_full	using	"${Output}/Final/Table2_welfare_dynamics.tex",  ///
					cells("mean(fmt(%12.2f))") label	title("Welfare Dynamics - Consumption Expenditure, HDDS and TLU") noobs	///
					/*mtitles("Full sample" "non-PSNP" "PSNP"	"Full sample" "non-PSNP" "PSNP)*/ replace
	
	
			
			*	Use Figure
			preserve
				collapse	(mean)	allexp_below_PL	HDDS_below_5	TLU_below_2, by(round)
				
				graph	twoway	(connected	allexp_below_PL	round, mlabel(allexp_below_PL) mlabposition(12) mlabformat(%12.2f) msymbol(diamond) lc(green) lp(solid))	///
								(connected	HDDS_below_5	round, mlabel(HDDS_below_5) mlabposition(12) mlabformat(%12.2f) msymbol(circle) lc(blue) lp(dash))	///
								(connected	TLU_below_2	round, mlabel(TLU_below_2) mlabposition(12) mlabformat(%12.2f) msymbol(triangle) lc(red) lp(dot)),	///
								legend(label(1 "Consumption expenditure below poverty line") lab(2 "HDDS below 5") lab(3 "TLU below 2") pos(6) row(1) size(small)) ytitle(Porportion) xtitle(Survey Round) name(Fig3, replace)
				graph	export	"${Output}/Final/Figure3_welfare_dynamics.png", as(png) replace
			restore
			
		
	
		*	Sample households distribution
		forval	year=2006(2)2014	{
			
			*	Sample households
			graph	twoway	(histogram id01 if round==`year', discrete frequency title("`year'") xtitle("Region") ytitle("") xlabel(1(1)9, labsize(vsmall) angle(forty_five) valuelabel) name(dist_region_`year', replace) nodraw)
				
		}
		
		graph	twoway	(bar	lnrexpaeu_peryear	id01)
		
		graph	combine	dist_region_2006	dist_region_2008	dist_region_2010	dist_region_2012	dist_region_2014, title("Sample distribution by region")
		graph	export	"${Output}/sample_dist_region.png", as(png) replace
		

		*	Distribution of Welfare Outcomes (Figure 1 of Feb 2023 draft)
			
			*	Consumption expenditure (full-sample, PSNP and non-PSNP)
			twoway	(kdensity ${outcome_allexp}, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full")))	///
					(kdensity ${outcome_allexp} if psnp==1, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "PSNP")))	///
					(kdensity ${outcome_allexp}	if psnp==0, lc(red) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "non-PSNP") row(1) pos(6) size(vsmall))), 	///
					ytitle("Density") xtitle("Log(Consumption Expenditure)")	title("Consumption Expenditure") name(allexp_outcome_dist, replace)
		
			*	HDDS
			twoway	(hist ${outcome_HDDS}, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full")))	///
					(hist ${outcome_HDDS} if psnp==1, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "PSNP")))	///
					(hist ${outcome_HDDS} if psnp==0, lc(red) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "non-PSNP") row(1)  pos(6) size(vsmall))), 	///
					ytitle("Density") xtitle("HDDS")	title("HDDS") name(HDDS_outcome_dist, replace)
			
			*	TLU (IHS)
			twoway	(kdensity ${outcome_TLU_IHS}, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full")))	///
					(kdensity ${outcome_TLU_IHS} if psnp==1, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "PSNP")))	///
					(kdensity ${outcome_TLU_IHS} if psnp==0, lc(red) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "non-PSNP") row(1)  pos(6) size(vsmall))), 	///
					ytitle("Density") xtitle("TLU (IHS)")	title("TLU (IHS)") name(TLU_IHS_outcome_dist, replace)		
				
		
			*	Combine graphs
				graph	combine	allexp_outcome_dist	HDDS_outcome_dist TLU_IHS_outcome_dist, ///
					/*title(Distribution of Resilience Measures)*/ ycommon	graphregion(fcolor(white))	name(Fig1, replace)
				graph	export	"${Output}/Fig1_outcome_dist_resize.png", as(png) replace
				graph	close
			
			
			*	(2024-3-19) Plot total only
				
				*	Consumption expenditure (full-sample, PSNP and non-PSNP)
				twoway	(kdensity ${outcome_allexp}, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full"))), 	///
					ytitle("Density") xtitle("Log(Consumption Expenditure)")	title("Consumption Expenditure") 	ysize(15) xsize(16.0)		///
					name(allexp_outcome_dist_tot, replace)
				*graph	export	"${Output}/temp1.png", as(png) replace
				*graph	display allexp_outcome_dist_tot, ysize(10) xsize(16.0)	
				
				*	HDDS
				twoway	(hist ${outcome_HDDS}, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full"))), 	///
					ytitle("Density") xtitle("HDDS")	title("HDDS") name(HDDS_outcome_dist_tot, replace)	ysize(15) xsize(16.0)
			
				*	TLU (IHS)
				twoway	(kdensity ${outcome_TLU_IHS}, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full"))), 	///
					ytitle("Density") xtitle("TLU (IHS)")	title("TLU (IHS)") name(TLU_IHS_outcome_dist_tot, replace)	ysize(15) xsize(16.0)	
				
		
			*	Combine graphs
				graph	combine	allexp_outcome_dist_tot	HDDS_outcome_dist_tot TLU_IHS_outcome_dist_tot, ///
					/*title(Distribution of Resilience Measures)*/ ycommon	graphregion(fcolor(white))	name(Fig1, replace) row(3)
				graph	display Fig1, ysize(40)  xsize(30.0)	
				graph	export	"${Output}/Final/Figure1_Dist_wellbeing.png", as(png) replace
				graph	close
			
		*	Distribution of univariate resilience measures (full, PSNP and non-PSNP)	Fig3 of June 2025 draft
			
			*	Consumption expenditure
				twoway	(kdensity allexp_resil_normal, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full")))	///
						(kdensity allexp_resil_normal if psnp==1, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "PSNP")))	///
						(kdensity allexp_resil_normal if psnp==0, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "non-PSNP") row(1) size(small) keygap(0.1) symxsize(5))),	///
						title("Consumption Expenditure",	color(black) size(medium)) ytitle("Density") xtitle("Resilience") name(dist_resil_consexp, replace)
						
			*	HDDS
				twoway	(kdensity HDDS_resil_normal, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full")))	///
						(kdensity HDDS_resil_normal if psnp==1, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "PSNP")))	///
						(kdensity HDDS_resil_normal if psnp==0, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "non-PSNP")  row(1) size(small) keygap(0.1) symxsize(5))),	///
						title("Dietary",	color(black) size(medium)) ytitle("Density") xtitle("Resilience") name(dist_resil_HDDS, replace)
						
			*	TLU (IHS)
				twoway	(kdensity TLU_IHS_resil_normal, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full")))	///
						(kdensity TLU_IHS_resil_normal if psnp==1, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "PSNP")))	///
						(kdensity TLU_IHS_resil_normal if psnp==0, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "non-PSNP") row(1) size(small) keygap(0.1) symxsize(5))),	///
						title("Livestock",	color(black) size(medium)) ytitle("Density") xtitle("Resilience") name(dist_resil_TLU_IHS, replace)

			
			
			*	Combine graphs
				graph	combine	dist_resil_consexp	dist_resil_HDDS dist_resil_TLU_IHS, ///
					/*title(Distribution of Resilience Measures)*/ ycommon	graphregion(fcolor(white))	
				graph	export	"${Output}/Fig3_uniresil_dist.png", as(png) replace
				graph	close
				
			*	(2024-3-19)	 Total only (fig 3)
			
			*	Consumption expenditure
				twoway	(kdensity allexp_resil_normal, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full"))),	///
						title("Consumption Expenditure",	color(black) size(medium)) ytitle("Density") xtitle("Resilience") name(dist_resil_consexp, replace)
						
			*	HDDS
				twoway	(kdensity HDDS_resil_normal, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full"))),	///
						title("Dietary",	color(black) size(medium)) ytitle("Density") xtitle("Resilience") name(dist_resil_HDDS, replace)
						
			*	TLU (IHS)
				twoway	(kdensity TLU_IHS_resil_normal, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full"))),	///
						title("Livestock",	color(black) size(medium)) ytitle("Density") xtitle("Resilience") name(dist_resil_TLU_IHS, replace)

			*	Combined
				twoway	(kdensity allexp_resil_normal, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Expenditure")))	///
						(kdensity HDDS_resil_normal, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Dietary")))	///
						(kdensity TLU_IHS_resil_normal, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Livestock")  row(1) size(small) keygap(0.1) pos(6) symxsize(5))),	///
						/*title("Distribution of Univariate Resilience Measures",	color(black) size(medium))*/ ytitle("Density") xtitle("Resilience") name(dist_resil_all, replace)
				graph	export	"${Output}/Final/Figure4_uniresil_dist.png", as(png) replace
				graph	close
			
			/*
			*	Combine graphs
				graph	combine	dist_resil_consexp	dist_resil_HDDS dist_resil_TLU_IHS, ///
					/*title(Distribution of Resilience Measures)*/ ycommon	graphregion(fcolor(white))	
				graph	export	"${Output}/Fig3_uniresil_dist.png", as(png) replace
				graph	close
			*/
	
		*	Distribution of multivariate resiliences (fig 6 of July 2024 draft)
		
			*	Poverty and Nutritional
				twoway	/*(kdensity allexp_resil_normal,	 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Poverty")))	///
						(kdensity HDDS_resil_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Nutritional"))) */	///
						(kdensity resil_avg_ae_HDDS, 	 lc(red) lp(shortdash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Average")))	///
						(kdensity resil_uni_ae_HDDS, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Union")))	///
						(kdensity resil_int_ae_HDDS, lc(grau) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Intersection") row(1) size(small) pos(6) keygap(0.1) symxsize(5))),	///
						title("Consumption Expenditure and Dietary", size(medsmall)) ytitle("Density") xtitle("Probability") name(dist_multires_pov_nut, replace) //note(CE stands for Consumption Expenditure)
				*graph	export	"${Output}/multi_resil_pov_nut.png", as(png) replace
				*graph	close	
				
		
			*	Poverty and Asset
				twoway	/*(kdensity allexp_resil_normal,	 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Poverty")))	///
						(kdensity TLU_IHS_resil_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Asset")))*/	///
						(kdensity resil_avg_ae_TLU_IHS, 	 lc(red) lp(shortdash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Average")))	///
						(kdensity resil_uni_ae_TLU_IHS, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Union")))	///
						(kdensity resil_int_ae_TLU_IHS, lc(grau) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Intersection") row(1) size(small) pos(6) keygap(0.1) symxsize(5))),	///
						title("Consumption Expenditure and Livestock", size(medsmall)) ytitle("Density") xtitle("Probability") name(dist_multires_pov_ast, replace) //note(CE stands for Consumption Expenditure)
				*graph	export	"${Output}/multi_resil_pov_ast.png", as(png) replace
				*graph	close	
		
			*	Nutritional and Asset
				twoway	/*(kdensity HDDS_resil_normal,	 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Nutritional")))	///
						(kdensity TLU_IHS_resil_normal, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Asset")))*/	///
						(kdensity resil_avg_HDDS_TLU_IHS, 	 lc(red) lp(shortdash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Intersection")))	///
						(kdensity resil_uni_HDDS_TLU_IHS, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Union")))	///
						(kdensity resil_int_HDDS_TLU_IHS, lc(grau) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Intersection") row(1) size(small) pos(6) keygap(0.1) symxsize(5))),	///
						title("Dietary and Livestock", size(medsmall)) ytitle("Density") xtitle("Probability") name(dist_multires_nut_ast, replace) 
				*graph	export	"${Output}/multi_resil_nut_ast.png", as(png) replace
				*graph	close
				
				*	Poverty, Nutritional and Asset
				twoway	(kdensity resil_avg_ae_HDDS_TLU_IHS, 	 lc(red) lp(shortdash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Average")))	///
						(kdensity resil_uni_ae_HDDS_TLU_IHS, lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Union")))	///
						(kdensity resil_int_ae_HDDS_TLU_IHS, lc(grau) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Intersection") row(1) size(small) pos(6) keygap(0.1) symxsize(5))),	///
						title("Consumption Expenditure, Dietary and Livestock", size(medsmall)) ytitle("Density") xtitle("Probability") name(dist_multires_pov_nut_ast, replace) //note(CE stands for Consumption Expenditure)
				*graph	export	"${Output}/multi_resil_pov_nut_ast.png", as(png) replace
				*graph	close	
		
				*	Combine graphs
				graph	combine	dist_multires_pov_nut	dist_multires_pov_ast dist_multires_nut_ast	dist_multires_pov_nut_ast, ///
					/*title(Distribution of Resilience Measures)*/ ycommon	graphregion(fcolor(white))	 name(Fig7, replace)
					
				graph	display Fig7, ysize(12) xsize(13.0)	
				graph	export	"${Output}/Final/Figure7_multiresil_dist.png", as(png) replace
				graph	close
		
		*	Resilience Dynamics
				
				*	Univariate measures (Table 3 of 2023 draft)
				
				foreach	var	in	allexp	HDDS	TLU_IHS	{
					
					*	Generate a binary indicator if expenditure resilience is below 0.5
					*cap	drop	`var'_resil
					*gen		`var'_resil=.
					*replace	`var'_resil=0	if	!mi(`var'_resil_normal)	&	`var'_resil_normal<0.5
					*replace	`var'_resil=1	if	!mi(`var'_resil_normal)	&	`var'_resil_normal>=0.5
										
						*	Full sample
						estpost	tabstat	`var'_resil_normal,	statistics(mean) columns(statistics) by(round)
						est	store	`var'_resil_dyn_full
						
						*	non-PSNP
						estpost	tabstat	`var'_resil_normal	if	psnp==0,	statistics(mean) columns(statistics) by(round)
						est	store	`var'_resil_dyn_nonpsnp
						
						*	PSNP
						estpost	tabstat	`var'_resil_normal	if	psnp==1,	statistics(mean) columns(statistics) by(round)
						est	store	`var'_resil_dyn_psnp
							
					
				}

			
			esttab	allexp_resil_dyn_full		allexp_resil_dyn_nonpsnp	allexp_resil_dyn_psnp	///
					HDDS_resil_dyn_full			HDDS_resil_dyn_nonpsnp			HDDS_resil_dyn_psnp	///
					TLU_IHS_resil_dyn_full		TLU_IHS_resil_dyn_nonpsnp		TLU_IHS_resil_dyn_psnp	///
					using	"${Output}/resilience_dynamics.csv",  ///
				cells("mean(fmt(%12.2f))") label	title("Resilience Dynamics - Expenditure, Dietary and Livestock") noobs	///
				mtitles("Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries") replace

			esttab	allexp_resil_dyn_full		allexp_resil_dyn_nonpsnp	allexp_resil_dyn_psnp	///
					HDDS_resil_dyn_full			HDDS_resil_dyn_nonpsnp			HDDS_resil_dyn_psnp	///
					TLU_IHS_resil_dyn_full		TLU_IHS_resil_dyn_nonpsnp		TLU_IHS_resil_dyn_psnp	///
					using	"${Output}/resilience_dynamics.tex",  ///
				cells("mean(fmt(%12.2f))") label	title("Resilience Dynamics - Expenditure, Dietary and Livestock") noobs	///
				mtitles("Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries") replace
			
			*	(2024-3-19) Total dynamics only
			esttab	allexp_resil_dyn_full		HDDS_resil_dyn_full	TLU_IHS_resil_dyn_full	using	"${Output}/resilience_dynamics.csv",  ///
				cells("mean(fmt(%12.2f))") label	title("Resilience Dynamics - Expenditure, Dietary and Livestock") noobs	///
				/*mtitles("Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries")*/ replace

			esttab	allexp_resil_dyn_full		HDDS_resil_dyn_full	TLU_IHS_resil_dyn_full	using	"${Output}/resilience_dynamics.tex",  ///
				cells("mean(fmt(%12.2f))") label	title("Resilience Dynamics - Expenditure, Dietary and Livestock") noobs	///
				/*mtitles("Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries"	"Full sample" "PSNP non-beneficiaries" "PSNP beneficiaries")*/ replace
		
		
		*xtsum		${resil_normal}	${bivariate_resil_measures}	${trivariate_resil_measure}
		
		*	Figure plotting univariate resilience dynamics
		use	"${dtInt}/PSNP_resilience_const.dta", clear
			
			lab	var	allexp_resil_normal		"Expenditure"
			lab	var	HDDS_resil_normal		"Dietary"
			lab	var	TLU_IHS_resil_normal	"Livestock"
			
			lgraph 	allexp_resil_normal HDDS_resil_normal	TLU_IHS_resil_normal round, errortype(iqr) separate(0.01) wide /*title(Univariate Resilience Dynamics)*/  bgcolor(white)	///
					graphregion(color(white))  yscale(range(0.5 1) titlegap(1)) 	ylabel(0.1(0.1)1) 	name(PFS_annual, replace) ytitle(Probability)	xtitle(Survey Round)	///
					legend(lab (1 "Consumption Expenditure") lab(2 "Dietary") lab(3 "Livestock")  rows(1) pos(6))	 ///
					note(Capped bars represent interquantile range)
			
			graph	export	"${Output}/Final/Figure6_uni_resilience_dynamics.png", replace as(png)
			graph	close
	
		
		*	Correlation among resilience measures (Table 5 of Feb 2023 draft)
		use	"${dtInt}/PSNP_resilience_const.dta", clear
		
		pwcorr	allexp_resil_normal		HDDS_resil_normal	TLU_IHS_resil_normal, sig
		mat	pwcorr_uniresil_coef	=	r(C)
		mat	pwcorr_uniresil_sig	=	r(sig)
		
		mat	rownames	pwcorr_uniresil_coef	=	"Expenditure"  "Dietary"  "Livestock"
		mat	colnames	pwcorr_uniresil_coef	=	"Expenditure"  "Dietary"  "Livestock"
											
		 esttab  matrix(pwcorr_uniresil_coef, fmt(%12.2f)) using    "${Output}/corr_uni_resil.tex", ///
		 note("All significant at 95%") replace
		 
		 
		 
		 
		 	
	
		*	Headcount ratio (HCR) (both unadjusted (UHCR) and adjusted (AHCR)) - Table 4 of Feb 2020 draft
			*	Unadjusted (UHCR): share of non-resilient households
			*	Adjusted (AHCR): UHCR * average number of non-resilience measures among non-resilient households (intensity)
		
		cap	mat	drop	UHCR_1_all
		cap	mat	drop	UHCR_2_all
		cap	mat	drop	UHCR_3_all
		cap	mat	drop	UHCR_all
		cap	mat	drop	AHCR_1_all
		cap	mat	drop	AHCR_2_all
		cap	mat	drop	AHCR_3_all
		cap	mat	drop	AHCR_all
		
				forval	k=1/3	{	//	# of non-resilient measures to be defined as non-resilient
					
					foreach	year	in	2008	2010	2012	2014	pool	{	//	survey round (including pooled data)
						
						*	Keep specific year of observations only for non-pooled data
						if	"`year'"!="pool"	{	
							preserve
							keep	if	round==`year'
						}
							
							*	Unadjusted HCR
							summ	nonresil_inten_`k'	//	Full sample
							scalar	UHCR_`k'_full_`year'	=	r(mean)
							summ	nonresil_inten_`k'	if	psnp==1	//	PSNP
							scalar	UHCR_`k'_psnp_`year'	=	r(mean)
							summ	nonresil_inten_`k'	if	psnp==0	//	non-PSNP
							scalar	UHCR_`k'_nonpsnp_`year'	=	r(mean)
							
								*	Combine full, PSNP and non-PSNP as a matrix
								cap	mat	drop	UHCR_`k'_`year'
								mat	UHCR_`k'_`year'	=	UHCR_`k'_full_`year',	 UHCR_`k'_nonpsnp_`year', UHCR_`k'_psnp_`year'
							
							*	Intensity
							summ	num_nonresil	if	nonresil_inten_`k'==1	//	full sample
							scalar	INT_`k'_full_`year'		=	r(mean)
							summ	num_nonresil	if	nonresil_inten_`k'==1	&	psnp==1	//	PSNP
							scalar	INT_`k'_psnp_`year'		=	r(mean)
							summ	num_nonresil	if	nonresil_inten_`k'==1	&	psnp==0	//	PSNP
							scalar	INT_`k'_nonpsnp_`year'		=	r(mean)
							
							*	Adjusted HCR (AHCR) = UHCR * Intnsity
							scalar	AHCR_`k'_full_`year'		=	UHCR_`k'_full_`year'	*	INT_`k'_full_`year'
							scalar	AHCR_`k'_psnp_`year'		=	UHCR_`k'_psnp_`year'	*	INT_`k'_psnp_`year'
							scalar	AHCR_`k'_nonpsnp_`year'	=	UHCR_`k'_nonpsnp_`year'	*	INT_`k'_nonpsnp_`year'	
							
								*	Combine full, PSNP and non-PSNP as a matrix
								cap	mat	drop	AHCR_`k'_`year'
								mat	AHCR_`k'_`year'	=	AHCR_`k'_full_`year',	AHCR_`k'_nonpsnp_`year',	AHCR_`k'_psnp_`year'
							
						*	Restore specific year of observations only for non-pooled data (since it was preserved earlier)
						if	"`year'"!="pool"	{	
							restore
						}	//	if
						
						*	Append matrix over years
						mat	UHCR_`k'_all	=	nullmat(UHCR_`k'_all) \ UHCR_`k'_`year'
						mat	AHCR_`k'_all	=	nullmat(AHCR_`k'_all) \ AHCR_`k'_`year'
						
					}	//	year
					
					*	Append matrix over different K
					mat	UHCR_all	=	nullmat(UHCR_all), UHCR_`k'_all
					mat	AHCR_all	=	nullmat(AHCR_all), AHCR_`k'_all
				}	//	k
				
		*	Make matrices to be exported (Tale 4 in Nov 2023 draft)
		mat rownames	UHCR_all	=	2008	2010	2012	2014	Total
		mat rownames	AHCR_all	=	2008	2010	2012	2014	Total
		mat	colnames	UHCR_all	=	Full-sample	non-PSNP	PSNP	Full-sample	non-PSNP	PSNP	Full-sample	non-PSNP	PSNP
		mat	colnames	AHCR_all	=	Full-sample	non-PSNP	PSNP	Full-sample	non-PSNP	PSNP	Full-sample	non-PSNP	PSNP
	
	
		esttab matrix(UHCR_all, fmt(%9.2f)) using "${Output}/UHCR_all.tex", replace	
		esttab matrix(AHCR_all, fmt(%9.2f)) using "${Output}/AHCR_all.tex", replace	
		 
		 *	(2024-3-19) Full sample only, combining adjusted and unadjusted
			*	Retrieve "full" column only from the matrices above
			
			forval	k=1/3	{
				
				loc	colnum	=	3*(`k'-1)+1
				mat UHCR_`k'_full	=	UHCR_all[1..5,`colnum']
				mat AHCR_`k'_full	=	AHCR_all[1..5,`colnum']
			}
			
			mat	HCR_byyear_full	=	UHCR_1_full, UHCR_2_full, UHCR_3_full,	AHCR_1_full,	AHCR_2_full,	AHCR_3_full
			mat	list	HCR_byyear_full
			
			mat rownames	HCR_byyear_full	=	2008	2010	2012	2014	Total
			mat colnames	HCR_byyear_full	=	k=1	k=2	k=3	k=1	k=2	k=3
			
			esttab matrix(HCR_byyear_full, fmt(%9.2f)) using "${Output}/Final/Table2_Headcount_ratio_all.tex", replace	

	
	
	
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
				
				*	Generate a binary indicator if expenditure resilience is below 0.5
				*cap	drop	`var'_resil
				*gen		`var'_resil=.
				*replace	`var'_resil=0	if	!mi(`var'_resil_normal)	&	`var'_resil_normal<0.5
				*replace	`var'_resil=1	if	!mi(`var'_resil_normal)	&	`var'_resil_normal>=0.5
									
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
			
		
		*	Make it as figure
	
			lab	var	TLU_IHS_resil_normal_2	"TLU cutoff=2"
			lab	var	TLU_IHS_resil_normal_4	"TLU cutoff=4"
			lab	var	TLU_IHS_resil_normal_6	"TLU cutoff=6"
			
			lgraph 	TLU_IHS_resil_normal_2 TLU_IHS_resil_normal_4	TLU_IHS_resil_normal_6 round, errortype(iqr) separate(0.01) wide /*title(Univariate Resilience Dynamics)*/  bgcolor(white)	///
					graphregion(color(white))  yscale(range(0.5 1) titlegap(1)) 	ylabel(0.1(0.1)1) 	name(PFS_annual, replace) ytitle(Probability)	xtitle(Survey Round)	///
					legend(lab (1 "Consumption Expenditure") lab(2 "Dietary") lab(3 "Livestock")  rows(1) pos(6))	 ///
					note(Capped bars represent interquantile range)
			
			graph	export	"${Output}/Final/FigureA3_dietray_resil_dynamics_cutoffs.png", replace as(png)
			graph	close
		
		
	
	