	*	Set macro

		
		*global	statevar	l.HDDS	
		global	demovars	lnhead_age lnhead_age_sq	malehead	headnoed	maritals_m		hhsize	electricity	IHS_dist_nt
		global	econvars	occupation_non_farm		IHS_landaeu IHS_lvstk_real IHS_vprodeq_realaeu	 
		global	rainfallvar	ln_rf_annual
		global	programvars	c.psnp##c.OFSP_HABP	log_psnp
		global	dsvars		DS	lnDStotPayM_realpc
		global	dsvars_med	DS_belowmed DS_abovemed
		global	pwvars		PW	lnPWtotPayM_realpc
		global	communityvars	tarmac_rd  truckaccess_rd piped_water primschool2 healthpost	//	Some variables are not included since they are available only in certain years. (i.e. highschool1)
		global	year_FE		i.year	
		global	woreda_FE	i.woreda_id //	(2025-03-03) Exclude district-FE to address JDE 1st R&R (2025-5-8) Ra-added it.
		
		global	resil_RHS	${demovars}	${econvars}	${rainfallvar}	 ${year_FE}	 ${woreda_FE}	//		${communityvars}	//		 		(2025-3-6) Added to easily control model specifications
		
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

