// Define log file path (assumes $base_path is already set by Master_Script.do)
local log_path "$base_path/Log_Files/ACS_Race_Cleaning.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: ACS_Race_Cleaning
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Process and clean ACS county-level race data with selected variables.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: ACS_Race_Cleaning"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Process and clean ACS county-level race data with selected variables."
di as txt "***********************************************"

// ------------------------ Step 1: Set Up --------------------------
local raw_folder "$base_path/Raw_Data/ACS_County_Characteristics_Data/ACS_Race"
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

    // Extract Year from filename
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

keep b03002_003e b03002_004e b03002_005e b03002_006e b03002_007e b03002_008e b03002_009e b03002_012e name Year

rename b03002_003e Ann_NH_White
rename b03002_004e Ann_NH_Black
rename b03002_005e Ann_NH_AIAN
rename b03002_006e Ann_NH_Asian
rename b03002_007e Ann_NH_NHOPI
rename b03002_008e Ann_NH_Other
rename b03002_009e Ann_NH_TwoOrMore
rename b03002_012e Ann_Hispanic_Latino
rename name COUNTY

drop in 1   // Drop ACS header row if present
drop if COUNTY == "GEOGRAPHIC AREA NAME"

gen COUNTY_clean = upper(subinstr(COUNTY, " County, Kentucky", "", .))
drop COUNTY
rename COUNTY_clean COUNTY

label variable Ann_NH_White         "Annual estimate: Non-Hispanic White population"
label variable Ann_NH_Black         "Annual estimate: Non-Hispanic Black population"
label variable Ann_NH_AIAN          "Annual estimate: Non-Hispanic American Indian or Alaska Native population"
label variable Ann_NH_Asian         "Annual estimate: Non-Hispanic Asian population"
label variable Ann_NH_NHOPI         "Annual estimate: Non-Hispanic Native Hawaiian or Other Pacific Islander population"
label variable Ann_NH_Other         "Annual estimate: Non-Hispanic Other Race population"
label variable Ann_NH_TwoOrMore     "Annual estimate: Non-Hispanic Two or More Races population"
label variable Ann_Hispanic_Latino  "Annual estimate: Hispanic or Latino population"

// ------------------------ Step 5: Add Month Variable ---------------
gen Month = .
expand 12
bysort COUNTY Year (Month): replace Month = _n

gen MonthFormatted = string(Month, "%02.0f")
drop Month
rename MonthFormatted Month

order COUNTY Year Month Ann_NH_White Ann_NH_Black Ann_NH_AIAN Ann_NH_Asian Ann_NH_NHOPI Ann_NH_Other Ann_NH_TwoOrMore Ann_Hispanic_Latino

destring Month, replace
destring Year, replace
destring Ann_Hispanic_Latino, replace
destring Ann_NH_AIAN, replace
destring Ann_NH_Asian, replace
destring Ann_NH_Black, replace
destring Ann_NH_NHOPI, replace
destring Ann_NH_TwoOrMore, replace
destring Ann_NH_White, replace
destring Ann_NH_Other, replace

replace COUNTY = proper(lower(COUNTY))

// ------------------------ Step 6: Save Final Dataset ---------------
save "$base_path/Data_Outputs/ACS_Race/ACS_Race_Cleaned.dta", replace
di "ACS Race dataset successfully processed and saved."

// Close log
log close

// Export log as PDF
translate "`log_path'" "$base_path/Log_Files/ACS_Race_Cleaning.pdf", replace
