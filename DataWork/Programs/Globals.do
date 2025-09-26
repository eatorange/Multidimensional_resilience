   * ******************************************************************** *
   *
   *       SET UP STANDARDIZATION GLOBALS AND OTHER CONSTANTS
   *
   *           - Set globals used all across the project
   *           - It is bad practice to define these at multiple locations
   *
   * ******************************************************************** *

   * ******************************************************************** *
   * Set all conversion rates used in unit standardization 
   * ******************************************************************** *

   **Define all your conversion rates here instead of typing them each 
   * time you are converting amounts, for example - in unit standardization. 
   * We have already listed common conversion rates below, but you
   * might have to add rates specific to your project, or change the target 
   * unit if you are standardizing to other units than meters, hectares,
   * and kilograms.

   *Standardizing length to meters
       global foot     = 0.3048
       global mile     = 1609.34
       global km       = 1000
       global yard     = 0.9144
       global inch     = 0.0254

   *Standardizing area to hectares
       global sqfoot   = (1 / 107639)
       global sqmile   = (1 / 258.999)
       global sqmtr    = (1 / 10000)
       global sqkmtr   = (1 / 100)
       global acre     = 0.404686

   *Standardizing weight to kilorgrams
       global pound    = 0.453592
       global gram     = 0.001
       global impTon   = 1016.05
       global usTon    = 907.1874996
       global mtrTon   = 1000

   * ******************************************************************** *
   * Set global lists of variables
   * ******************************************************************** *

   **This is a good location to create lists of variables to be used at 
   * multiple locations across the project. Examples of such lists might 
   * be different list of controls to be used across multiple regressions. 
   * By defining these lists here, you can easliy make updates and have 
   * those updates being applied to all regressions without a large risk 
   * of copy and paste errors.

       *Control Variables
       *Example: global household_controls       income female_headed
       *Example: global country_controls         GDP inflation unemployment
		global	demovars	lnhead_age lnhead_age_sq	malehead	headnoed	maritals_m		hhsize	electricity	IHS_dist_nt
		global	econvars	occupation_non_farm		IHS_landaeu IHS_lvstk_real IHS_vprodeq_realaeu	 
		global	rainfallvar	ln_rf_annual
		global	programvars	c.psnp##c.OFSP_HABP	log_psnp
		global	dsvars		DS	lnDStotPayM_realpc
		global	dsvars_med	DS_belowmed DS_abovemed
		global	pwvars		PW	lnPWtotPayM_realpc
		global	communityvars	tarmac_rd  truckaccess_rd piped_water primschool2 healthpost	//	Some variables are not included since they are available only in certain years. (i.e. highschool1)
		global	year_FE		i.year	
		global	woreda_FE	i.woreda_id 
		
		global	resil_RHS	${demovars}	${econvars}	${rainfallvar}	 ${year_FE}	 ${woreda_FE}	
		
		global	outcome_allexp	lnrexpaeu_peryear
		global	outcome_foodexp	lnrfdxpmaeu_peryear
		global	outcome_HDDS	HDDS
		global	outcome_TLU		TLU
		global	outcome_TLU_IHS	TLU_IHS
		
		global	outcome_measures	${outcome_allexp}	${outcome_HDDS}	${outcome_TLU_IHS}
		
		global	resil_normal		allexp_resil_normal  HDDS_resil_normal TLU_IHS_resil_normal 
		
		global	resil_normal_nooxen			allexp_resil_normal	HDDS_resil_normal	TLU_IHS_resil_normal
		
		
		global	bivariate_resil_measures	resil_uni_ae_HDDS	resil_uni_ae_TLU_IHS	resil_uni_HDDS_TLU_IHS		///
											resil_int_ae_HDDS	resil_int_ae_TLU_IHS	resil_int_HDDS_TLU_IHS	
											
		global	trivariate_resil_measure	resil_uni_ae_HDDS_TLU_IHS resil_int_ae_HDDS_TLU_IHS



   * ******************************************************************** *
   * Set custom adofile path
   * ******************************************************************** *

   **It is possible to control exactly which version of each command that 
   * is used in the project. This prevents that different versions of 
   * installed commands leads to different results.

	 global ado      "${dataWorkFolder}/ado"	
		
		*	Set "PLUS" directory where user-written commands are installed by Stata (ssc install, net install, etc.)
		*	I believe changing the directory is easier to control all ado-files used in this project.
		sysdir	set PLUS "${ado}"
	
		*	Set the directory where "ado" files are used.
        adopath ++  "${ado}" 
           *adopath ++  "$ado/m" 
           *adopath ++  "$ado/b" 
   
   * ******************************************************************** *
   * Install user-written commands
   * ******************************************************************** *
   
 
   * Install all packages that this project requires:
	*	Note that this never updates outdated versions of already installed commands.
	*	It is NOT recommended to update ado-file because of version control; the commands may not work under new version. But if update is needed, use "adoupdate"
   foreach	command	in	ietoolkit	univar	shapley2	winsor	estout	fre	tsspell	geoplot	moremata	palettes	colrspace	lgraph	{
		
		cap	which	`command'
		if	_rc==111	{
		
			ssc	install	`command', replace
		
		}
		
		
	}
	// net install sg162.pkg, replace	//	needed for spatial analysis

   
      

   * ******************************************************************** *
   * Anything else
   * ******************************************************************** *
   
   
   *Standardize settings accross users
   ieboilstart, version(18.0) maxvar(32767) matsize(11000)        //Set the version number to the oldest version used by anyone in the project team
   `r(version)'                        //This line is needed to actually set the version from the command above

	

   **Everything that is constant may be included here. One example of
   * something not constant that should be included here is exchange
   * rates. It is best practice to have one global with the exchange rate
   * here, and reference this each time a currency conversion is done. If 
   * the currency exchange rate needs to be updated, then it only has to
   * be done at one place for the whole project.

