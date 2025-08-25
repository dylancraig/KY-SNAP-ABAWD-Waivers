// Define log file path (assumes $base_path is already set by Master_Script.do)
local log_path "$base_path/Log_Files/Data_Analysis.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: Data_Analysis
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Collapse SNAP-related data by WaiverStatus, Year, and Month,
         and create a final, merged dataset.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: Data_Analysis"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Collapse SNAP-related data by WaiverStatus, Year, and Month,"
di as txt "         and create a final, merged dataset."
di as txt "***********************************************"

// ------------------------ Step 1: Weighted Means ------------------
use "$base_path/Data_Outputs/Final_Cleaned_Data/Final_Cleaned_Data.dta", clear

collapse (mean) Ann_Perc_NH_White Ann_Perc_NH_Black Ann_Perc_NH_AIAN Ann_Perc_NH_Asian ///
         Ann_Perc_NH_NHOPI Ann_Perc_NH_Other Ann_Perc_NH_TwoOrMore Ann_Perc_Hispanic_Latino ///
         Mnthly_Unemployment_Rate Ann_FoodInsecurePerc Ann_RuralPopPerc Ann_Perc_Below_Poverty Quart_Wkly_Wage ///
         [aw=Ann_Population], by(WaiverStatus Year Month)

save "$base_path/Data_Outputs/Final_Collapsed_Data/temp_weighted_means.dta", replace

// ------------------------ Step 2: Education Weighted Means --------
use "$base_path/Data_Outputs/Final_Cleaned_Data/Final_Cleaned_Data.dta", clear

collapse (mean) Ann_Perc_HS_25_Over Ann_Perc_Bach_25_Over [aw=Ann_25_Over_Pop], ///
         by(WaiverStatus Year Month)

save "$base_path/Data_Outputs/Final_Collapsed_Data/temp_education_means.dta", replace

// ------------------------ Step 3: Sums ----------------------------
use "$base_path/Data_Outputs/Final_Cleaned_Data/Final_Cleaned_Data.dta", clear
gen count_dummy = 1

collapse (sum) Mnthly_WorkReg_16_59 Mnthly_ActiveSNAP_18_49 Mnthly_WorkReg_18_49 Mnthly_Working80Hrs ///
    Mnthly_Dep_Child Mnthly_Pregnancy Mnthly_WEPVES Mnthly_ABAWD_Comply Mnthly_STLP ///
    Mnthly_ActiveSNAP_18_52 Mnthly_WorkReg_18_52 Mnthly_Veteran Mnthly_Homeless Mnthly_FosterCare ///
    Mnthly_ActiveSNAP_18_54 Mnthly_WorkReg_18_54 (sum) Number_Counties = count_dummy, ///
    by(WaiverStatus Year Month)

save "$base_path/Data_Outputs/Final_Collapsed_Data/temp_sums.dta", replace

// ------------------------ Step 4: Generate All Observations --------
clear
set obs 192  // 8 years (2017-2024) * 12 months * 2 WaiverStatus
gen Year = 2017 + int((_n-1)/24)
gen Month = mod(int((_n-1)/2), 12) + 1
gen WaiverStatus = mod((_n-1), 2)

label define WaiverStatus_lbl 0 "Not Waived" 1 "Waived"
label values WaiverStatus WaiverStatus_lbl

drop if Year == 2024 & Month >= 11

merge 1:1 WaiverStatus Year Month using "$base_path/Data_Outputs/Final_Collapsed_Data/temp_weighted_means.dta", keep(master match) nogen
merge 1:1 WaiverStatus Year Month using "$base_path/Data_Outputs/Final_Collapsed_Data/temp_education_means.dta", keep(master match) nogen
merge 1:1 WaiverStatus Year Month using "$base_path/Data_Outputs/Final_Collapsed_Data/temp_sums.dta", keep(master match) nogen

