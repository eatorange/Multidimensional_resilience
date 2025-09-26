
	/*****************************************************************
	PROJECT: 		Multidimensional Development Resilience
					
	TITLE:			Climate_cl
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Jun 15, 2025, by Seungmin Lee (slee76@nd.edu)
	
	IDS VAR:    	hhid round (Household ID-survey wave)

	DESCRIPTION: 	Prepare and clean climate data
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
						1	- Additional cleaning from the cleaned data
						

					X - Save and Exit
					
	INPUTS: 		
	
	OUTPUTS: 		

	NOTE:			File should run before running household survey cleaning and shapefile cleaning.
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
	loc	name_do	Climate_clean
	

	/****************************************************************
		SECTION 1: Additional cleaning from the cleaned data
	****************************************************************/	

	
	*	Ethiopia Shapefile

		cd	"${dtRaw}/Shapefiles"

		*	Convert shapefile into dta file
		*	Two dta files would be generated; attribute file and shape file
		spshape2dta "eth_admbnda_adm0_csa_bofedb_itos_2021.shp", replace saving(Eth_admin_lv0)
		spshape2dta "eth_admbnda_adm1_csa_bofedb_2021.shp", replace saving(Eth_admin_lv1)
		spshape2dta "eth_admbnda_adm2_csa_bofedb_2021.shp", replace saving(Eth_admin_lv2)
		spshape2dta "eth_admbnda_adm3_csa_bofedb_2021.shp", replace saving(Eth_admin_lv3)
		
		**	Merging is not working properly, since some woredas that are merged are not adjacent.
		**	As an alternative, we map PSNP woreda's resilience to multiple woredas in shapefile.
		
			use	Eth_admin_lv1, clear
			cap	drop	study_region
			gen		study_region=1	if	inlist(ADM1_EN,"Amhara")
			replace	study_region=2	if	inlist(ADM1_EN,"Oromia")
			replace	study_region=3	if	inlist(ADM1_EN,"SNNP")
			replace	study_region=4	if	inlist(ADM1_EN,"Tigray")
			lab	define	study_region	1	"Amhara"	2	"Oromia"	3	"SNNP"	4	"Tigray", replace
			lab	val	study_region	study_region
			save	Eth_admin_lv1,	replace
		
	
	*	Climate data
		
		*	Temperature
		*	Source: ERA5 Monthly Aggregates
		*	Link:	https://developers.google.com/earth-engine/datasets/catalog/ECMWF_ERA5_MONTHLY
		import delimited "${dtRaw}/Climate/eth_level3_jan85_dec14_temp.csv", clear
		rename	(sum	mean min max count)	(temp_total	temp_mean temp_min temp_max temp_count)

		*	Convert K to C
		replace	temp_total	=	temp_total	-	273.15
		replace	temp_mean	=	temp_mean	-	273.15
		replace	temp_min	=	temp_min	-	273.15
		replace	temp_max	=	temp_max	-	273.15
		
		drop	temp_total	temp_count //	we don't need it.
		
		*	Generate year, month and date
		gen year=substr(systemindex,1,4)
		gen month=substr(systemindex,5,2)

		*	Additional cleaning
		destring year month , replace
		order year month 
		drop	systemindex
		

		//lab	var	temp_total 	"Total (woreda) monthly temperature (C)"
		lab	var	temp_mean	"Average (woreda) monthly temperature (C)"
		lab	var	temp_min	"Minimum (woreda) monthly temperature (C)"
		lab	var	temp_max	"Maximum (woreda) monthly temperature (C)"

		tempfile	ERA5_temp
		save		`ERA5_temp'
		
		*	Precipitation
		*	Source: CHIRPS Pentag aggregated (mm/pentad)
		*	Link:	https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_PENTAD
			*	The pixel-level data are aggregated on Google Earth by admin unit, so I believe each variable is as below.
				*	count: Total number of pixels aggregated to compute woreda-level precipitation
				*	sum: Total precipitation (mm/pentad) per woreda 
				*	mean: Average pixel-level precipitation within woreda
				*	max: maximum pixel-level precipitation within woreda (precipitation from the pixel with the highest precipitation)
				*	min: maximum pixel-level precipitation within woreda (precipitation from the pixel with the lowest precipitation)
		import delimited "${dtRaw}/Climate/eth_level3_jan85_dec14_precip.csv", clear
		
			gen year=substr(systemindex,1,4)
			gen month=substr(systemindex,5,2)
			gen	day=substr(systemindex,7,2)
			
			*	Generate year, month and date
			destring year month day, replace
			order year month day
			drop	systemindex
			
			*	Computing total rainfall
			*	(2025-4-16) I have always been consufed with how to compute total rainfall per admin unit (woreda), from pixel-level pentad data
				*	(i) Should I compute total rainfall per pixel, and then "aggregate" all those rainfalls over pixels witn a unit?
				*	(ii) Should I compute total rainfall per pixe, and then "average" them within a unit?
				*	Based on what I have searched on the Internet, (ii) seems the correct choice
					*	Source 1: https://spatialthoughts.com/2020/10/28/rainfall-data-gee/
						*	Under "Calculating Total Rainfall In a Region", It says "Now that we have computed an Image with the total rainfall for each pixel, we can compute "average" total rainfall in any given geometry using reduceRegion() function."
					*	Source 2: ChatGPT; rainfall is "depth" of water, so calculating total depth isn't something meaningful
					
					/*
					When you see CHIRPS (or any gridded precipitation) in millimeters, you're looking at a depth of water over each pixel's area, not a "count" that you simply add up.

					Mean of pixels ⇒ the representative depth (mm) of rain over your admin unit.

					Sum of pixels ⇒ (depth × number_of_pixels) → yields mm × pixel_count, which doesn't correspond to a meaningful water‑depth.

				📐 Getting "Total" Water Volume vs. Depth

					Total Depth (mm) across the unit

						Conceptually, the average depth across all pixels is the depth that fell everywhere.

						So you use reduceRegions(..., ee.Reducer.mean()) on your summed‑over‑time precip image.

					Total Volume (e.g. cubic meters) of water that fell

						Convert each pixel's depth to a volume:

							volume_per_pixel = precipitation_mm × pixel_area_m²

						Then sum those volumes across all pixels in the admin unit:

							total_volume = ∑(volume_per_pixel)
					*/	
				
			*	Since we have "average pixel-level rainfall per pentad (mm/pentad) per woreda", "mean" variable as described above, we aggregate this over time to compute "average pixel-level rainfall per period (month, year, etc.)"
			*	Note that "sum" variable, total precipitation per woreda, isn't really meaningful as described on ChatGPT answer above.
			
		
		*	Since it is pentad data, we need to aggregate by month to merge it with temperatue data
		collapse (sum)  mean (min) min (max) max, by(year month adm3_pcode)	
		
		rename	(mean min max)	( rf_mean rf_min rf_max)
		
		*lab	var	rf_sum	"Total monthly rainfall at woreda (mm/month)"
		lab	var	rf_mean	"Average monthly rainfall (mm/month) - woreda level"
		lab	var	rf_min	"Minimum monthly rainfall (mm/month) - woreda level"
		lab	var	rf_max	"Maximum monthly rainfall (mm/month) - woreda level"
		

			
		tempfile	CHIRPS_precipitation
		save		`CHIRPS_precipitation'
		
		*	Merge with ERA temperature data
		use	`ERA5_temp', clear
		merge	1:1	year month adm3_pcode using `CHIRPS_precipitation' //, nogen assert(3)
		isid	year	month	adm3_pcode
		

			*	Save (including raw adm3_pcode)
			*	This file would be later used in mapping.
			preserve
				keep	adm1_en adm1_pcode adm2_en adm2_pcode adm3_en adm3_pcode shape_area shape_leng // adm3_pcode_raw
				duplicates drop
				save	"${dtInt}\AMD3_code_matching.dta", replace
			restore
			
			
				
		
		*	Collapse data to keep unique obs for new adm3_pcode per year-month
			*	It is still unclear how to collapse "rf_sum" (mean? sum?), but it is not used in final analyses so let's not worry about it.
		*	(2025-6-11) I no longer use "TEMP" mathcing, so disable it.
		/*
		preserve
			keep	if	inlist(adm3_pcode,"TEMP-001","TEMP-002","TEMP-003","TEMP-004","TEMP-005")
			collapse	(mean)	/*rf_sum*/	 rf_mean	temp_mean (max) temp_max rf_max (min) temp_min rf_min, by(year	month adm1_en adm1_pcode adm3_pcode)
			isid	year	month	adm3_pcode
			tempfile	Woreda_tobe_matched
			save		`Woreda_tobe_matched'
		restore
		drop	if	inlist(adm3_pcode,"TEMP-001","TEMP-002","TEMP-003","TEMP-004","TEMP-005")
		append	using	`Woreda_tobe_matched'
		*/
	
