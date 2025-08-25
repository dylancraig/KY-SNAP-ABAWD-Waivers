// Define log file path (assumes $base_path is already set by Master_Script.do)
local log_path "$base_path/Log_Files/ACS_Poverty_Cleaning.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: ACS_Poverty_Cleaning
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Process and clean ACS county-level poverty data with selected variables.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: ACS_Poverty_Cleaning"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Process and clean ACS county-level poverty data with selected variables."
di as txt "***********************************************"

// ------------------------ Step 1: Set Up --------------------------
local raw_folder "$base_path/Raw_Data/ACS_County_Characteristics_Data/ACS_Poverty"
local file_pattern "*.csv"

// ------------------------ Step 2: Initialize Master Dataset --------
clear
tempfile master
save `master', emptyok replace

// ------------------------ Step 3: Process Files -------------------
local files : dir "`raw_folder'" files "`file_pattern'"

foreach file of local files {
    di "Processing file: `file'"
    local filepath "`raw_folder'/`file'"
    di "Full file path: `filepath'"

    capture import delimited "`filepath'", varnames(1) stringcols(_all) clear
    if _rc {
        di "Error: Could not import `file'. Skipping."
        continue
    }

    // Extract year from filename
    gen Year = real(regexs(1)) if regexm("`file'", "([0-9]{4})")
    if missing(Year) {
        di "Error: Could not extract year from `file'. Skipping."
        continue
    }

    append using `master'
    save `master', replace
}

// ------------------------ Step 4: Keep Relevant Variables ----------
use `master', clear

keep b17001_002e b17001_001e name Year
rename b17001_002e Ann_Below_Poverty
rename b17001_001e Ann_Total_Pop
rename name COUNTY

gen COUNTY_clean = upper(subinstr(COUNTY, " County, Kentucky", "", .))
drop COUNTY
rename COUNTY_clean COUNTY

// ------------------------ Step 5: Add Month Variable ---------------
gen Month = .
expand 12
bysort COUNTY Year (Month): replace Month = _n

gen MonthFormatted = string(Month, "%02.0f")
drop Month
rename MonthFormatted Month

order COUNTY Year Month Ann_Total_Pop Ann_Below_Poverty

label variable Ann_Total_Pop "Annual total population estimate"
label variable Ann_Below_Poverty "Annual population below poverty level estimate"

drop if COUNTY == "GEOGRAPHIC AREA NAME"

destring Month, replace
destring Year, replace
destring Ann_Below_Poverty, replace
destring Ann_Total_Pop, replace

replace COUNTY = proper(lower(COUNTY))

// ------------------------ Step 6: Save Final Dataset ---------------
save "$base_path/Data_Outputs/ACS_Poverty/ACS_Poverty_Cleaned.dta", replace
di "ACS Poverty dataset successfully processed and saved."

// Close log
log close

// Export log as PDF
translate "`log_path'" "$base_path/Log_Files/ACS_Poverty_Cleaning.pdf", replace
