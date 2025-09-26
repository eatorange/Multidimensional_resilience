   * ******************************************************************** *
   * ******************************************************************** *
   *                                                                      *
   *        		Multidimensional Development Resilience				  *
   *       	        MASTER DO_FILE                                        *
   *                                                                      *
   * ******************************************************************** *
   * ******************************************************************** *

       /*
       ** PURPOSE:      Replicate Analyses in Lee et al. (2025) JDE paper

       ** OUTLINE:      PART 0: Standardize settings and install packages
                        PART 1: Prepare folder path globals
                        PART 2: Run the master dofiles for each high-level task

       ** IDS VAR:      hhid      

       ** NOTES:

       ** WRITTEN BY:   Seungmin Lee

       ** Last date modified:  September 26, 2025
       */

*iefolder*0*StandardSettings****************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 0:  INSTALL PACKAGES AND STANDARDIZE SETTINGS
   *
   *           - Install packages needed to run all dofiles called
   *            by this master dofile.
   *           - Use ieboilstart to harmonize settings across users
   *
   * ******************************************************************** *

*iefolder*0*End_StandardSettings************************************************
*iefolder will not work properly if the line above is edited
	
	clear all
	macro	drop _all
	
  
*iefolder*1*FolderGlobals*******************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 1:  PREPARING FOLDER PATH GLOBALS
   *
   *           - Set the global box to point to the project folder
   *            on each collaborator's computer.
   *           - Set other locals that point to other folders of interest.
   *
   * ******************************************************************** *

   * Users
   * -----------

   * Root folder globals
   * ---------------------
   
   * Add local folder name of each collaborator.
   * `c(username)' is the system macro of STATA which has username
   * To find collaborator's user name, type -di "`c(username)'"- in STATA


   if "`c(username)'"== "Seungmin Lee" {	//	Min, Desktop
       global	projectfolder	"E:/GitHub/Multidimensional_resilience"		//	Github location
   }

   if "`c(username)'"== "ftac2" {	//	Min, personal laptop/desktop
       global	projectfolder	"E:/GitHub/Multidimensional_resilience"
   }
   
    if "`c(username)'"	==   "slee76" {	//	Min, UND work laptop
       global	projectfolder	"E:/GitHub/Multidimensional_resilience"
   }
    


* These lines are used to test that the name is not already used (do not edit manually)

   * Project folder globals
   * ---------------------

  global dataWorkFolder         "$projectfolder/DataWork"
   

*iefolder*1*FolderGlobals*master************************************************
*iefolder will not work properly if the line above is edited

  * global mastData               "$dataWorkFolder/MasterData" 

*iefolder*1*FolderGlobals*encrypted*********************************************
*iefolder will not work properly if the line above is edited

  // global encryptFolder          "$dataWorkFolder/EncryptedData" 

*iefolder*1*FolderGlobals*PSID**************************************************
*iefolder will not work properly if the line above is edited


   *DataSets sub-folder globals
	global DataSets         "${dataWorkFolder}/DataSets"
	global dtRaw			"$DataSets/Raw"
	global dtInt           	"$DataSets/Intermediate" 
	global dtFin          	"$DataSets/Final" 

   *Dofile sub-folder globals
	global Programs          "${dataWorkFolder}/Programs" 
	global doCln             "${Programs}/Cleaning" 
	global doCon             "${Programs}/Construct" 
	global doAnl             "${Programs}/Analysis" 
  	*global	data_analysis		 "${projectfolder}/data_analysis"

   *Output sub-folder globals
	global Output               "${dataWorkFolder}/Outputs" 


*iefolder*1*End_FolderGlobals***************************************************
*iefolder will not work properly if the line above is edited


*iefolder*2*StandardGlobals*****************************************************
*iefolder will not work properly if the line above is edited

   * Set all non-folder path globals that are constant accross
   * the project. Examples are conversion rates used in unit
   * standardization, different sets of control variables,
   * adofile paths etc.

   do "${Programs}/Globals.do" 


*iefolder*2*End_StandardGlobals*************************************************
*iefolder will not work properly if the line above is edited


*iefolder*3*RunDofiles**********************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 3: - RUN DOFILES CALLED BY THIS MASTER DOFILE
   *
   *           - A task master dofile has been created for each high-
   *            level task (cleaning, construct, analysis). By 
   *            running all of them all data work associated with the 
   *            PSID should be replicated, including output of 
   *            tables, graphs, etc.
   *           - Feel free to add to this list if you have other high-
   *            level tasks relevant to your project.
   *
   * ******************************************************************** *

   **Set the locals corresponding to the tasks you want
   * run to 1. To not run a task, set the local to 0.
   local importDo       0
   local cleaningDo     0
   local constructDo    0
   local analysisDo     0

   if (`importDo' == 1) { // Change the local above to run or not to run this file
       do "$PSID_doImp/PSID_import_MasterDofile.do" 
   }

   if (`cleaningDo' == 1) { // Change the local above to run or not to run this file
       do "$PSID_do/PSID_cleaning_MasterDofile.do" 
   }

   if (`constructDo' == 1) { // Change the local above to run or not to run this file
       do "$PSID_do/PSID_construct_MasterDofile.do" 
   }

   if (`analysisDo' == 1) { // Change the local above to run or not to run this file
       do "$PSID_do/PSID_analysis_MasterDofile.do" 
   }

*iefolder*3*End_RunDofiles******************************************************
*iefolder will not work properly if the line above is edited