// ------------------------ Step 5: Label Variables -----------------
label variable Ann_Perc_NH_White "Annual Weighted Avg. Percent Non-Hispanic White"
label variable Ann_Perc_NH_Black "Annual Weighted Avg. Percent Non-Hispanic Black"
label variable Ann_Perc_NH_AIAN "Annual Weighted Avg. Percent Non-Hispanic AIAN"
label variable Ann_Perc_NH_Asian "Annual Weighted Avg. Percent Non-Hispanic Asian"
label variable Ann_Perc_NH_NHOPI "Annual Weighted Avg. Percent Non-Hispanic NHOPI"
label variable Ann_Perc_NH_Other "Annual Weighted Avg. Percent Non-Hispanic Other Race"
label variable Ann_Perc_NH_TwoOrMore "Annual Weighted Avg. Percent Non-Hispanic Two or More Races"
label variable Ann_Perc_Hispanic_Latino "Annual Weighted Avg. Percent Hispanic or Latino"
label variable Ann_RuralPopPerc "Annual Weighted Avg. Percent Rural Population"

label variable Mnthly_Unemployment_Rate "Monthly Weighted Avg. Unemployment Rate"
label variable Ann_FoodInsecurePerc "Annual Weighted Avg. Percent Food Insecure"
label variable Ann_Perc_Below_Poverty "Annual Weighted Avg. Percent Below Poverty Line"
label variable Quart_Wkly_Wage "Quarterly Weighted Avg. Weekly Wage (All Industries)"
label variable Ann_Perc_HS_25_Over "Annual Weighted Avg. Percent with HS Diploma or Higher (25+)"
label variable Ann_Perc_Bach_25_Over "Annual Weighted Avg. Percent with Bachelor's Degree or Higher (25+)"

label variable Mnthly_ActiveSNAP_18_49 "Monthly Total SNAP Participants Aged 18-49"
label variable Mnthly_ActiveSNAP_18_52 "Monthly Total SNAP Participants Aged 18-52"
label variable Mnthly_ActiveSNAP_18_54 "Monthly Total SNAP Participants Aged 18-54"
label variable Mnthly_Veteran "Monthly Total Veterans"
label variable Mnthly_Homeless "Monthly Total Homeless"
label variable Mnthly_FosterCare "Monthly Total Foster Care Youth"
label variable Mnthly_WorkReg_16_59 "Monthly Total Work-Registered (16-59)"
label variable Mnthly_WorkReg_18_49 "Monthly Total Work-Registered (18-49)"
label variable Mnthly_WorkReg_18_52 "Monthly Total Work-Registered (18-52)"
label variable Mnthly_WorkReg_18_54 "Monthly Total Work-Registered (18-54)"
label variable Mnthly_Working80Hrs "Monthly Total Working >80 Hours"
label variable Mnthly_Dep_Child "Monthly Total Dependent Children"
label variable Mnthly_Pregnancy "Monthly Total Pregnant Individuals"
label variable Mnthly_WEPVES "Monthly Total WEP/VES Participants"
label variable Mnthly_ABAWD_Comply "Monthly Total ABAWDs Subject to Work Requirements"
label variable Mnthly_STLP "Monthly Total STLP Participants"

// ------------------------ Step 6: Summary Tables ------------------
* Economic Variables
outsum Mnthly_Unemployment_Rate Ann_FoodInsecurePerc Ann_Perc_Below_Poverty Quart_Wkly_Wage ///
    using "$base_path/Visualizations/economics_means.txt" if WaiverStatus==1, ///
    ctitle("Waived Counties") title("Economic Variables Means") replace
outsum Mnthly_Unemployment_Rate Ann_FoodInsecurePerc Ann_Perc_Below_Poverty Quart_Wkly_Wage ///
    using "$base_path/Visualizations/economics_means.txt" if WaiverStatus==0, ///
    ctitle("Non Waived Counties") append

* Demographic Variables
outsum Ann_Perc_NH_White Ann_Perc_NH_Black Ann_Perc_Hispanic_Latino Ann_Perc_NH_Asian ///
       Ann_Perc_NH_AIAN Ann_Perc_NH_NHOPI Ann_Perc_NH_Other Ann_Perc_NH_TwoOrMore ///
       Ann_RuralPopPerc Ann_Perc_HS_25_Over Ann_Perc_Bach_25_Over ///
    using "$base_path/Visualizations/demographics_means.txt" if WaiverStatus==1, ///
    ctitle("Waived Counties") title("Demographic Variables Means") replace
