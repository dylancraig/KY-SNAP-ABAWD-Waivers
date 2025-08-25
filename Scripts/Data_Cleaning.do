// Define log file path (assumes $base_path is already set by Master_Script.do)
local log_path "$base_path/Log_Files/Data_Cleaning.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: Data_Cleaning
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Merge all .dta files from specified folders by COUNTY, Year, and Month.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: Data_Cleaning"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Merge all .dta files from specified folders by COUNTY, Year, and Month."
di as txt "***********************************************"

// ------------------------ Step 1: Load Population Data --------------------------
// Start with ACS population dataset
use "$base_path/Data_Outputs/ACS_Population/ACS_Population_Cleaned.dta", clear

// Append Census Bureau County Population data
append using "$base_path/Data_Outputs/Census_Bureau_County_Population_Data/County_Population.dta"

// ------------------------ Step 2: Sequential Merges -----------------------------
// ACS Education
merge 1:1 COUNTY Year Month using "$base_path/Data_Outputs/ACS_Education/ACS_Education_Cleaned.dta", keepusing(*) nogen

// ACS Poverty
merge 1:1 COUNTY Year Month using "$base_path/Data_Outputs/ACS_Poverty/ACS_Poverty_Cleaned.dta", keepusing(*) nogen

// ACS Race
merge 1:1 COUNTY Year Month using "$base_path/Data_Outputs/ACS_Race/ACS_Race_Cleaned.dta", keepusing(*) nogen

// County Health Rankings
merge 1:1 COUNTY Year Month using "$base_path/Data_Outputs/County_Health_Rankings_Roadmaps_Data/Cleaned_FoodInsecurity_Data.dta", keepusing(*) nogen

// Kentucky County ABAWD
merge 1:1 COUNTY Year Month using "$base_path/Data_Outputs/Kentucky_County_ABAWD_Data/Cleaned_ABAWD_Data.dta", keepusing(*) nogen

// Kentucky Waiver Status
merge 1:1 COUNTY Year Month using "$base_path/Data_Outputs/Kentucky_Waiver_Status/Final_Waiver_Status.dta", keepusing(*) nogen

// LAUS County Data
merge 1:1 COUNTY Year Month using "$base_path/Data_Outputs/LAUS_County_Data/Cleaned_LAUS_Data.dta", keepusing(*) nogen

// QCEW County Data
merge 1:1 COUNTY Year Month using "$base_path/Data_Outputs/QCEW_County_Data/Cleaned_QCEW_Data.dta", keepusing(*) nogen

// ------------------------ Step 3: Variable Creation ------------------------------
// Make sure numeric fields are numeric (avoids type mismatch issues)
destring Ann_Below_Poverty Ann_NH_White Ann_NH_Black Ann_NH_AIAN Ann_NH_Asian ///
         Ann_NH_NHOPI Ann_NH_Other Ann_NH_TwoOrMore Ann_Hispanic_Latino, replace force

// Poverty percentage
gen Ann_Perc_Below_Poverty = (Ann_Below_Poverty / Ann_Population) * 100
label variable Ann_Perc_Below_Poverty "Annual Percentage of population below poverty level"

// Race/Ethnicity percentages
gen Ann_Perc_NH_White        = (Ann_NH_White     / Ann_Population) * 100
gen Ann_Perc_NH_Black        = (Ann_NH_Black     / Ann_Population) * 100
gen Ann_Perc_NH_AIAN         = (Ann_NH_AIAN      / Ann_Population) * 100
gen Ann_Perc_NH_Asian        = (Ann_NH_Asian     / Ann_Population) * 100
gen Ann_Perc_NH_NHOPI        = (Ann_NH_NHOPI     / Ann_Population) * 100
gen Ann_Perc_NH_Other        = (Ann_NH_Other     / Ann_Population) * 100
gen Ann_Perc_NH_TwoOrMore    = (Ann_NH_TwoOrMore / Ann_Population) * 100
gen Ann_Perc_Hispanic_Latino = (Ann_Hispanic_Latino / Ann_Population) * 100

// Labels
label variable Ann_Perc_NH_White         "Annual % Non-Hispanic White"
label variable Ann_Perc_NH_Black         "Annual % Non-Hispanic Black"
label variable Ann_Perc_NH_AIAN          "Annual % Non-Hispanic AIAN"
label variable Ann_Perc_NH_Asian         "Annual % Non-Hispanic Asian"
label variable Ann_Perc_NH_NHOPI         "Annual % Non-Hispanic NHOPI"
label variable Ann_Perc_NH_Other         "Annual % Non-Hispanic Other"
label variable Ann_Perc_NH_TwoOrMore     "Annual % Non-Hispanic Two or More Races"
label variable Ann_Perc_Hispanic_Latino  "Annual % Hispanic or Latino"

// Replace invalid values with missing
foreach var in Ann_Perc_Below_Poverty Ann_Perc_NH_White Ann_Perc_NH_Black Ann_Perc_NH_AIAN ///
                  Ann_Perc_NH_Asian Ann_Perc_NH_NHOPI Ann_Perc_NH_Other ///
                  Ann_Perc_NH_TwoOrMore Ann_Perc_Hispanic_Latino {
    replace `var' = . if missing(Ann_Population) | Ann_Population == 0
}

// ------------------------ Step 4: Convert Percentages to Proportions --------------
local percent_vars Ann_Perc_HS_25_Over Ann_Perc_Bach_25_Over Ann_Perc_Below_Poverty ///
    Ann_Perc_NH_White Ann_Perc_NH_Black Ann_Perc_NH_AIAN Ann_Perc_NH_Asian Ann_Perc_NH_NHOPI ///
    Ann_Perc_NH_Other Ann_Perc_NH_TwoOrMore Ann_Perc_Hispanic_Latino Ann_FoodInsecurePerc ///
    Ann_RuralPopPerc Mnthly_Unemployment_Rate

foreach var of local percent_vars {
    replace `var' = `var' / 100
}

// ------------------------ Step 5: Final Adjustments -------------------------------
order COUNTY REGION Year Month WaiverStatus Ann_Population
sort COUNTY Year Month

save "$base_path/Data_Outputs/Final_Cleaned_Data/Final_Cleaned_Data.dta", replace
di "All files successfully merged and saved."

// Close log
log close

// Export log to PDF
translate "`log_path'" "$base_path/Log_Files/Master_Cleaning.pdf", replace
