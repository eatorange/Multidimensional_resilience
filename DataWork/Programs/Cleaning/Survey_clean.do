
	/*****************************************************************
	PROJECT: 		Multidimensional Development Resilience
					
	TITLE:			Survey_cl
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Dec 6, 2022, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	hhid round (Household ID-survey wave)

	DESCRIPTION: 	Clean household survey
		
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
	loc	name_do	Survey_cl
	
		
	local	clean_var	1	//	Clean variables
		loc	de_identify	1	//	De-identify data
	local	gen_resil	1	//	Generate resilience measures
	local	eval_resil	0	//	Evaluate resilience measures


		
	/*
	local	data_analysis	0	//	data analysis
		local	spell_length	1	//	Spell length
		local	trans_matrix	1	//	Transition matrix
		local	test_stationary	0	//	Stationary test
		local	perm_approach	1	//	permanent apporach 
	*/
	
	/****************************************************************
		SECTION 1: Additional cleaning from the cleaned data
	****************************************************************/	

	
	*	Clean variables
	*local	clean_var	1

		
		
		if	`de_identify'==1	{
			
			use "${dtRaw}/PSNP/PSNP_social_protection_and_resilience_analysisdata.dta" ,	clear	//	Confidential data
			drop	Zone Wereda
			save	"${dtRaw}/PSNP/PSNP_social_protection_and_resilience_analysisdata_public.dta" ,	replace	//	De-identified data
			
			use	"${dtRaw}/PSNP/PSNP_geography_of_resilience_analysis.dta", clear
			drop	Zone Wereda	r_name	z_name	w_name	latitude	longitude
			save	"${dtRaw}/PSNP/PSNP_geography_of_resilience_analysis_public.dta" ,	replace	//	De-identified data
			
			use	"${dtRaw}/PSNP/PSNP_social_protection_and_resilience_analysisdata_public.dta" ,	clear	//	De-identified data
		}
		
		else	{
			
			use "${dtRaw}/PSNP/PSNP_social_protection_and_resilience_analysisdata.dta" ,	clear	//	De-identified data
		}

		
		isid	hhid	round	//	household ID and round of survey uniquely identifies observations

		*	Quick data overview
		ta year
		ta interviewed, missing	//	Min: What are missing obs? Do all missing obs imply they are not interviewed? 
		ta year interviewed, missing	//	Min: It seems the ratio of interview increases from 57% in 2006 to 82% in 2014

		
		xtset hhid year	//	panel data
		keep if interviewed==1	//	Keep interviewed households only
	
		*	Create variables

			*	IDs
			egen woreda_id		=	group( id01 id02 id03)
			egen village_num	=	group( id01 id02 id03 id04)

			*	Lagged treatment variable
			gen lagged_psnp		=	l.psnp	//	Received PW or DS payments 2 years ago 
		
			*	Farm worker
			gen		occupation_farm	=	1 if occupation==1	//	Farm worker
			replace occupation_farm	=	0 if occupation!=1
			lab	var	occupation_farm	"Main occupation farming"
			
			*	Non-farm worker
			gen		occupation_non_farm	=	1 if	occupation>=3 & occupation<=15
			replace occupation_non_farm	=	1 if 	occupation==21
			replace occupation_non_farm	=	0 if	occupation_non_farm!=1
			lab	var	occupation_non_farm	"Main occupation non-farming"
			
			ta occupation_non_farm
			
			*	PSNP Payment
			gen log_psnp=asinh(PSNPtotPayM_realpc)	//	Inverse hyperbolic transformation of PSNP payment amount (approximation of log and attain zero value)
			lab	var	log_psnp	"IHS (PSNP transfer per household member)"
			*gen clog_psnp=log_psnp-r(mean)
			
			*	Head's years of education (category)
			loc	var	educhead_cat
			cap	drop	`var'
			gen		`var'=0	if	inrange(educhead,0,0)
			replace	`var'=1	if	inrange(educhead,1,7)
			replace	`var'=2	if	inrange(educhead,8,11)
			replace	`var'=3	if	inrange(educhead,12,16)
			lab	define	`var'	0	"No education at all"	///
								1	"Less than elementary school"	///
								2	"Elementary school"	///
								3	"Secondary school or above"
			lab	val	`var'	`var'
			lab	var	`var'	"Head's education (category)"
			
			
			*	Distance
			*	Note: "lndist_nt", which was used in December draft, has negative values. Thus I also generate inverse hyperbolic sine transformation 
			gen lndist_nt=log(0.1+dist_nt)
			lab	var	lndist_nt	"ln(distance to the nearest town + 0.1)"
			
			gen	IHS_dist_nt	=	asinh(dist_nt)
			lab	var	IHS_dist_nt	"IHS (distance to nearest town)"
			
			*	Dinstance (category)
				loc	var	dist_nt_cat
				cap	drop	`var'
				gen		`var'=1	if	inrange(dist_nt,0,6.5)
				replace	`var'=2	if	inrange(dist_nt,7,12)
				replace	`var'=3	if	inrange(dist_nt,12.5,20)
				replace	`var'=4	if	inrange(dist_nt,20.5,155)
				lab	define	`var'	1	"Less than 6.5"	///
									2	"7 to 12"	///
									3	"12.5 to 20"	///
									4	"20.5 to 155"
				lab	val	`var'	`var'
				lab	var	`var'	"Distance to nearest town (category)"
			
			
			*	Marriage status	(Married)
			gen 	maritals_m=1 		if maritals==1 
			replace maritals_m=0	if maritals!=1 
			lab	var	maritals_m	"Household head Married"
			
			*	Initial sample (surveyed in 2006)
			loc	var	initial_sample
			cap	drop	`var'
			gen	`var'_temp=1	if	round==2006	&	interviewed==1
			bys	hhid:	egen	`var'=	max(`var'_temp)
			drop	`var'_temp
			lab	var	`var'	"HH initially surveyed in 2006"
			
			*	PSNP Graduation
			gen 	graduated=1 if m5q158n==1
			replace graduated=1 if m5q158n==3
			replace graduated=0 if m5q158n==2
			ta graduated
			lab	var	graduated "Household graduated PSNP"
			
			*	Age
			*	Generate (log(age))^2 (note: NOT log(age^2)) to capure non-linaer effect of age using log.
			cap	drop	lnhead_age_sq
			gen		lnhead_age_sq	=	(lnhead_age)^2
			lab	var	lnhead_age_sq	"(log(age))^2"
			*gen lnhead_age=log(head_age)
			
			*	Asset holding
			*	Note: "log" of some values below generate negative values, so I also generate inverse hyperbolic sine (IHS) transformation.
			gen llnvprodeq_real=log( vprodeq_realaeu )	//	"ln(productive asset value per adult)"
			gen lnvlvstk_real=log(vlvstk_real)	//	Log(livestock asset value, real)
					
			gen	IHS_landaeu			=	asinh(landaeu)
			gen	IHS_lvstk_real		=	asinh(vlvstk_real)
			gen	IHS_vprodeq_realaeu	=	asinh(vprodeq_realaeu)
			
			lab	var	lnlandaeu		"ln(farm size)"
			lab	var	lnvlvstk_real	"ln(livestock value per adult)"
			lab	var	llnvprodeq_real	"ln(productive asset value per adult)"
			
			lab	var	IHS_landaeu			"IHS (farm size)"
			lab	var	IHS_lvstk_real		"IHS (livestock value per adult)"
			lab	var	IHS_vprodeq_realaeu	"IHS (Productive asset value per adult)"
			
			*	Poverty line
			gen poverty_line=log(Absolute_PL)	//	Log(Absolute poverty line)
			lab	var	poverty_line	"ln(poverty line)"

			*	(Negative) Rainfall shock (z-score < -1)
				
				*	Less than -1
				loc	var	rainfall_neg1
				cap	drop	`var'
				gen		`var'=.	if	mi(rf_zscore)
				replace	`var'=0	if	!mi(rf_zscore)	*	rf_zscore>=-1
				replace	`var'=1	if	!mi(rf_zscore)	*	rf_zscore<-1
				lab	var	`var'	"Negative rainfall shock (z-score < -1)"
				
				*	Less than -2
				loc	var	rainfall_neg2
				cap	drop	`var'
				gen		`var'=.	if	mi(rf_zscore)
				replace	`var'=0	if	!mi(rf_zscore)	*	rf_zscore>=-2
				replace	`var'=1	if	!mi(rf_zscore)	*	rf_zscore<-2
				lab	var	`var'	"Negative rainfall shock (z-score < -2)"
			
			*	Program Participation
			xtset hhid year
			pctile pct_psnsp= PSNPtotPayM_realpc if psnp==1, nq(10)	//	Percentile of per capita PSNP payments
			gen 	PSNP_HABP=1 if psnp==1	&	OFSP_HABP==1	//	PSNP and HABP
			replace PSNP_HABP=0 if psnp==0	|	OFSP_HABP==0	
			gen 	lagged_PSNP_HABP=l.PSNP_HABP	//	Lagged PSNP and HABP
			lab	var	PSNP_HABP	"PSNP and HABP member household"
			
			*	Years of PSNP participation
			loc	var	PSNP_years
			cap	drop	`var'
			bys	hhid:	egen	`var'	=	total(psnp)
			lab	var	`var'	"\# of PSNP participation"
			
			*	Program participation (categorical variable)
			loc	var	PSNP_HABP_cat
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0	if	psnp==0	//	No PSNP participation
			replace	`var'=1	if	psnp==1	//	PSNP beneficiaries
			replace	`var'=2	if	OFSP_HABP==1	//	HABP beneficiaries
			replace	`var'=3	if	PSNP_HABP==1	//	PSNP	&	HABP beneficiaries
			
			lab	define	`var'	0	"Non-PSNP"	1	"PSNP only"	2	"HABP only"	3	"PSNP and HABP"
			lab	val	`var'	`var'
			
			lab	var	`var'	"PSNP and HABP status"
		
			*	Below/above Median PSNP transfer
			su PSNPtotPayM_realpc if psnp==1, d	//	Total per capita real PSNP payments
			return list
			gen medl = r(p50)	//	Median PSNP transfer
			
			su log_psnp if psnp==1, d
			return list
			gen med = r(p50)	//	Median log PSNP transfer

			
			loc	var	PSNP_median
			gen		`var'	=	0	if	psnp==0
			replace	`var'	=	1	if	psnp==1	&	PSNPtotPayM_realpc<medl
			replace	`var'	=	2	if	psnp==1	&	PSNPtotPayM_realpc>medl
			
			lab	define	`var'	0	"N/A"	1	"Below_median"	2	"Above_median"
			lab	val	`var'	`var'
			
			lab	var	`var'	"PSNP (above/below median)"
			
			*	tlu (IHS)
			loc	var	TLU_IHS
			cap	drop	`var'
			gen	`var'	=	asinh(tlu)
			lab	var	`var'	"IHS (Tropical Livestock Unit)"
			
			cap	drop	TLU_IHS_threshold
			gen	TLU_IHS_threshold	=	asinh(2)
			
			
			*	Number of Oxen
			*	Import from the existing data
			merge	1:1	hhid	round	using	"${dtRaw}/PSNP/PSNP_geography_of_resilience_analysis_public.dta", keepusing(No_Oxen) gen(NoOxen_merged) //assert(1 3)
			
			loc	var	Oxen2pl
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0	if	!mi(No_Oxen)	&	inrange(No_Oxen,0,1)
			replace	`var'=1	if	!mi(No_Oxen)	&	!inrange(No_Oxen,0,1)
			lab	var	`var'	"Has 2+ Oxen"
			
			*	Food secure months: 12 - food gap
			loc	var	fs_months
			cap	drop	`var'
			gen	`var'	=	12	-	fgap
			lab	var	`var'	"# of months w/o food shortage"
			note	`var': 12-fgap
			
			
			*	Replace outlying (top 1%) values as missing
			*	(2022-07-08) Originally this code was to winsorize, but Kibrom suggested to replace them with missing values.		
			foreach	var	in	pcfdxpm rfdxpmaeu_peryear tlu	{
				
				summ	`var',d
				replace	`var'=.	if	`var'>r(p99)
				
				*cap	drop	`var'_wins
				*winsor `var', gen(`var'_wins) p(0.01) highonly
				
			}
			
			
			*	(log) Food poverty line
			gen poverty_line_food=log(Food_PL + 1)	//	use the same formula per lnrfdxpmaeu_peryear, for consistency.
			
				 *	Indicator whether exp measures (overall exp, food exp) above correspoding poverty line.
				lab	define	above_PL	0	"Below PL"	1	"Above PL", replace
				
				loc	var	allexp_above_PL
				cap	drop	`var'
				gen		`var'=0	if	!mi(lnrfdxpmaeu_peryear)	&	lnrfdxpmaeu_peryear<poverty_line
				replace	`var'=1	if	!mi(lnrfdxpmaeu_peryear)	&	lnrfdxpmaeu_peryear>=poverty_line
				lab	var	`var'	"Household consumes above poverty line"
				lab	val	`var'	above_PL
				
				*	Poverty status changed
				sort	hhid	year
				loc	var	allexp_pov_change
				cap	drop	`var'
				gen		`var'=.
				replace	`var'=0	if	!mi(allexp_above_PL)	&	!mi(l.allexp_above_PL)
				replace	`var'=1	if	(allexp_above_PL==0	&	l.allexp_above_PL==1) | (allexp_above_PL==1	&	l.allexp_above_PL==0)
				lab	var	`var'	"Poverty status changed"

				
				loc	var	foodexp_above_PL
				cap	drop	`var'
				gen		`var'=0	if	!mi(lnrfdxpmaeu_peryear)	&	lnrfdxpmaeu_peryear<poverty_line_food
				replace	`var'=1	if	!mi(lnrfdxpmaeu_peryear)	&	lnrfdxpmaeu_peryear>=poverty_line_food
				lab	var	`var'	"Household food expenditure above food poverty line"
				lab	val	`var'	above_PL
				
			
			*	(IHS) per capita daily calories
			*	"lnpdcals" is a simple log function, having negative values which does not make sense
			*	Thus I create an IHS-version
			
				loc	var	log_pdcals
				cap	drop	`var'
				gen	`var'=asinh(pdcals)
				lab	var	`var'	"(IHS) Per Capita Daily Calories"
							
				*	Indicator if households consumes above 2100 cal
				loc	var	calories_above_2100
				cap	drop	`var'
				gen		`var'=0	if	!mi(pdcals)	&	pdcals<2100
				replace	`var'=1	if	!mi(pdcals)	&	pdcals>=2100
				lab	var	`var'	"=1 if HH per cacpity calories is no less than 2100"
			
			*	Share of food expenditure on total expenditure (couldn't find income, so use total expenditure as denominator instead)
				loc	var	share_foodexp_allexp
				cap	drop	`var'
				gen		`var'	=	rfdxpmaeu_peryear/rexpaeu_peryear
				lab	var	`var'	"(food exp/total exp)"
			
			*	Difference between threshold and outcome
			
				*	All expenditure gap	-	poverty line as threshold
				loc	var	all_exp_gap
				cap	drop	`var'
				gen		`var'=	(Absolute_PL	-	rexpaeu_peryear)/Absolute_PL
				replace	`var'=	0	if	`var'<=0
				lab	var	`var'	"All Expenditure Gap (AEG)"
				
				*	food expenditure gap - food poverty line as threshold
				loc	var	food_exp_gap
				cap	drop	`var'
				gen		`var'=0	if	foodexp_above_PL==1
				replace	`var'=	(Food_PL	-	rfdxpmaeu_peryear)/Food_PL	if	foodexp_above_PL==0
				lab	var	`var'	"Food Expenditure Gap (FAG)"
				
				*	food calorie gap (2,100 calories as threshold)
				loc	var	food_cal_gap
				cap	drop	`var'
				gen		`var'=	(2100	-	pdcals)/2100
				replace	`var'=	0	if	`var'<=0
				lab	var	`var'	"Food Calorie Gap (FGG)"
		
			*	For 2022 Nov version, I use all sample for summary stats
			cap	drop	rexpaeu_peryear_K
			cap	drop	vlvstk_K
			cap	drop	vprodeq_realaeu_K
			
			*	Unit in thousands
			gen	rexpaeu_peryear_K	=	rexpaeu_peryear	/	1000
			gen	vlvstk_K	=	vlvstk	/	1000
			
			*	PSNP amount per capita
			cap	drop	psnp_amt
			gen	psnp_amt	=	PSNPtotPayM_realpc
			replace	psnp_amt	=.	if	psnp!=1	//	replace as missing if non-beneficiaries
			lab	var	psnp_amt	"PSNP benefit amount per capita"
			
			* PSNP/DS/PW above/below median (use 2006 initial sample only)
				
				
				*	PSNP
				**	IMPORTANT: This variable is differnt from the original PSNP_median which uses all sample.
				loc	var	PSNP_median_2006
				cap	drop	`var'
				gen		`var'=0	if	DS==0
				summ	DStotPayM_real	if	DS==1	&	initial_sample==1,d
				replace	`var'=1	if	DS==1	&	DStotPayM_real<r(p50)
				replace	`var'=2	if	DS==1	&	DStotPayM_real>=r(p50)
				lab	var	`var'	"PSNP (above/below median) - 2006 initial sample"
				lab	val	`var'	PSNP_median
				
				
				*	Direct Transfer (DS)
				loc	var	DS_median
				cap	drop	`var'
				gen		`var'=0	if	DS==0
				summ	DStotPayM_real	if	DS==1	&	initial_sample==1,d
				replace	`var'=1	if	DS==1	&	DStotPayM_real<r(p50)
				replace	`var'=2	if	DS==1	&	DStotPayM_real>=r(p50)
				lab	var	`var'	"DS (above/below median)"
				lab	val	`var'	PSNP_median
				
				*	Public Work (PW)
				loc	var	PW_median
				cap	drop	`var'
				gen		`var'=0	if	PW==0
				summ	PWtotPayM_real	if	PW==1	&	initial_sample==1,d
				replace	`var'=1	if	PW==1	&	PWtotPayM_real>=r(p50)
				replace	`var'=2	if	PW==1	&	PWtotPayM_real<r(p50)
				lab	var	`var'	"PW (above/below median)"
				lab	val	`var'	PSNP_median
				
	
		
		*	Local polynomial graph of TLU and consumption
		*	Food expenditure and TLU has positive association since TLU>=2.5. I use it as the TLU threshold.
		twoway	 (lpolyci lnrexpaeu_peryear tlu if tlu<=15,	///
				bwidth (1) degree(1) legend(order(1  2 "Consumption expenditure")) /*title("Distribution of consumption expenditure over TLU", color(black))*/	///
				xline(2, lp(dash)lwidth(vthin)) xlabel(2 "TLU threshold (2)" 5 10 15) ytitle("log(consumption expenditure)") xtitle("TLU") note(Top 1 percentile (TLU>15) omitted)) 
		graph	export	"${results}/Allexp_TLU_lpoly.png", as(png) replace
		graph	close	
				
					
		forval	i=3/6	{
			
			cap	drop	HDDS_`i'			
			gen		HDDS_`i'	=	0
			replace	HDDS_`i'	=	1	if	HDDS>=`i'
			
			lab	var	HDDS_`i'	"HDDS >=`i'"
		}
		
			loc	var	TLU_6
			cap	drop	`var'
			gen		`var'=0	if	!mi(tlu)	&	tlu<6
			replace	`var'=1	if	!mi(tlu)	&	tlu>=6
			lab	var	`var'	"=1 if TLU>=6"
		
		*tab	HDDS, gen(HDDS)	
		
		
		*	Lagged vars
		sort	hhid	year
		foreach	var	in	lnrexpaeu_peryear	lnrfdxpmaeu_peryear	HDDS	tlu	lnrainfall	TLU_IHS	log_pdcals	fgap	fs_months	share_foodexp_allexp	{
			
			cap	drop	lag_`var'
			gen	lag_`var'	=	l.`var'
		}
		
				
		*	Clean key variable labels
		lab	var	rexpaeu_peryear		"Annual real consumption per aeu"
		lab	var	rfdxpmaeu_peryear	"Annual food consumption per aeu"
		lab	var	lnrexpaeu_peryear	"Log(consumption per adult)"
		lab	var	lnrfdxpmaeu_peryear	"Log(food consumption per adult)"
		lab	var	HDDS		"Household Dietary Diversity Score (HDDS)"
		lab	var	tlu			"Tropical Livestock Unit (TLU)"

		lab	var	malehead	"Male headed household"
		lab	var	head_age	"Age of household head"
		lab	var	headnoed	"Household head no education"
		lab	var	maritals_m	"Household head married"
		
		lab	var	landaeu		"Landholding per aeu (hectares)"
		lab	var	vprodeq_realaeu	"Production asset value per aeu"
		lab	var	vlvstk_K	"Value of livestock assets (K)"
		
		lab	var	lnhead_age		"Log(household head age)"
		lab	var	lnhead_age_sq	"Log(household head age) squared"
		lab	var	electricity		"Household has electricity access"
		lab	var	lag_lnrainfall	"Lagged rainfall"
		
		lab	var	psnp	"PSNP beneficiaries"
		lab	var	DS		"PSNP direct support (DS) beneficiaries"
		lab	var	PW		"PSNP public work (PW) beneficiaries"
		lab	var	OFSP_HABP	"HABP beneficiaries"
		lab	var	PSNP_HABP	"PSNP and HABP beneficiaries"
		
		lab	var	PSNPtotPayM_realpc	"PSNP transfer per capita"
		lab	var	log_psnp	"IHS (PSNP transfer per capita)"
		lab	var	lnPWtotPayM_realpc	"Log(PW transfer per capita)"
		lab	var	lnDStotPayM_realpc	"Log(DS transfer per capita)"
	
		lab	var	rf_mean		"(Mean) Rainfall in the past 12 months (2006 - 2014)"
		lab	var	rf_sd		"(Stdev) Rainfall in the past 12 months (2006 - 2014)"
		lab	var	rf_zscore	"(Z-score) Rainfall in the past 12 months (2006 - 2014)"
		lab	var	rainfall	"Total rainfall in the past 12 months"
		lab	var	lnrainfall	"(log) Total rainfall in the past 12 months"
		
		
		*	IMPORTANT (2023-2-4) For now, We use households initially surveyed in 2006 by dropping non-initinal sample, as John suggeseted
		*	We can recover them later if needed
		keep	if	initial_sample==1
		
		*	Import ERA5 weather data
			*	Prepare matching data
			*	We use Woreda spatial data shared by Kibrom, to match between ERA5 and PSNP data
			*	Source
				*	Data: https://github.com/Madaga-L/Ethiopia_Woredas_spatial_summaries/PSNP/woredas/modified2.csv
				*	Email: Multidimensional resilience/data_preparation/ERA5/woreda_spatial_matching_source.pdf
			preserve
				import delimited "${dtRaw}/Climate/PSNP_woredas_modified2.csv", varnames(1) clear 
				
				encode	id01, gen(id01_val)
				recode	id01_val	(1=3) (2=4) (3=7) (4=1)
				
				
				lab	define	adm1_code	1	"Tigray"	3	"Amhara"	4	"Oromiya"	7	"snnp", replace
				lab	val	id01_val	adm1_code
				drop	id01
				rename	id01_val	id01
				order	id01,	before(id02)
			
				tempfile	woreda_matching
				save		`woreda_matching'
			restore
		
			*	Import adm3 pcode
			merge 	m:1 id01 id02 id03 using `woreda_matching', assert(3) keepusing(adm3_pcode) nogen
			
			*	(2025-6-11) Replace specific woreda with those in shapefile
			*	Unlike previous code that changes woreda in the original shapefile, I change woreda in PSNP file to match with the shapefile
			*	The reason is to create a congruity matrix for spatial regression, where geolocations should be matched with those in shapefile.
			*	Not sure which match is right or wrong, as neither is perfect.
			*clonevar	adm3_pcode_raw	=	adm3_pcode
			
			
			*	Replace specific observations that are unmatched with modified pcode. (Check Climate.do for more detail)
			replace	adm3_pcode	=	"ET071403"	if	Wereda=="Alaba"			//	"Atote Ulo" in shapefile
			replace	adm3_pcode	=	"ET070205"	if	Wereda=="Badewacho"		//	"Misrak Badawacho" in shapefile
			replace	adm3_pcode	=	"ET070305"	if	Wereda=="Omo Sheleko"	//	"Hadero Tunto" in shapefile
			replace	adm3_pcode	=	"ET071303"	if	Wereda=="Konso"			//	"Karat Zuria" in shapefile	
			replace	adm3_pcode	=	"ET071505"	if	Wereda=="Gofa Zuria"	//	"Gezei Gofa" in shapefile
			
			*	Merge ERA5 data into PSNP data
			merge	m:1	round adm3_pcode using "${dtInt}/Climate_cleaned.dta",  /* nogen  */ keep(1 3) keepusing(rf_annual-dev_temp_mean_30yravg)
			assert	mi(Wereda) if _merge==1	//	All non-missing wereda (78 obs total) are matched (only missing wereda are unmatched)
			drop	if	_merge==1
			drop	_merge
		
		*	Log-tranform weather data
		gen	ln_rf_annual			=	ln(rf_annual)
		gen	ln_past_rf_total		=	ln(past_rf_annual)
		gen	ln_past_rf_meher		=	ln(past_rf_mean_meher)
		gen	ihs_dev_rf_mean_30yravg	=	asinh(dev_rf_mean_30yravg)
		
		lab	var	ln_rf_annual		"ln(Average annual rainfall (mm))"
		lab	var	ln_past_rf_total	"ln(Total rainfall in previous year (mm))"
		lab	var	ln_past_rf_meher	"ln(Average Meher rainfall in previous year)"
		lab	var	ihs_dev_rf_mean_30yravg	"IHS(Deviation in average annual rainfall from 30-year average)"
		
		*	Comparing rainfall (log) between the PSNP data and ERA5 data
		graph twoway (kdensity lnrainfall) (kdensity ln_past_rf_total), title(Log(rainfall) in the past year) legend(label(1 "PSNP data") label(2 "CHIRPS data"))
		graph	export	"${Output}/dist_rainfall_PSNP_CHIRPS.png", as(png) replace	
			
		*	(2025-03-03) Drop agro-pastoral zone (Bale and Borena), addressing John's comment on JDE 1st R&R
			drop if inlist(Zone,"Bale","Borena")	
			
		*	(2025-3-6) Recode missing community vars as zero
		foreach var of global communityvars	{
			
			replace	`var'=0	if	mi(`var')
			
		}
		
		
		*	Import latitude and longitude
		preserve
			
			*	We use two data to improt GPS coordinates
			*	(i)	"PSNP_geography_of_resilience_analysis.dta", since it has GPS-coordinates from the original PSNP data
		
			use	"${dtRaw}/PSNP/PSNP_geography_of_resilience_analysis.dta", clear
			keep	id01 id02 id03 Wereda longitude	latitude
			duplicates	drop
			isid	id01 id02 id03
			
			tempfile	PSNP_GPS_woreda
			save		`PSNP_GPS_woreda'

				
			*	(ii) GPS coordinate from shapefile,	"${projectfolder}/data_preparation/Climate/Shapefiles/Eth_admin_lv3", to fill in missing GPS coordinates in the first data above.
			use	"${dtRaw}/Shapefiles/Eth_admin_lv3",	clear
			drop	if	mi(ADM3_PCODE)
			rename	ADM3_PCODE	adm3_pcode
			
			clonevar	latitude=_CY
			clonevar	longitude=_CX
			
				*	Woreda's with "TEMP-xxx" has multiple GPS coordinates, as multiple woredas are assigned to such codes. I use the average GPS coordinates of them.
				*	Averaing shouldn't be a big issue here, as he only "TEMP-xxx" woredas with missing GPS coordinates are "TEMP-003" (Omo Sheleko). Two woredas with TEMP-003 have very similar geocodes
				*collapse (mean) latitude=_CY longitude=_CX, by(adm3_pcode)

			tempfile	admin_GPS_woreda
			save		`admin_GPS_woreda'
			
		restore	
		
		merge	m:1	id01 id02 id03 using `PSNP_GPS_woreda',	assert(2 3) keep(3) nogen //	All households in the study sample exist in PSNP geocode data
		merge	m:1	adm3_pcode	using	`admin_GPS_woreda', keepusing(latitude longitude _ID _CX _CY Shape_Leng	Shape_Area) update assert(2 4 5) keep(4 5) nogen	//	Import missing woreda's latitude/longitudes from admin GPS data
		assert	!mi(latitude)	&	!mi(longitude)
		
		lab	var	latitude	"Latitude"
		lab	var	longitude	"Longitude"

		*	Save
		compress
		save	"${dtInt}/PSNP_resilience_cleaned.dta", replace
		