/*
	*	Construct deviation from 30-year average value
	gen	dev_rf_sum_30yravg	=	rf_sum	-	rf_sum_30yravg
	gen	dev_rf_mean_30yravg	=	rf_mean	-	rf_mean_30yravg
	gen	dev_temp_mean_3yravg	=	temp_mean	-	temp_mean_30yravg
	
	lab	var	dev_rf_sum_30yravg	"Deviation in total Meher rainfall"
	lab	var	dev_rf_mean_30yravg	"Deviation in average Meher rainfall"
	lab	var	dev_temp_mean_30yravg	"Deviation in average Meher temperature"
	
	summ	dev_rf_sum_30yravg	dev_rf_mean_30yravg	dev_temp_mean_30yravg
	
	tempfile	dev_30yravg
	save		`dev_30yravg'
*/
	
	*	Create time and date variables
	drop  date
	gen yearmonth=ym(year,month)
	format yearmonth %tm
	lab	var	yearmonth	"Year-month"
	encode	adm3_pcode, gen(adm3_pcode_num)
	
	*	Save
	compress
	save	"${dtInt}\Climate_intermediate.dta", replace
	
	*	Create yearly panel
	*	Since PSNP is yearly-data without month information, we need to use yearly panel to merge with PSNP data.
	
	*xtset	adm3_pcode_num year, yearly
	*xtset	adm3_pcode_num yearmonth , monthly // monthly panel
		
	
	*	Create variables of interest

	
		*	(1) Avg rainfall and temperature in the last 12 months
		*	Since PSNP data is yearly data, we cannot create year-month-specific variables.
			*	Note that "rf_mean" is currently "pixel-level average within an admin unit, aggregated over month". So we need to aggregate it over months in a year to compute "annual" rainfall
		use "${dtInt}/Climate_intermediate.dta", clear
		collapse	(sum)	/*rf_sum*/	rf_mean (mean) temp_mean (max) temp_max rf_max (min) temp_min rf_min, by(year adm1_en-shape_leng adm3_pcode_num)
		rename	(rf_mean) (rf_annual)
		lab	var	rf_annual	"Average annual rainfall this year (mm)"
		note rf_annual: woreda-level average rainfall aggregated over year
		
		*	Construct panel
		xtset	adm3_pcode_num year, yearly
		
		*	Construct lagged annual rainfall
		gen		past_rf_annual	=	l.rf_annual
		lab	var	past_rf_annual	"Annual annual rainfall in the previous year (mm/year)"
		note past_rf_annual: woreda-level average rainfall aggregated over previous year
		
		
		*lab	var	rf_sum 		"Total annual rainfall (mm)"
		lab	var	rf_annual 	"Total annual rainfall (mm)"
		lab	var	rf_max 		"Maximum annual rainfall (mm)"
		lab	var	rf_min 		"Minimum annual rainfall (mm)"
		lab	var	temp_mean 	"Average temperature(C)"
		lab	var	temp_min 	"Minimum temperature(C)"
		lab	var	temp_max 	"Maximum temperature(C)"
		
		tempfile	past_rf_annual
		save		`past_rf_annual'
		
/*
		collapse	(sum) rf_mean, by(year adm1_en-shape_leng adm3_pcode_num)
		rename		rf_mean	rf_annual	// I use "annual" for yearly rainfall, not to be consufed with "sum"
		lab	var		rf_annual	"Annual rainfall this year (mm/year)"
		note rf_annual: woreda-level average rainfall aggregated over year.
*/
		
			
		
		*	(2) Total rainfall in the meher season (May-September)
		use "${dtInt}/Climate_intermediate.dta", clear
		
			*	Keep only Meher season
			keep	if	inrange(month,5,9)
			
			*	Total rainfall over the Meher season
			collapse	(sum) /*rf_sum*/	rf_mean, by(year adm3_pcode_num)
			rename	(/*rf_sum*/		rf_mean)	(/*rf_sum_meher*/	rf_mean_meher)
			*lab	var	rf_sum_meher	"Total rainfall during Meher season (May-Sep) (mm)"
			lab	var	rf_mean_meher	"Average rainfall during Meher season (May-Sep) (mm/season)"
			*note rf_sum_meher: Monthly woreda-level total rainfall aggregated over meher season
			note rf_mean_meher: Monthly woreda-level mean rainfall aggregated over meher season
			
			*	Construct panel
			xtset	adm3_pcode_num year, yearly
			
			*	Construct lagged Meher rainfall
			*gen		past_rf_sum_meher	=	l.rf_sum_meher
			*lab	var	past_rf_sum_meher	"Total rainfall during Meher season (May-Sep) previous year (mm)"
			gen		past_rf_mean_meher	=	l.rf_mean_meher
			lab	var	past_rf_mean_meher	"Aveage rainfall during Meher season (May-Sep) previous year (mm/year)"
			
			tempfile	rf_meher
			save		`rf_meher'
			
		*	(3) Deviation in total rainfall and temperature from long-term average
		use "${dtInt}/Climate_intermediate.dta", clear
		
			*	Calculate 30-year (2005-2014) average
			collapse	(sum)	/*rf_sum*/	rf_mean (mean) temp_mean, by(year adm3_pcode_num)
			preserve
				collapse	(mean)	/*rf_sum*/ rf_mean	temp_mean, by(adm3_pcode_num)
				
				rename	(/*rf_sum*/	rf_mean	temp_mean)	(/*rf_sum_30yravg*/	rf_mean_30yravg	temp_mean_30yravg)
				
				*lab	var	rf_sum_30yravg		"30-year average total rainfall (mm) "
				lab	var	rf_mean_30yravg		"30-year average annual rainfall (mm)"
				lab	var	temp_mean_30yravg	"30-year average temperature (C)"
				
				tempfile climate_30yr_avg
				save `climate_30yr_avg'
			restore

			merge m:1 adm3_pcode_num using `climate_30yr_avg', nogen assert(3)
			
			*gen	dev_rf_sum_30yravg	=	rf_sum	-	rf_sum_30yravg
			gen	dev_rf_mean_30yravg	=	rf_mean	-	rf_mean_30yravg
			gen	dev_temp_mean_30yravg	=	temp_mean	-	temp_mean_30yravg
			
			*lab	var	dev_rf_sum_30yravg		"Deviation in total annual rainfall from 30-year average"
			lab	var	dev_rf_mean_30yravg		"Deviation in average annual rainfall from 30-year average"
			lab	var	dev_temp_mean_30yravg	"Deviation in average temperature from 30-year average"
			
			summ	/*dev_rf_sum_30yravg*/	dev_rf_mean_30yravg	dev_temp_mean_30yravg
			
			tempfile	dev_30yravg
			save		`dev_30yravg'
			
	
		
/*
	*	Construct yearly precipiation and temperature average data and merge the created variables
	use "E:\Dropbox\Multidimensional resilience\data_preparation\Climate\Climate_intermediate.dta", clear
	collapse	(sum)	rf_sum	rf_mean (mean) temp_mean (max) temp_max rf_max (min) temp_min rf_min, by(year adm1_en-shape_leng adm3_pcode_num)
	
		lab	var	rf_sum 		"Total annual rainfall (mm)"
		lab	var	rf_mean 	"Average annual rainfall (mm/woreda)"
		lab	var	rf_max 		"Maximum annual rainfall (mm/woreda)"
		lab	var	rf_min 		"Minimum annual rainfall (mm/woreda)"
		lab	var	temp_mean 	"Average temperature(C)"
		lab	var	temp_min 	"Minimum temperature(C)"
		lab	var	temp_max 	"Maximum temperature(C)"
*/
		
		
		*	Merge data
		use	`past_rf_annual', clear
		*merge	1:1	year	adm3_pcode_num	using	`past_rf_annual', nogen assert(3) keepusing(rf_annual past_rf_annual)
		merge	1:1	year	adm3_pcode_num	using	`rf_meher', nogen assert(3) keepusing(/*rf_sum_meher*/	rf_mean_meher	/*past_rf_sum_meher*/	past_rf_mean_meher)
		merge	1:1	year	adm3_pcode_num	using	`dev_30yravg', nogen assert(3) keepusing(dev*)
	
	
		*	Drop 2005
		drop	if year==2005
		
		clonevar	round=year
		
	*	Save
	compress
	save	"${dtInt}/Climate_cleaned.dta", replace
	
	
	
	*	Descriptive stats
	
		*	Annul precipitation and temperature
		use	"${dtInt}/Climate_cleaned.dta", clear
		collapse (mean) rf_annual temp_mean, by(year)
		graph twoway (line  temp_mean year, yaxis(1)) (connected rf_annual year, yaxis(2)), ytitle("Temperature (C)", axis(1)) ytitle("Rainfall (mm)", axis(2)) title(Annual temperature and rainfall) legend(label(1 "averarge temperature") label(2 "averarge rainfall"))
		graph	export	"${Output}/annual_temp_rainfall.png", as(png) replace
	
		/*
		*	Monthly precipitation and temperature
		use	"E:\Dropbox\Multidimensional resilience\data_preparation\Climate\Climate_intermediate.dta", clear
		collapse	(mean)	/*rf_sum*/	 temp_mean, by(month)
		graph twoway (line  temp_mean month, yaxis(1)) (connected /*rf_sum*/ month, yaxis(2)), ytitle("Temperature (C)", axis(1)) ytitle("Rainfall (mm)", axis(2)) title(Monthly temperature and rainfall) legend(label(1 "averarge temperature") label(2 "averarge rainfall"))
		graph	export	"${projectfolder}/results/monthly_temp_rainfall.png", as(png) replace
		*/
		
		*	Total rainfall (mm)
		use	"${dtInt}/Climate_cleaned.dta", clear
		collapse	(mean)	/*rf_sum_meher*/	rf_mean_meher , by(year)
		graph twoway (line  rf_mean_meher year, yaxis(1)), ytitle("Total rainfall (mm)", axis(1))  title(Total rainfall) legend(label(1 "total rainfall") )
		graph	export	"${Output}/total_meher_rainfall.png", as(png) replace
		
		*	Deviation from 10-year average
		use	"${dtInt}/Climate_cleaned.dta", clear
		collapse	(mean)	/*dev_rf_sum_30yravg*/	dev_rf_mean_30yravg dev_temp_mean_30yravg, by(year)
		graph twoway (line  dev_rf_mean_30yravg year, yaxis(1)) (connected dev_temp_mean_30yravg year, yaxis(2)), ytitle("Average rainfall (mm)", axis(1)) ytitle("Average temperature (C)", axis(2)) title(Deviation in meher rainfall and temperature from 10-year average ) legend(label(1 "avg rainfall") label(2 "avg temperature"))
		graph	export	"${Output}/dev_30yr_temp_rainfall.png", as(png) replace
		