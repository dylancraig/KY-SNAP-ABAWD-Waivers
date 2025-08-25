// Define log file path (assumes $base_path is already set by Master_Script.do)
local log_path "$base_path/Log_Files/LAUS_County_Cleaning.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: LAUS_County_Cleaning
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Clean and process LAUS county-level data for analysis.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: LAUS_County_Cleaning"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Clean and process LAUS county-level data for analysis."
di as txt "***********************************************"

// ------------------------ Step 1: Set Up --------------------------
// Define raw folder and input file
local raw_folder "$base_path/Raw_Data/LAUS_County_Data"
local file "Master_LAUS_Report.xlsx"

// ------------------------ Step 2: Import Data ---------------------
di "Processing: `file'"
local filepath "`raw_folder'/`file'"
di "Full file path: `filepath'"

// Import Excel file starting from row 6 for variable names
import excel "`filepath'", cellrange(A6) firstrow clear

// ------------------------ Step 3: Drop Unnecessary Variables -------
drop A B C E L M N

// ------------------------ Step 4: Clean and Convert Variables ------
foreach var of varlist CivilianLaborForce Employed Unemployed UnemploymentRate {
    replace `var' = subinstr(`var', "(P)", "", .)   // Remove provisional flags
    replace `var' = subinstr(`var', "%", "", .)     // Remove %
    replace `var' = subinstr(`var', ",", "", .)     // Remove commas
    destring `var', replace force                   // Convert to numeric
}

// ------------------------ Step 5: Filter Data ----------------------
drop if real(Year) < 2017

// ------------------------ Step 6: Format Month Variable ------------
gen MonthFormatted = ""
replace MonthFormatted = "01" if Month == "January"
replace MonthFormatted = "02" if Month == "February"
replace MonthFormatted = "03" if Month == "March"
replace MonthFormatted = "04" if Month == "April"
replace MonthFormatted = "05" if Month == "May"
replace MonthFormatted = "06" if Month == "June"
replace MonthFormatted = "07" if Month == "July"
replace MonthFormatted = "08" if Month == "August"
replace MonthFormatted = "09" if Month == "September"
replace MonthFormatted = "10" if Month == "October"
replace MonthFormatted = "11" if Month == "November"
replace MonthFormatted = "12" if Month == "December"

drop Month
rename MonthFormatted Month

// ------------------------ Step 7: Clean and Standardize COUNTY -----
rename Location COUNTY
replace COUNTY = subinstr(COUNTY, " County", "", .)
replace COUNTY = upper(trim(COUNTY))
replace COUNTY = proper(lower(COUNTY))

// ------------------------ Step 8: Final Adjustments ----------------
drop if trim(Month) == "" | missing(Month)

sort COUNTY Year Month
order COUNTY Year Month CivilianLaborForce Employed Unemployed UnemploymentRate

destring Month, replace
destring Year, replace

rename CivilianLaborForce Mnthly_Civilian_Labor_Force
label variable Mnthly_Civilian_Labor_Force "Monthly Civilian Labor Force"

rename Employed Mnthly_Employed
label variable Mnthly_Employed "Monthly Number of Employed Individuals"

rename Unemployed Mnthly_Unemployed
label variable Mnthly_Unemployed "Monthly Number of Unemployed Individuals"

rename UnemploymentRate Mnthly_Unemployment_Rate
label variable Mnthly_Unemployment_Rate "Monthly Unemployment Rate (percentage)"

// ------------------------ Step 9: Save Final Dataset ---------------
save "$base_path/Data_Outputs/LAUS_County_Data/Cleaned_LAUS_Data.dta", replace
di "LAUS county data successfully processed and saved."

// Close the log
log close

// Export log to PDF
translate "`log_path'" "$base_path/Log_Files/LAUS_County_Cleaning.pdf", replace
