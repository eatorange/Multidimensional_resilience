
	
	
		
	*	Prepare matching data
	use	"${dtInt}/AMD3_code_matching.dta", clear	//	Generated in "Climate.do" file
	isid	adm3_pcode
	
		*	Expand it to make 5 obs per each woreda (4 rounds + 1 total)
		expand 5
		bys	adm3_pcode:	gen	round=_n
		recode	round	(1=2008) (2=2010) (3=2012) (4=2014)	(5=9999)
		
		tempfile	matching_byround
		save	`matching_byround',	replace
	
	*	Prepare PSNP file
	
		*	Woreda-average frame	
		use	"${dtInt}/PSNP_resilience_const.dta", clear
		drop	if	round==2006
		collapse	(mean)	psnp	rf_annual	tlu	${outcome_measures}	${resil_normal_nooxen}	${bivariate_resil_measures}	${trivariate_resil_measure}, by(Wereda adm3_pcode)	
		gen	round=9999	//	9999	stands for total
		tempfile	woreda_9999_avg	
		save		`woreda_9999_avg'
		
		*	Woreda-year-average 
		use	"${dtInt}/PSNP_resilience_const.dta", clear
		drop	if	round==2006
		collapse	(mean)	psnp	rf_annual	tlu	${outcome_measures}	${resil_normal_nooxen}	${bivariate_resil_measures}	${trivariate_resil_measure}, by(Wereda adm3_pcode	round)
		drop	if	round==2006
		append	using	`woreda_9999_avg'
		sort	Wereda round
		

	*	Merge with matching_byround data
	merge	1:m		adm3_pcode	round	using	`matching_byround',	assert(2 3)	nogen
	
		*	Additional cleaning to merge with shapefile
		rename	adm3_pcode	ADM3_PCODE	//	change raw variable name to be matched with shapefile
		save	"${dtInt}/adm3_matched.dta", replace
	
	*	Merge	with shapefile
	merge	m:1	ADM3_PCODE	using	"${dtRaw}/Shapefiles/Eth_admin_lv3", nogen	assert(3) 
	*keep	if	round==2008
	save	"${dtInt}/adm3_matched_shape", replace
	
	
	
	
	*	Create frames using "geoframe" (included in "geoplot" command)
	frame	reset
	*use		"${dtInt}/adm3_matched_shape", clear
	*frame	rename	default	PSNP_avg_all
	
		*	Each admin level (lv0 to lv3)
		*	(2024-6-30) If the code below shows an error message, run "ssc install moremata" (reference: https://www.statalist.org/forums/forum/general-stata-discussion/mata/1429962-error-istmt-3499-mm_root-not-found-when-finding-the-root-using-mm_root-command)
			*"_clean_empty():  3499  _mm_unique_tag() not found
               *<istmt>:     -  function returned error"
			   
		geoframe	create	admin0		using	"${dtRaw}/Shapefiles/Eth_admin_lv0", replace	shp("${dtRaw}/Shapefiles/Eth_admin_lv0_shp")	
		geoframe	create	admin1		using	"${dtRaw}/Shapefiles/Eth_admin_lv1", replace	shp("${dtRaw}/Shapefiles/Eth_admin_lv1_shp")	
		geoframe	create	admin2		using	"${dtRaw}/Shapefiles/Eth_admin_lv2", replace	shp("${dtRaw}/Shapefiles/Eth_admin_lv2_shp")	
		
		
		geoframe	create	admin3		using	"${dtRaw}/Shapefiles/Eth_admin_lv3", replace	shp("${dtRaw}/Shapefiles/Eth_admin_lv3_shp")	
		
		*	Admin 3 (per year), with PSNP data
		foreach	round	in	2008	2010	2012	2014	9999	{
			
			use	"${dtInt}/adm3_matched_shape", clear
			keep	if	round==`round'
			save	"${dtInt}/adm3_matched_shape_`round'", replace
		
			geoframe	create	PSNP_avg_`round'		using	"${dtInt}/adm3_matched_shape_`round'", replace	shp("${dtRaw}/Shapefiles/Eth_admin_lv3_shp")	
			
		}
		
		*	(2025-6-30) disable old code.
		/*
		foreach	year	in	2008	 2010	 2012	2014	9999  	{
					
			*loc	year=2008
		
			*	Create an emply frame
			cap	drop	PSNP_avg_`year'
			frame 	change	default
			cap	frame	drop	PSNP_avg_`year'
			frame	create	PSNP_avg_`year'
			frame	change	PSNP_avg_`year'
			
			use		"${dtInt}/adm3_matched.dta", clear
			keep	if	round==`year'
			
			save	"${dtInt}/PSNP_avg_`year'", replace
			
			*	Import _ID variable
			merge	1:1	ADM3_PCODE	using	"${dtRaw}/Shapefiles/Eth_admin_lv3", keepusing(_ID _CX _CY) assert(3) nogen
			
			geoframe	create	PSNP_avg_`year'	using	"${dtInt}/PSNP_avg_`year'", ///
				replace	shp("${dtRaw}/Shapefiles/Eth_admin_lv3_shp")		//	Created frame overwrites current frame, unless "nocurrent" is specified.
			*erase	"${dtInt}/PSNP_avg_`year'.dta"
		}
		*/
		
	*	Plot maps
	
		*	Study region
		frame change admin1
		geoplot	(area	admin1	i.study_region,	color(viridis) label() missing(nolabel)) (line admin1, lc(black) lw(0.2))	(line admin0, lc(black) lw(0.2)),	///
			title("Study region", size(6) span) 
		graph	export	"${Output}/Study_region.png", as(png) replace
		graph	close
		
		
		global	title2008	2008
		global	title2010	2010
		global	title2012	2012
		global	title2014	2014
		global	title9999	2008-2014
		
		
		*	PSNP Participation rate
		
			*	Over years
			foreach	year	in	2008	2010	2012	2014	9999	{
				
				*loc	year=2008
				geoplot	(area	PSNP_avg_`year'	psnp, cuts(0(0.1)1)	color(viridis)	label("@lb - @ub", format(%12.2f)) missing(nolabel) ) 	(line admin1, lc(blue) lw(0.1) ) 	(line admin0, lc(black) lw(0.2)), ///
				clegend(pos(2)) zlabel(0(0.2)1) title("PSNP Participation Rate, ${title`year'}", size(6) span)
				graph	export	"${Output}/PSNP_rate_${title`year'}.png", as(png) replace
				graph	close
			}
			
		*	Rainfall
		
			*	Over years
			foreach	year	in	2008	2010	2012	2014	9999	{
				
				
				geoplot	(area	PSNP_avg_`year'	rf_annual, cuts(0(200)2000)	color(viridis)	label("@lb - @ub", format(%12.2f)) missing(nolabel) ) 	(line admin1, lc(blue) lw(0.1) ) 	(line admin0, lc(black) lw(0.2)), ///
				clegend(pos(2)) zlabel(0(200)2000) title("Annual Rainfall (mm), ${title`year'}", size(6) span)	name(psnp`year', replace)
				
				graph	export	"${Output}/rf_annual_${title`year'}.png", as(png) replace
				graph	close
			}
			
		*	HDDS
		
			*	Over years
			foreach	year	in	2008	2010	2012	2014	9999	{
				
				geoplot	(area	PSNP_avg_`year'	tlu, cuts(0(1)10)	color(viridis)	label("@lb - @ub", format(%12.2f)) missing(nolabel) ) 	(line admin1, lc(blue) lw(0.1) ) 	(line admin0, lc(black) lw(0.2)), ///
				clegend(pos(2)) zlabel(#10) title("Household Dietary Diversity Score, ${title`year'}", size(6) span)	name(HDDS`year', replace)
				graph	export	"${Output}/HDDS_${title`year'}.png", as(png) replace
				graph	close
			}
		
		*	TLU
		
			*	Over years
			foreach	year	in	2008	2010	2012	2014	9999	{
				
				geoplot	(area	PSNP_avg_`year'	tlu,	cuts(0(1)10)	color(viridis)	label("@lb - @ub", format(%12.2f)) missing(nolabel) ) 	(line admin1, lc(blue) lw(0.1) ) 	(line admin0, lc(black) lw(0.2)), ///
				clegend(pos(2)) zlabel(#10) title("Tropical Livestock Unit, ${title`year'}", size(6) span)	name(tlu`year', replace)
				graph	export	"${Output}/TLU_${title`year'}.png", as(png) replace
				graph	close
			}
		
	
		*	Consumpetion expenditure resilience
		*	(2024-7-25) Plot pooled years separately
		
			*	Over years
			foreach	year	in	2008	2010	2012	2014	/* 9999 */	{
				
				geoplot	(area	PSNP_avg_`year'	allexp_resil_normal, cuts(0(0.1)1)	color(viridis)	label("@lb - @ub", format(%12.2f)) missing(nolabel)) 	(line admin1, lc(blue) lw(0.1) ) 	(line admin0, lc(black) lw(0.2)), ///
				clegend(pos(2)) zlabel(0(0.2)1)	title("${title`year'}", size(6) span)	name(ceresil`year', replace)
				graph	export	"${Output}/CE_resil_${title`year'}.png", as(png) replace
				graph	close
			}
				
				*	Combine all years, to be included in the appendix
				graph	combine	ceresil2008	ceresil2010	ceresil2012	ceresil2014/*,	title(Annual CE Resilience by Woreda)*/
				graph	export	"${Output}/Final/FigureA4_CE_resil_by_woreda_year.png", as(png) replace
				graph	close
				
		*	Dietary resilience
		
			*	Over years
				foreach	year	in	2008	2010	2012	2014	/* 9999 */	{
				
				geoplot	(area	PSNP_avg_`year'	HDDS_resil_normal,  cuts(0(0.1)1)	color(viridis)	label("@lb - @ub", format(%12.2f)) missing(nolabel)) 	(line admin1, lc(blue) lw(0.1) ) 	(line admin0, lc(black) lw(0.2)), ///
				clegend(pos(2)) zlabel(0(0.2)1)	 title("${title`year'}", size(6) span)	name(dietresil`year', replace)
				graph	export	"${Output}/Dietary_resil_${title`year'}.png", as(png) replace
				graph	close
			}
			
				*	Combine all years, to be included in the appendix
				graph	combine	dietresil2008	dietresil2010	dietresil2012	dietresil2014/*,	title(Annual Dietary Resilience by Woreda)*/
				graph	export	"${Output}/Final/FigureA5_Dietary_resil_by_woreda_year.png", as(png) replace
				graph	close
				
		*	Livestcok resilience
	
			*	Over years
				foreach	year	in	2008	2010	2012	2014	/* 9999 */	{
				
				geoplot	(area	PSNP_avg_`year'	TLU_IHS_resil_normal,  cuts(0(0.1)1)	color(viridis)	label("@lb - @ub", format(%12.2f)) missing(nolabel)) 	(line admin1, lc(blue) lw(0.1) ) 	(line admin0, lc(black) lw(0.2)), ///
				clegend(pos(2)) zlabel(0(0.2)1)	 title("${title`year'}", size(6) span)	name(lstresil`year', replace)
				graph	export	"${Output}/Livestock_resil_${title`year'}.png", as(png) replace
				graph	close
				
			}
			
			*	Combine all years, to be included in the appendix
				graph	combine	lstresil2008	lstresil2010	lstresil2012	lstresil2014/*,	title(Annual Livestock Resilience by Woreda)*/
				graph	export	"${Output}/Final/FigureA6_Livestock_resil_by_woreda_year.png", as(png) replace
				graph	close
			
		*	All resilience, pooled
				
				global	titleallexp		Consumption Expenditure	
				global	titleHDDS		Dietary
				global	titleTLU_IHS	Livestock
				
				foreach	type	in	allexp	HDDS	TLU_IHS	{
						
					geoplot	(area	PSNP_avg_9999	`type'_resil_normal,  cuts(0(0.1)1)	color(viridis)	label("@lb - @ub", format(%12.2f)) missing(nolabel)) 	(line admin1, lc(blue) lw(0.1) ) 	(line admin0, lc(black) lw(0.2)), ///
					clegend(pos(2)) zlabel(0(0.2)1)	 title("${title`type'}", size(6) span)	name(`type'resil9999, replace)
					graph	export	"${Output}/`type'_resil_0814.png", as(png) replace
					graph	close
					
				}
				
			
				
			*	Combine 3 resilience graphs
			graph	combine	allexpresil9999	HDDSresil9999	TLU_IHSresil9999/*,	title(Resilience by woreda)*/
			graph	export	"${Output}/Final/Figure5_resil_by_woreda_0814.png", as(png) replace
			graph	close
		
/*
	
	*	Merge certain woredas
	*	Guide: https://www.statalist.org/forums/forum/general-stata-discussion/general/1521655-merging-two-provinces-into-one-while-working-with-maps-shapefile
	use	"Eth_admin_lv3.dta", clear

	br	if	inlist(ADM3_EN,"Mirab Badowach","Misrak Badawacho")
	keep	if	inlist(ADM3_EN,"Mirab Badowach","Misrak Badawacho")
	gen	long	_IDAlaba	=	9995
	isid _ID, sort
	list	_IDAlaba	_ID	ADM3_EN
	save	"Woreda_Alaba.dta", replace
	
	mergepoly	using	"Eth_admin_lv3_shp.dta", coor("Woreda_Alaba_coor.dta") replace
	save "Woreda_Alaba_db.dta", replace
	
	use	"Eth_admin_lv3.dta", clear
	merge 1:1 _ID using "Woreda_Alaba.dta", keep(master) nogen	//	drop sub-woreda to be merged.
	
	* append the single database record for the midwest and save the new combo db
	append using "Woreda_Alaba_db.dta"
	replace _ID = _IDAlaba if !mi(_IDAlaba)
	replace ADM3_EN = "Alaba" if !mi(_IDAlaba)
	isid _ID, sort
	save "adm3_+_Alaba.dta", replace
	
	
	* adjust the midwest coor identifier to match and append to US coor
	use "Woreda_Alaba_coor.dta", clear
	replace _ID = 9999
	gen long shape_order = _n
	save "Woreda_Alaba_coor.dta", replace
	
	use	"Eth_admin_lv3_shp.dta", clear
	append	using	"Woreda_Alaba_coor.dta"
	sort	_ID	shape_order
	save	"adm3_+_Alaba_coor.dta", replace
	
	
	geo2xy _Y _X, replace projection(albers)
	save	"adm3_+_Alaba_coor_XY.dta", replace
	
	
	use "adm3_+_Alaba.dta", clear
	keep	if	_ID==828
	spmap	using	"adm3_+_Alaba_coor_XY.dta", id(_ID)
*/