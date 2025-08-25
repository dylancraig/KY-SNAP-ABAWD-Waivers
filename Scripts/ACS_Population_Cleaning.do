// Define log file path (assumes $base_path is already set by Master_Script.do)
local log_path "$base_path/Log_Files/ACS_Population_Cleaning.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: ACS_Population_Cleaning
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Process and clean ACS county-level population data with a month variable.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: ACS_Population_Cleaning"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Process and clean ACS county-level population data with a month variable."
di as txt "***********************************************"

// ------------------------ Step 1: Set Up --------------------------
local raw_folder "$base_path/Raw_Data/ACS_County_Characteristics_Data/ACS_Population"
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

    capture import delimited "`filepath'", varnames(2) stringcols(_all) clear
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

    // Drop unnecessary rows
    drop if geographic == "" | missing(geographic)

    append using `master'
    save `master', replace
}

// ------------------------ Step 4: Add Month Variable & Clean --------
use `master', clear

// Expand to 12 months per year
gen Month = .
expand 12
bysort geographicareaname Year (Month): replace Month = _n

// Format Month as two digits
gen MonthFormatted = string(Month, "%02.0f")
drop Month
rename MonthFormatted Month

// Reorder and clean variables
order geographicareaname Year Month estimatetotal
rename geographicareaname COUNTY
rename estimatetotal Ann_Population

// Standardize COUNTY names
gen COUNTY_clean = upper(subinstr(COUNTY, " County, Kentucky", "", .))
drop COUNTY
rename COUNTY_clean COUNTY

// Keep only necessary vars
keep COUNTY Ann_Population Year Month
order COUNTY Year Month

// Convert to numeric
destring Month, replace
destring Year, replace
destring Ann_Population, replace

replace COUNTY = proper(lower(COUNTY))

// Drop data for 2020 and later
drop if Year >= 2020

// Label variables
label variable Ann_Population "Annual Population"

// ------------------------ Step 5: Save Final Dataset ---------------
di "Saving final dataset with Month variable..."
save "$base_path/Data_Outputs/ACS_Population/ACS_Population_Cleaned.dta", replace
di "File successfully saved as ACS_Population_Cleaned.dta"

// Close log
log close

// Export log as PDF
translate "`log_path'" "$base_path/Log_Files/ACS_Population_Cleaning.pdf", replace
