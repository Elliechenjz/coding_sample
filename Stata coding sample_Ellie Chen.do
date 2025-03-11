
* Author: Ellie Chen
* Date: Jan 2025
* Purpose: Stata coding sample

/*

Dear Professionals,

Thank you for reviewing my STATA coding sample submission. This submission 
comprises two recent rojects, both of which I assert as 
original, representing my own work and no one else's.

PROJECT 1: Leaf Color Charts (LCC) Scaling Pilot - Engagement Statistics 
	
PROJECT 2: Regression Analysis for LCC evaluation Fertilizer Survey


Best regards,
Ellie Chen

(echen.prf@gmail.com)

*/

******PROJECT 1*******

		** Goal: LCC scaling: engagement statistics
		** Author: Ellie Chen
		** Date: 21 Aug, 2024
		**************************************************************************
		clear all

		local user = 1
		if `user'==1 {
			global main "/Users/elliechen/Library/CloudStorage/GoogleDrive-echen@precisiondev.org/.shortcut-targets-by-id/1D-OD8AWdh5W129DnRHmfYCoGUgJTI-3I/LCC Master Folder/Aii LCC Implementation /Maha scaling pilot /Advisory/Engagement data analysis"
			global raw_data "${main}/raw data"
			global final_roster "/Users/elliechen/Library/CloudStorage/GoogleDrive-echen@precisiondev.org/.shortcut-targets-by-id/1D-OD8AWdh5W129DnRHmfYCoGUgJTI-3I/LCC Master Folder/Aii LCC Implementation /Maha scaling pilot /Monitoring/Farmer distribution survey/"

		} 
		if `user'==2 {
			global main "PUT YOUR PATH HERE"
		}

			* ~~~~~~~~~~~~~~~~~~~~~
			* Combine risk and benefit
			* ~~~~~~~~~~~~~~~~~~~~~
			/*
			import delimited using "${raw_data}/LCCscaling_Risksbenefits_list_1.csv", clear
				tempfile rb1
				save `rb1'
				
			import delimited using "${raw_data}/LCCscaling_Risksbenefits_list_2.csv", clear
			
			append using `rb1'
			
			export delimited "${raw_data}/LCCscaling_Risksbenefits.csv", replace
			*/
			
			* ~~~~~~~~~~~~~~~~~~~~~
			* Engagement stats
			* ~~~~~~~~~~~~~~~~~~~~~
			local datasets "LCCscaling_BasalUrea LCCscaling_Fieldfeedback LCCscaling_LCCreminder LCCscaling_LCCuseprocess LCCscaling_Risksbenefits LCCscaling_LCCreminder_0812 LCCscaling_LCCreminder_0827 LCCscaling_LCCnudge_Sep25th LCCscaling_LCCreminder_Sep26th LCCscaling_LCCstorage_Oct22"
			local counter = 1

			foreach dataset in `datasets' {
				* Import the dataset
				import delimited using "${raw_data}/`dataset'.csv", clear
				
				gen message_N = `counter'
				local counter = `counter' + 1
				
				* Housekeeping
				gsort phone_number attempt_number
				bysort phone_number: egen attempt_max = max(attempt_number)
				gen last_attempt = (attempt_max == attempt_number)
			 
				
				* eliminate duplicates in RiskBenefits
				bysort phone_number (sent_on): gen seq_survey = _n
				
				bysort phone_number (seq_survey): keep if _n == _N
				
				
				* Count total attempts
				count
				
				* Count the number of targeted farmers
				count if last_attempt == 1
				
				* Count reached farmers
				tab delivery_status if last_attempt == 1
				count if last_attempt == 1 & delivery_status == "Reached"
				
				* Average attempts for reaching
				tab attempt_number if last_attempt == 1 & delivery_status == "Reached"
				sum attempt_number if last_attempt == 1 & delivery_status == "Reached" 
				
				*  listening %
				egen length_message = max(duration)
				gen pct_listen = duration/length_message
				
				sum pct_listen if last_attempt == 1 & delivery_status == "Reached"
				
				* drop the "'+91"
				replace phone_number = subinstr(phone_number, "'+91", "", .)
			
				* save 
				save "${raw_data}/`dataset'_processed.dta",replace
				
				keep if last_attempt == 1
			
				tempfile `dataset'
				save ``dataset''
				
				
			}

		* SUMMARY starts 

			* ~~~~~~~~~~~~~~~~~~~~~
			* REPORT - aggregate 
			* ~~~~~~~~~~~~~~~~~~~~~
		preserve 
			
			merge 1:1 phone_number using `LCCscaling_BasalUrea'
				rename _merge _merge1
			merge 1:1 phone_number using `LCCscaling_Fieldfeedback'
				rename _merge _merge2
			merge 1:1 phone_number using `LCCscaling_LCCreminder'
				rename _merge _merge3
			merge 1:1 phone_number using `LCCscaling_LCCuseprocess'
				rename _merge _merge4
			merge 1:1 phone_number using `LCCscaling_Risksbenefits'
				rename _merge _merge5
			merge 1:1 phone_number using `LCCscaling_LCCreminder_0812'
				rename _merge _merge6
			merge 1:1 phone_number using `LCCscaling_LCCreminder_0827'
				rename _merge _merge7
			merge 1:1 phone_number using `LCCscaling_LCCnudge_Sep25th'
				rename _merge _merge8
			merge 1:1 phone_number using `LCCscaling_LCCreminder_Sep26th'
				rename _merge _merge9
			* count the unique farmers ever reached 
			count 
			unique phone_number
		restore 

			* ~~~~~~~~~~~~~~~~~~~~~
			* REPORT - aggregate 
			* ~~~~~~~~~~~~~~~~~~~~~
			use "`LCCscaling_BasalUrea'", clear
			safeappend using "`LCCscaling_Fieldfeedback'"
			safeappend using "`LCCscaling_LCCreminder'"
			safeappend using "`LCCscaling_LCCuseprocess'"
			safeappend using "`LCCscaling_Risksbenefits'"
			safeappend using "`LCCscaling_LCCreminder_0812'"
			safeappend using "`LCCscaling_LCCreminder_0827'"
			safeappend using "`LCCscaling_LCCreminder_Sep26th'"
			safeappend using "`LCCscaling_LCCnudge_Sep25th'"
			safeappend using "`LCCscaling_LCCstorage_Oct22'"
			
			unique phone_number
			


		*----add a graph here for cluster-wise pick-up and listening rate
			* ~~~~~~~~~~~~~~~~~~~~~
			* Graph 1 (line graph): 
				* X axis- Cluster names
				* Y axis- Pick up rate, Listening rate
			* ~~~~~~~~~~~~~~~~~~~~~
			merge m:1 phone_number using "${final_roster}/Final_LCCdistributionrawdata_Aug8th2024_cleaned.dta"
			drop if missing(Location)
			
			gen pickup = (delivery_status == "Reached")
			* keep if pickup == 1
				* ----- by Location 
			preserve
				bysort phone_number message_N (sent_on): gen seq_reach = _n
				order phone_number message_N seq_reach
				keep if seq_reach == 1  // keep the unique farmer visited
				tab Location
				
				 
					bysort phone_number: gen seq_reach2 = _n
					order phone_number message_N seq_reach2
					keep if seq_reach2 == 1 
					* Cluster-wise break up of unique farmers reached
					tab Location
				restore
				
				
				* -----

			preserve
			collapse (mean) pickup, by(Location)
				list	
					tempfile pickuprate
						save `pickuprate'
			restore 
			
			preserve 
				keep if delivery_status == "Reached"
				collapse (mean) pct_listen, by(Location)
				
				list
					tempfile pct_listen
						save `pct_listen'
			
			merge 1:1 Location using `pickuprate'
			
			* Generate a two-way bar chart
			graph bar pickup pct_listen, over(Location, label(angle(45) labsize(small))) ///
			 title("Pick-up and listening rates by Cluster", size(large)) ///
			 ytitle("Rates") ylabel(0(0.1)0.9) ///
			 b1title("Clusters") ///
			 blabel() ///
			 legend(rows(1) pos(1) ring(0) label (1 "Pick up Rates") label(2 "Listening Rates")) ///
			 scheme(plotplain) 
			 
			restore
			
		*----
			
			* count number of unique message sent 
			count 
			* averge pick up rate across messages
			encode delivery_status, gen(delivery)
			
			preserve
				 collapse (count) delivery, by(delivery_status)
				 egen total_N = sum(delivery)
				 gen pick_up_rate = delivery/total_N if delivery_status == "Reached"
				 list pick_up_rate if delivery_status == "Reached"
			restore
			
			* average listening rate
			preserve 
				collapse (mean) pct_listen if delivery == 3
				list
			
			restore

*****PROJECT 1 END ******




*****PROJECT 2******

	*PURPOSE	 : Fertilizer use survey: Regression analysis  
	*AUTHOR		 : Ellie Chen
	*DATE		 : Jan 11, 2025

	*=====================================================
	********************** Globals *****************************************
	clear all

	local user = 1
	if `user'==1 {
		global main "/Users/elliechen/Library/CloudStorage/GoogleDrive-echen@precisiondev.org/.shortcut-targets-by-id/1D-OD8AWdh5W129DnRHmfYCoGUgJTI-3I/LCC Master Folder/Wellspring LCC Evaluation Implementation/Experiment 1/3. Data Collection/16. Fertilizer and input use survey/2. Data/01_raw"
	} 
	if `user'==2 {
		global main "PUT Jagori's PATH HERE"
	}
	if `user'==3 {
		global main "PUT Claudia's PATH HERE"
	}

	global today :	display %tdCCYYNNDD date(c(current_date),"DMY")
	global fertilizer_survey_v3 "$main/20241203_Fertilizer Use Survey RK_Version3(03_December)_WIDE.dta"
	global fertilizer_survey_v4 "$main/20250116_Soil Fertility Maharashtra Fertilizer Use Survey V4 (Dec 18).dta"

	***********
	* Merge for sections
	***********
	use "$fertilizer_survey_v3", clear
	keep farmer_id b3 z1 z2 v* w* x* y* 

	drop if b3 == ""
	bysort farmer_id: gen dup = _n
	drop if dup == 2

	drop v262-v2363

	* match the variable types
		replace b3 = "1" if b3 == "Yes"
		destring b3, replace
		
		replace v3 = "1" if v3 == "Yes"
		destring v3, replace
		
		destring v4, replace 
		destring v41, replace
		destring v5, replace 
		destring v51, replace
		destring v7, replace 
		destring v8, replace
		destring z2, replace
		
		replace v10 = "998" if v10 == "other"
		destring v10, replace
		replace v11 = "998" if v11 == "other"
		destring v11, replace
		replace v12 = "998" if v12 == "other"
		destring v12, replace
		replace z1 = "1" if z1 == "Yes"
		destring z1, replace
		
		label values v6
		label values v9
		label values w1


	foreach var of varlist * {
		capture confirm string variable `var'
		if _rc == 0 { // Proceed if it is a string variable
			quietly {
				// Count unique values
				levelsof `var', local(vals) clean

				if "`vals'" == "No Yes" | "`vals'" == "Yes No" | "`vals'" == "Yes" | "`vals'" == "No"{
					replace `var' = cond(`var' == "Yes", "1", cond(`var' == "No", "0", `var'))
					
					destring `var', replace
					
					label define yesno 0 "No" 1 "Yes", replace
					label values `var' yesno
				}
			}
		}
	}

	foreach var of varlist * {
		capture confirm string variable `var'
		if _rc == 0 { // Proceed if it is a string variable
			quietly {
				levelsof `var', local(vals) clean
				if "`vals'" == "0 1" | "`vals'" == "1 0" | "`vals'" == "1" | "`vals'" == "0" {
					destring `var', replace
				}
			}
		}
	}




		tempfile  v3
		save `v3'


		use "$fertilizer_survey_v4", clear
		keep farmer_id b3 z1 z2 v* o_v* w* x* y* 
		replace z1 = "Yes" if z1 == "1"
		replace z1 = "No" if z1 == "2"
		replace b3 = "Yes" if b3 == "1"
		replace b3 = "No" if b3 == "2"

		bysort farmer_id b3: gen dup2 = _n
		keep if b3 == "Yes"
		drop if dup2 == 2

		foreach var of varlist * {
			capture confirm string variable `var'
			if _rc == 0 { // Proceed if it is a string variable
				quietly {
					// Count unique values
					levelsof `var', local(vals) clean

					if "`vals'" == "No Yes" | "`vals'" == "Yes No" | "`vals'" == "Yes" | "`vals'" == "No"{
						replace `var' = cond(`var' == "Yes", "1", cond(`var' == "No", "0", `var'))
						
						destring `var', replace
						
						label define yesno 0 "No" 1 "Yes", replace
						label values `var' yesno
					}
				}
			}
		}

		foreach var of varlist * {
			capture confirm string variable `var'
			if _rc == 0 { // Proceed if it is a string variable
				quietly {
					levelsof `var', local(vals) clean
					if "`vals'" == "0 1" | "`vals'" == "1 0" | "`vals'" == "1" | "`vals'" == "0" {
						destring `var', replace
					}
				}
			}
		}


		merge 1:n farmer_id using  `v3'

			* solve the Section V randomization 
			forval i = 1/15 {
				replace v1_1_`i' = v1_2_`i' if missing(v1_1_`i')
			}

			foreach i in 997 998 999 {
				replace v1_1_`i' = v1_2_`i' if missing(v1_1_`i')
			}

			forval i = 1/15 {
				replace v2_2_`i' = v2_1_`i' if missing(v2_2_`i')
			}

			foreach i in 997 998 999 {
				replace v2_2_`i' = v2_1_`i' if missing(v2_2_`i')
			}
			replace v1_1 = v1_2 if missing(v1_1)
			replace v2_2 = v2_1 if missing(v2_2)

	drop v1_2* v2_1*
	rename farmer_id id
	destring id, replace
	drop _merge

	tempfile  full
		save `full'

	import excel using "/Users/elliechen/Library/CloudStorage/GoogleDrive-echen@precisiondev.org/.shortcut-targets-by-id/1D-OD8AWdh5W129DnRHmfYCoGUgJTI-3I/LCC Master Folder/Wellspring LCC Evaluation Implementation/Experiment 1/3. Data Collection/16. Fertilizer and input use survey/1. Sample/fertilizer_use_survey_sample.xlsx", firstrow clear  

	merge 1:1 id using `full'

	keep if _merge == 3
	drop N-Z 



	***** Regressions *****\

		gen any_lcc=0  if  treatment==0
		replace any_lcc=1 if treatment==1 |treatment==2 | treatment==3 | treatment==4

		gen incentive=0 if  treatment==0 | treatment==1
		replace incentive=1 if treatment==2 | treatment==3 | treatment==4

		gen exante=0 if  treatment==0 | treatment==1 | treatment==2
		replace exante=1 if treatment==3 | treatment==4

		gen threat=0 if treatment==0 | treatment==1 | treatment==2 | treatment==4
		replace threat=1 if treatment==3
		
		tab block, gen(block_)

		gen seen_lcc = v3
		gen used_lcc_bl = v4
		
		
		gen used_lcc_anycotplot = 1 if v4 == 1 | v41 == 1 | v5 == 1
		replace used_lcc_anycotplot = 0 if v4 == 0
		
		gen used_lcc_othancotton = v51
		
		gen lcc_owned = v6
		gen lcc_shared = v7 
		gen lcc_stillhave = v8
		
		gen lcc_knowldg_timing_1st = (v10 == 3)
		gen lcc_knowldg_timing_2nd = (v11 == 2)
		gen lcc_knowldg_nplant_slct = (v12 == 3)
		gen lcc_knowldg_amount = (v13 == 2)
		
	local depvars seen_lcc used_lcc_bl used_lcc_anycotplot used_lcc_othancotton lcc_owned lcc_shared lcc_stillhave lcc_knowldg_timing_1st lcc_knowldg_timing_2nd lcc_knowldg_nplant_slct lcc_knowldg_amount
	 
	// Loop through each dependent variable
	foreach dep in `depvars' {
		eststo `dep': regress `dep' any_lcc incentive exante threat block_*, cluster(id)
		local mu: di %5.2f r(mean)
		estadd local mu `mu'
		nlcom _b[any_lcc] + _b[incentive] + _b[exante] + _b[threat]
	}
	#delimit ;
	esttab seen_lcc used_lcc_bl used_lcc_anycotplot used_lcc_othancotton using "${main}/table_sectionV", cells(b(star fmt(3)) se(par fmt(3))) ///
		starlevels(* 0.1 ** 0.05 *** 0.01) tex fragment replace 
		mlabels("Seen LCC" "Used-BL" "Used-cottonplot" "Used-otherplot", prefix({) suffix(})) nonum collabels(none) ///
		stats(N mu, labels("Observations" "Control Mean") ///
		fmt(0 2) layout("{$@$}")) ///
			coeflabels(any_lcc "\textit{LCC}" incentive "\textit{LCC} \times Incentive" exante "\textit{LCC} \times Incentive \times PaidBefore" threat "\textit{LCC} \times Incentive \times PaidBefore \times Threat")
			keep(any_lcc incentive exante threat) order(any_lcc incentive exante threat)
			indicate("Block FE = block_*", labels("{Yes}"))
		;
	#delimit cr


	#delimit ;
	esttab lcc_owned lcc_shared lcc_stillhave using "${main}/table_owning", cells(b(star fmt(3)) se(par fmt(3))) ///
		starlevels(* 0.1 ** 0.05 *** 0.01) tex fragment replace 
		mlabels("Own" "Shared" "Still have", prefix({) suffix(})) nonum collabels(none) stats(N mu, labels("Observations" "Control Mean") ///
		fmt(0 2) layout("{$@$}")) ///
			coeflabels(any_lcc "\textit{LCC}" incentive "\textit{LCC} \times Incentive" exante "\textit{LCC} \times Incentive \times PaidBefore" threat "\textit{LCC} \times Incentive \times PaidBefore \times Threat")
			keep(any_lcc incentive exante threat) order(any_lcc incentive exante threat)
			indicate("Block FE = block_*", labels("{Yes}"))
		;
	#delimit cr

	#delimit ;
	esttab lcc_knowldg_timing_1st lcc_knowldg_timing_2nd lcc_knowldg_nplant_slct lcc_knowldg_amount using "${main}/table_fert_knowledge", cells(b(star fmt(3)) se(par fmt(3))) ///
		starlevels(* 0.1 ** 0.05 *** 0.01) tex fragment replace 
		mlabels("1st timing" "2nd timing" "N Plant" "Amount", prefix({) suffix(})) nonum collabels(none) stats(N mu, labels("Observations" "Control Mean") fmt(0 2) layout("{$@$}")) ///
			coeflabels(any_lcc "\textit{LCC}" incentive "\textit{LCC} \times Incentive" exante "\textit{LCC} \times Incentive \times PaidBefore" threat "\textit{LCC} \times Incentive \times PaidBefore \times Threat")
			keep(any_lcc incentive exante threat) order(any_lcc incentive exante threat)
			indicate("Block FE = block_*", labels("{Yes}"))
		;
	#delimit cr
