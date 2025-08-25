// Define log file path (assumes $base_path is already set by Master_Script.do)
local log_path "$base_path/Log_Files/Kentucky_Waiver_Status_Cleaning.log"

// Close any open log file
capture log close

// Start logging in plain text format
log using "`log_path'", text replace

/***********************************************
FILE NAME: Kentucky_Waiver_Status_Cleaning
AUTHOR: Dylan Craig
DATE CREATED: November 24, 2024
DATE MODIFIED: November 26, 2024

PURPOSE: Process and compile Kentucky county waiver status data.
***********************************************/

// Echo header into log
di as txt "***********************************************"
di as txt "FILE NAME: Kentucky_Waiver_Status_Cleaning"
di as txt "AUTHOR: Dylan Craig"
di as txt "DATE CREATED: November 24, 2024"
di as txt "DATE MODIFIED: November 26, 2024"
di as txt "PURPOSE: Process and compile Kentucky county waiver status data."
di as txt "***********************************************"

// ------------------------ Step 1: Set Up --------------------------
// Define folders and Excel files
local raw_folder "$base_path/Raw_Data/Kentucky_County_Waiver_Status_Data"
local files : dir "`raw_folder'" files "*.xlsx"

// Prepare master dataset
clear
tempfile master
save `master', emptyok replace

// ------------------------ Step 2: Process Each File ----------------
foreach file of local files {
    di "Processing file: `file'"

    local filepath "`raw_folder'/`file'"

    // Import Excel file
    capture import excel "`filepath'", firstrow clear
    if _rc {
        di "Error importing `file'. Skipping."
        continue
    }

    // Standardize COUNTY variable
    rename County COUNTY
    replace COUNTY = upper(trim(COUNTY))

    // Ensure Month is two-digit string
    gen MonthFormatted = string(Month, "%02.0f")
    drop Month
    rename MonthFormatted Month

    // Reorder variables
    order COUNTY Year Month WaiverStatus

    // Append into master
    append using `master'
    save `master', replace
}

// ------------------------ Step 3: Clean and Standardize ------------
use `master', clear

destring Year, replace
destring Month, replace force
replace COUNTY = proper(lower(COUNTY))

// Map WaiverStatus to numeric
gen WaiverStatus_num = .
replace WaiverStatus_num = 1 if WaiverStatus == "Waived"
replace WaiverStatus_num = 0 if WaiverStatus == "Not Waived"

label define WaiverStatus_lbl 1 "Waived" 0 "Not Waived"
label values WaiverStatus_num WaiverStatus_lbl

drop WaiverStatus
rename WaiverStatus_num WaiverStatus

label variable WaiverStatus "County waived from SNAP ABAWD work requirements (1 = Waived, 0 = Not Waived)"

// ------------------------ Step 4: Save Final Dataset ---------------
save "$base_path/Data_Outputs/Kentucky_Waiver_Status/Final_Waiver_Status.dta", replace
di "Kentucky Waiver Status data successfully processed and saved."

// Close log
log close

// Export log to PDF
translate "`log_path'" "$base_path/Log_Files/Kentucky_Waiver_Status_Cleaning.pdf", replace
