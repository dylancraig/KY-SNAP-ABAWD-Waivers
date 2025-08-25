// Define log file path (assumes $base_path is already set by Master_Script.do)
local log_path "$base_path/Log_Files/Census_Bureau_Population_Cleaning.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: Census_Bureau_Population_Cleaning
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Process and clean Census Bureau county population data for analysis.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: Census_Bureau_Population_Cleaning"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Process and clean Census Bureau county population data for analysis."
di as txt "***********************************************"

// ------------------------ Step 1: Set Up --------------------------
local raw_folder "$base_path/Raw_Data/Census_Bureau_County_Population_Data"
local file "co-est2023-pop-21.xlsx"

// ------------------------ Step 2: Import Data ---------------------
clear
di "Processing file: `file'"

local filepath "`raw_folder'/`file'"
capture import excel "`filepath'", cellrange(A4) firstrow clear
if _rc {
    di "Error importing `file'. Exiting."
    exit
}

// ------------------------ Step 3: Clean Data ----------------------
drop if _n == 1 | inrange(_n, 122, 127)

rename A County
replace County = subinstr(County, ".", "", .)
replace County = subinstr(County, "County, Kentucky", "", .)
replace County = proper(trim(lower(County)))
rename County COUNTY
label variable COUNTY "County Name"

drop B

rename C Ann_Population_2020
rename D Ann_Population_2021
rename E Ann_Population_2022
rename F Ann_Population_2023

reshape long Ann_Population_, i(COUNTY) j(Year)
rename Ann_Population_ Ann_Population
label variable Ann_Population "Annual Population"
label variable Year "Year"

// ------------------------ Step 4: Add Month Variable ---------------
expand 12
bysort COUNTY Year: gen Month = _n
label variable Month "Month"

order COUNTY Year Month Ann_Population

// ------------------------ Step 5: Save Cleaned Data ----------------
save "$base_path/Data_Outputs/Census_Bureau_County_Population_Data/County_Population.dta", replace
di "Census Bureau county population data successfully processed and saved."

// Close the log
log close

// Export log as PDF
translate "`log_path'" "$base_path/Log_Files/Census_Bureau_Population_Cleaning.pdf", replace