outsum Ann_Perc_NH_White Ann_Perc_NH_Black Ann_Perc_Hispanic_Latino Ann_Perc_NH_Asian ///
       Ann_Perc_NH_AIAN Ann_Perc_NH_NHOPI Ann_Perc_NH_Other Ann_Perc_NH_TwoOrMore ///
       Ann_RuralPopPerc Ann_Perc_HS_25_Over Ann_Perc_Bach_25_Over ///
    using "$base_path/Visualizations/demographics_means.txt" if WaiverStatus==0, ///
    ctitle("Non Waived Counties") append

* SNAP Variables
outsum Mnthly_WorkReg_16_59 Mnthly_ActiveSNAP_18_49 Mnthly_WorkReg_18_49 Mnthly_Working80Hrs ///
       Mnthly_Dep_Child Mnthly_Pregnancy Mnthly_WEPVES Mnthly_ABAWD_Comply Mnthly_STLP ///
       Mnthly_ActiveSNAP_18_52 Mnthly_WorkReg_18_52 Mnthly_Veteran Mnthly_Homeless Mnthly_FosterCare ///
       Mnthly_ActiveSNAP_18_54 Mnthly_WorkReg_18_54 ///
    using "$base_path/Visualizations/snap_means.txt" if WaiverStatus==1, ///
    ctitle("Waived Counties") title("SNAP Variables Means") replace
outsum Mnthly_WorkReg_16_59 Mnthly_ActiveSNAP_18_49 Mnthly_WorkReg_18_49 Mnthly_Working80Hrs ///
       Mnthly_Dep_Child Mnthly_Pregnancy Mnthly_WEPVES Mnthly_ABAWD_Comply Mnthly_STLP ///
       Mnthly_ActiveSNAP_18_52 Mnthly_WorkReg_18_52 Mnthly_Veteran Mnthly_Homeless Mnthly_FosterCare ///
       Mnthly_ActiveSNAP_18_54 Mnthly_WorkReg_18_54 ///
    using "$base_path/Visualizations/snap_means.txt" if WaiverStatus==0, ///
    ctitle("Non Waived Counties") append

// ------------------------ Step 7: Regressions ----------------------
use "$base_path/Data_Outputs/Final_Cleaned_Data/Final_Cleaned_Data.dta", clear
gen YearMonth = ym(Year, Month)
format YearMonth %tm
egen COUNTY_num = group(COUNTY), label
xtset COUNTY_num YearMonth

global econ_controls Quart_Wkly_Wage Ann_Perc_Below_Poverty
global demo_controls Ann_Perc_NH_White Ann_Perc_NH_Black Ann_Perc_Hispanic_Latino ///
    Ann_Perc_HS_25_Over Ann_Perc_Bach_25_Over Ann_RuralPopPerc

reghdfe Ann_FoodInsecurePerc WaiverStatus Mnthly_Unemployment_Rate, ///
    absorb(COUNTY YearMonth) vce(cluster COUNTY_num)
outreg2 using "$base_path/Visualizations/Regression_Table.doc", ///
    bdec(4) title("Regression Estimates: Annual Food Insecurity Rate") ///
    cttop("Dependent Variable: Annual Food Insecurity Percentage") ///
    ctitle("Model 1: Unemployment Rate Control") word replace

reghdfe Ann_FoodInsecurePerc WaiverStatus Mnthly_Unemployment_Rate $econ_controls, ///
    absorb(COUNTY YearMonth) vce(cluster COUNTY_num)
outreg2 using "$base_path/Visualizations/Regression_Table.doc", ///
    bdec(4) ctitle("Model 2: Other Economic Controls") word append

reghdfe Ann_FoodInsecurePerc WaiverStatus Mnthly_Unemployment_Rate $econ_controls $demo_controls, ///
    absorb(COUNTY YearMonth) vce(cluster COUNTY_num)
outreg2 using "$base_path/Visualizations/Regression_Table.doc", ///
    bdec(4) ctitle("Model 3: Demographic Controls") word append

// ------------------------ Step 8: Save Collapsed Data --------------
save "$base_path/Data_Outputs/Final_Collapsed_Data/Collapsed_Waiver_Status_Data.dta", replace
di "Dataset successfully processed and saved as Collapsed_Waiver_Status_Data.dta"

// Close log
log close

// Export log as PDF
translate "`log_path'" "$base_path/Log_Files/Master_Data_Analysis.pdf", replace
