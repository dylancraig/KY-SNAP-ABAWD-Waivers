// Define log file path (assumes $base_path is already set by Master_Script.do)
local log_path "$base_path/Log_Files/ACS_Education_Cleaning.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: ACS_Education_Cleaning
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Process and clean ACS county-level education data with selected variables.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: ACS_Education_Cleaning"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Process and clean ACS county-level education data with selected variables."
di as txt "***********************************************"

// ------------------------ Step 1: Set Up --------------------------
local raw_folder "$base_path/Raw_Data/ACS_County_Characteristics_Data/ACS_Education"
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

    // Import CSV file
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

    // Append
    append using `master'
    save `master', replace
}

// ------------------------ Step 4: Keep Relevant Variables ----------
use `master', clear

keep s1501_c02_014e s1501_c02_015e name s1501_c01_006e Year
rename s1501_c01_006e Ann_25_Over_Pop
rename s1501_c02_014e Ann_Perc_HS_25_Over
rename s1501_c02_015e Ann_Perc_Bach_25_Over
rename name COUNTY

// Drop first row if extra header
drop in 1

// Standardize COUNTY
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

order COUNTY Year Month Ann_25_Over_Pop Ann_Perc_HS_25_Over Ann_Perc_Bach_25_Over

drop if COUNTY == "GEOGRAPHIC AREA NAME"

destring Month, replace
destring Year, replace
destring Ann_25_Over_Pop, replace
destring Ann_Perc_HS_25_Over, replace
destring Ann_Perc_Bach_25_Over, replace

replace COUNTY = proper(lower(COUNTY))

// Labels
label variable Ann_25_Over_Pop "Annual estimate: Population 25 years and over"
label variable Ann_Perc_HS_25_Over "Annual percentage: Population 25+ with high school diploma or higher"
label variable Ann_Perc_Bach_25_Over "Annual percentage: Population 25+ with bachelor's degree or higher"

// ------------------------ Step 6: Save Final Dataset ---------------
di "Saving final dataset with selected variables..."
save "$base_path/Data_Outputs/ACS_Education/ACS_Education_Cleaned.dta", replace
di "File successfully saved as ACS_Education_Cleaned.dta"

// Close log
log close

// Export log as PDF
translate "`log_path'" "$base_path/Log_Files/ACS_Education_Cleaning.pdf", replace
