# ================================================================
# Data_Visualizations.R
# Author: Dylan Craig (adapted)
# Date Created: November 24, 2024
# Date Modified: April 4, 2025
#
# PURPOSE:
#   Collapse SNAP-related data by WaiverStatus, Year, and Month,
#   create a final merged dataset, and generate visualizations,
#   including individual maps of waiver status over time saved as PNG and PDF.
# ================================================================

### ------------------------ Step 1: Set Up ------------------------ ###

# --- Define Global Base Path using KY_SNAP_ABAWD_Waivers ---
BASE_PATH <- "C:/Job Applications/KY-SNAP-ABAWD-Waivers"

# --- Load Required Libraries ---
library(dplyr)
library(haven)
library(lubridate)
library(zoo)
library(ggplot2)
library(scales)
library(sf)
library(tigris)
library(stringr)
library(RColorBrewer)

# --- Define Paths for Input and Output ---
data_in        <- file.path(BASE_PATH, "Data_Outputs/Final_Cleaned_Data/Final_Cleaned_Data.dta")
collapsed_path <- file.path(BASE_PATH, "Data_Outputs/Final_Collapsed_Data")
viz_path       <- file.path(BASE_PATH, "Visualizations")

# --- Optional: Create Output Directories ---
if (!dir.exists(collapsed_path)) dir.create(collapsed_path, recursive = TRUE)
if (!dir.exists(viz_path))       dir.create(viz_path, recursive = TRUE)



### ------------------------ Step 2: Load Data & Weighted Means ------------------------ ###
# Load the merged UNCOLLAPSED dataset (needed for county-level maps)
message("Loading uncollapsed data for mapping...")
if (!file.exists(data_in)) {
  stop("Input data file not found at: ", data_in, "\nPlease check the BASE_PATH and file location.")
}
# This 'data' object holds the county-level info needed for maps
data <- read_dta(data_in)
message("Loaded uncollapsed data with ", nrow(data), " rows.")

# --- The following collapse steps are kept for consistency with the original script's flow ---
# --- but the resulting data frames (weighted_means, education_means, sums_data, final_data) ---
# --- are primarily used for the line plots, not the maps. ---

# Collapse weighted means for population-based variables
message("Collapsing weighted means...")
weighted_means <- data %>%
  group_by(WaiverStatus, Year, Month) %>%
  summarise(
    Ann_Perc_NH_White        = weighted.mean(Ann_Perc_NH_White, Ann_Population, na.rm = TRUE),
    Ann_Perc_NH_Black        = weighted.mean(Ann_Perc_NH_Black, Ann_Population, na.rm = TRUE),
    Ann_Perc_NH_AIAN         = weighted.mean(Ann_Perc_NH_AIAN, Ann_Population, na.rm = TRUE),
    Ann_Perc_NH_Asian        = weighted.mean(Ann_Perc_NH_Asian, Ann_Population, na.rm = TRUE),
    Ann_Perc_NH_NHOPI        = weighted.mean(Ann_Perc_NH_NHOPI, Ann_Population, na.rm = TRUE),
    Ann_Perc_NH_Other        = weighted.mean(Ann_Perc_NH_Other, Ann_Population, na.rm = TRUE),
    Ann_Perc_NH_TwoOrMore    = weighted.mean(Ann_Perc_NH_TwoOrMore, Ann_Population, na.rm = TRUE),
    Ann_Perc_Hispanic_Latino = weighted.mean(Ann_Perc_Hispanic_Latino, Ann_Population, na.rm = TRUE),
    Mnthly_Unemployment_Rate = weighted.mean(Mnthly_Unemployment_Rate, Ann_Population, na.rm = TRUE),
    Ann_FoodInsecurePerc     = weighted.mean(Ann_FoodInsecurePerc, Ann_Population, na.rm = TRUE),
    Ann_RuralPopPerc         = weighted.mean(Ann_RuralPopPerc, Ann_Population, na.rm = TRUE),
    Ann_Perc_Below_Poverty   = weighted.mean(Ann_Perc_Below_Poverty, Ann_Population, na.rm = TRUE),
    Quart_Wkly_Wage          = weighted.mean(Quart_Wkly_Wage, Ann_Population, na.rm = TRUE),
    .groups = 'drop'
  )

# Save temporary dataset for weighted means
# write_dta(weighted_means, file.path(collapsed_path, "temp_weighted_means.dta"))


### ------------------------ Step 3: Education-Based Weighted Means ------------------------ ###
message("Collapsing education means...")
# Calculate weighted means for education-based variables
education_means <- data %>%
  group_by(WaiverStatus, Year, Month) %>%
  summarise(
    Ann_Perc_HS_25_Over   = weighted.mean(Ann_Perc_HS_25_Over, Ann_25_Over_Pop, na.rm = TRUE),
    Ann_Perc_Bach_25_Over = weighted.mean(Ann_Perc_Bach_25_Over, Ann_25_Over_Pop, na.rm = TRUE),
    .groups = 'drop'
  )

# Save temporary dataset for education means
# write_dta(education_means, file.path(collapsed_path, "temp_education_means.dta"))


### ------------------------ Step 4: Sums ------------------------ ###
message("Collapsing sums...")
# Generate a dummy variable for counting if it doesn't exist
if (!"count_dummy" %in% names(data)) {
  data <- data %>% mutate(count_dummy = 1)
}

# Collapse sums for count-based variables
sums_data <- data %>%
  group_by(WaiverStatus, Year, Month) %>%
  summarise(
    Mnthly_WorkReg_16_59    = sum(Mnthly_WorkReg_16_59, na.rm = TRUE),
    Mnthly_ActiveSNAP_18_49 = sum(Mnthly_ActiveSNAP_18_49, na.rm = TRUE),
    Mnthly_WorkReg_18_49    = sum(Mnthly_WorkReg_18_49, na.rm = TRUE),
    Mnthly_Working80Hrs     = sum(Mnthly_Working80Hrs, na.rm = TRUE),
    Mnthly_Dep_Child        = sum(Mnthly_Dep_Child, na.rm = TRUE),
    Mnthly_Pregnancy        = sum(Mnthly_Pregnancy, na.rm = TRUE),
    Mnthly_WEPVES           = sum(Mnthly_WEPVES, na.rm = TRUE),
    Mnthly_ABAWD_Comply     = sum(Mnthly_ABAWD_Comply, na.rm = TRUE),
    Mnthly_STLP             = sum(Mnthly_STLP, na.rm = TRUE),
    Mnthly_ActiveSNAP_18_52 = sum(Mnthly_ActiveSNAP_18_52, na.rm = TRUE),
    Mnthly_WorkReg_18_52    = sum(Mnthly_WorkReg_18_52, na.rm = TRUE),
    Mnthly_Veteran          = sum(Mnthly_Veteran, na.rm = TRUE),
    Mnthly_Homeless         = sum(Mnthly_Homeless, na.rm = TRUE),
    Mnthly_FosterCare       = sum(Mnthly_FosterCare, na.rm = TRUE),
    Mnthly_ActiveSNAP_18_54 = sum(Mnthly_ActiveSNAP_18_54, na.rm = TRUE),
    Mnthly_WorkReg_18_54    = sum(Mnthly_WorkReg_18_54, na.rm = TRUE),
    Number_Counties         = sum(count_dummy, na.rm = TRUE),
    .groups = 'drop'
  )

# Save temporary sums data
# write_dta(sums_data, file.path(collapsed_path, "temp_sums.dta"))


### ------------------------ Step 5: Generate All Observations and Merge (for Collapsed Data) -------- ###
# This step creates the 'final_data' used by the line plots
message("Generating final collapsed data grid...")
# Create a dataset with all combinations of WaiverStatus, Year, and Month
all_combinations <- expand.grid(
  WaiverStatus = c(0, 1), # Assuming 0/1 are the raw values before factor
  Year = 2017:2024,
  Month = 1:12
)

# Drop extra observations (for months beyond October 2024)
all_combinations <- all_combinations %>% filter(!(Year == 2024 & Month >= 11))

# Merge the collapsed datasets with the full grid of combinations
final_data <- all_combinations %>%
  left_join(weighted_means, by = c("WaiverStatus", "Year", "Month")) %>%
  left_join(education_means, by = c("WaiverStatus", "Year", "Month")) %>%
  left_join(sums_data, by = c("WaiverStatus", "Year", "Month"))

# Convert WaiverStatus to a factor with labels (0 = Not Waived, 1 = Waived)
# This applies to the COLLAPSED final_data, used later for line plots
final_data <- final_data %>%
  mutate(
    WaiverStatus_Factor = factor( # Renamed to avoid conflict
      WaiverStatus,
      levels = c(0, 1),
      labels = c("Not Waived", "Waived")
    )
  )

# --- Save the final merged COLLAPSED dataset (Optional) ---
# final_data_file <- file.path(collapsed_path, "Final_Collapsed_Data.dta")
# write_dta(final_data, final_data_file)


### ------------------------ Step 6: Label Variables ------------------------ ###
# Labeling primarily applies to the collapsed 'final_data' for interpretation,
# but comments are kept here for reference.
# attr(final_data$Ann_Perc_NH_White, "label") <- "Annual Weighted Avg. Percent Non-Hispanic White"


### ------------------------ Step 7a: Generate Visualizations (Trend Lines using COLLAPSED data) --- ###
message("Generating trend line plots...")

# Create a YearMonth variable for plotting (using the first day of the month) in final_data
final_data <- final_data %>%
  mutate(YearMonth = as.Date(ISOdate(Year, Month, 1)))

# Convert rates/proportions to percentages in final_data
final_data <- final_data %>%
  mutate(
    # Check if conversion already happened; avoid multiplying by 100 twice
    Mnthly_Unemployment_Rate_pct = if_else(Mnthly_Unemployment_Rate <= 1 & !is.na(Mnthly_Unemployment_Rate), Mnthly_Unemployment_Rate * 100, Mnthly_Unemployment_Rate),
    Ann_FoodInsecurePerc_pct     = if_else(Ann_FoodInsecurePerc <= 1 & !is.na(Ann_FoodInsecurePerc), Ann_FoodInsecurePerc * 100, Ann_FoodInsecurePerc),
    Ann_RuralPopPerc_pct         = if_else(Ann_RuralPopPerc <= 1 & !is.na(Ann_RuralPopPerc), Ann_RuralPopPerc * 100, Ann_RuralPopPerc),
    Ann_Perc_Below_Poverty_pct   = if_else(Ann_Perc_Below_Poverty <= 1 & !is.na(Ann_Perc_Below_Poverty), Ann_Perc_Below_Poverty * 100, Ann_Perc_Below_Poverty),
    Ann_Perc_HS_25_Over_pct      = if_else(Ann_Perc_HS_25_Over <= 1 & !is.na(Ann_Perc_HS_25_Over), Ann_Perc_HS_25_Over * 100, Ann_Perc_HS_25_Over),
    Ann_Perc_Bach_25_Over_pct    = if_else(Ann_Perc_Bach_25_Over <= 1 & !is.na(Ann_Perc_Bach_25_Over), Ann_Perc_Bach_25_Over * 100, Ann_Perc_Bach_25_Over),
    Ann_Perc_NH_White_pct        = if_else(Ann_Perc_NH_White <= 1 & !is.na(Ann_Perc_NH_White), Ann_Perc_NH_White * 100, Ann_Perc_NH_White),
    Ann_Perc_NH_Black_pct        = if_else(Ann_Perc_NH_Black <= 1 & !is.na(Ann_Perc_NH_Black), Ann_Perc_NH_Black * 100, Ann_Perc_NH_Black),
    Ann_Perc_Hispanic_Latino_pct = if_else(Ann_Perc_Hispanic_Latino <= 1 & !is.na(Ann_Perc_Hispanic_Latino), Ann_Perc_Hispanic_Latino * 100, Ann_Perc_Hispanic_Latino)
  )

# List of variables to plot from final_data
vars_to_plot <- c(
  "Mnthly_Unemployment_Rate_pct", # Use the percentage version
  "Ann_FoodInsecurePerc_pct",
  "Ann_RuralPopPerc_pct",
  "Ann_Perc_Below_Poverty_pct",
  "Quart_Wkly_Wage", # This is not a percentage
  "Ann_Perc_HS_25_Over_pct",
  "Ann_Perc_Bach_25_Over_pct",
  "Mnthly_ABAWD_Comply", # This is a count
  "Ann_Perc_NH_White_pct",
  "Ann_Perc_NH_Black_pct",
  "Ann_Perc_Hispanic_Latino_pct"
)

# Create a named vector of descriptive labels for plot titles and axes
var_labels <- c(
  Mnthly_Unemployment_Rate_pct = "Monthly Weighted Avg. Unemployment Rate (%)",
  Ann_FoodInsecurePerc_pct     = "Annual Weighted Avg. Percent Food Insecure (%)",
  Ann_RuralPopPerc_pct         = "Annual Weighted Avg. Percent Rural Population (%)",
  Ann_Perc_Below_Poverty_pct   = "Annual Weighted Avg. Percent Below Poverty Line (%)",
  Quart_Wkly_Wage              = "Quarterly Weighted Avg. Weekly Wage (All Industries)",
  Ann_Perc_HS_25_Over_pct      = "Annual Weighted Avg. Percent with HS Diploma or Higher (Aged 25+) (%)",
  Ann_Perc_Bach_25_Over_pct    = "Annual Weighted Avg. Percent with Bachelor's Degree or Higher (Aged 25+) (%)",
  Mnthly_ABAWD_Comply          = "Monthly Total ABAWDs Needing to Comply with Work Requirements",
  Ann_Perc_NH_White_pct        = "Annual Weighted Avg. Percent Non-Hispanic White (%)",
  Ann_Perc_NH_Black_pct        = "Annual Weighted Avg. Percent Non-Hispanic Black (%)",
  Ann_Perc_Hispanic_Latino_pct = "Annual Weighted Avg. Percent Hispanic or Latino (%)"
)

# Define key dates for vertical dashed lines
key_dates_lines <- as.Date(c( # Renamed to avoid conflict
  "2018-01-01", "2019-01-01",
  "2020-01-01", "2020-04-01",
  "2023-07-01", "2023-12-01"
))

# Define COVID annotation date once
covid_annotation_date <- as.Date("2020-04-01") + days(30)

# Loop through variables to create and save line plots
for (var in vars_to_plot) {
  
  # Check if the variable exists in the data
  if (!var %in% names(final_data)) {
    warning("Variable '", var, "' not found in final_data. Skipping trend plot.")
    next # Skip to the next variable
  }
  
  plot_title <- var_labels[var]
  if (is.na(plot_title)) plot_title <- var
  
  # Determine y-axis formatting
  if (grepl("_pct$", var)) {
    y_scale <- scale_y_continuous(labels = label_percent(scale = 1))
    y_axis_label <- "Percent (%)"
  } else if (var == "Quart_Wkly_Wage") {
    y_scale <- scale_y_continuous(labels = dollar_format(prefix = "$"))
    y_axis_label <- "US Dollars ($)"
  } else if (var == "Mnthly_ABAWD_Comply") {
    y_scale <- scale_y_continuous(labels = label_comma())
    y_axis_label <- "Number of Individuals"
  } else {
    y_scale <- scale_y_continuous()
    y_axis_label <- ""
  }
  
  # Create the plot using final_data and WaiverStatus_Factor
  p <- ggplot(final_data, aes(x = YearMonth, y = .data[[var]], color = WaiverStatus_Factor, group = WaiverStatus_Factor)) +
    geom_line(na.rm = TRUE, linewidth = 1.2) +
    scale_color_manual(
      name = NULL,
      values = c("Not Waived" = "#92B2E7", "Waived" = "#21314D"), # Colors matching bar chart
      labels = c("Not Waived" = "Non-Waived", "Waived" = "Waived")
    ) +
    labs(
      title = plot_title,
      subtitle = "Waived vs. Non-Waived Counties (Collapsed Average/Sum)",
      x = "Year",
      y = y_axis_label,
      color = "",
      caption = "Dashed lines reflect key policy/waiver dates."
    ) +
    scale_x_date(
      breaks = seq(min(final_data$YearMonth, na.rm = TRUE), max(final_data$YearMonth, na.rm = TRUE), by = "year"),
      date_labels = "%Y"
    ) +
    y_scale +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
      legend.position = "bottom",
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(color = "gray85", linetype = "dotted"),
      axis.line = element_line(color = "gray70"),
      axis.ticks = element_line(color = "gray70")
    ) +
    geom_hline(yintercept = 0, color = "gray80", linetype = "solid", linewidth = 0.5) +
    geom_vline(
      xintercept = as.numeric(key_dates_lines),
      linetype = "dashed",
      color = "gray40",
      linewidth = 0.8
    )
  
  # Add annotation
  annotation_y <- min(final_data[[var]], na.rm = TRUE)
  if (is.infinite(annotation_y) || is.na(annotation_y)) annotation_y <- 0
  x_range <- range(final_data$YearMonth, na.rm = TRUE)
  # Add check for NA range values before comparison
  if (!is.na(x_range[1]) && !is.na(x_range[2]) && !is.na(covid_annotation_date) && covid_annotation_date >= x_range[1] && covid_annotation_date <= x_range[2]) {
    p <- p + annotate(
      "text", x = covid_annotation_date, y = annotation_y, label = "COVID Waiver",
      vjust = -0.5, hjust = 0, size = 3, color = "gray30", angle = 90
    )
  }
  
  
  # Display the plot
  # print(p)
  
  # --- Save the plot ---
  plot_filename_base <- paste0(var, "_trend_R")
  png_file <- file.path(viz_path, paste0(plot_filename_base, ".png"))
  ggsave(filename = png_file, plot = p, width = 10, height = 6, dpi = 300)
  # pdf_file <- file.path(viz_path, paste0(plot_filename_base, ".pdf"))
  # ggsave(filename = pdf_file, plot = p, width = 10, height = 6, device = cairo_pdf)
}
message("Finished trend line plots.")

### ------------------------ Step 7b: Generate Visualizations (INDIVIDUAL MAPS using UNCOLLAPSED data - NO LOOP) ---------- ###
message("Generating individual waiver status maps...")

# --- 1. Define Selected Dates for Maps ---
selected_map_dates <- as.Date(c(
  "2017-01-01", "2018-01-01", "2019-01-01",
  "2020-01-01", "2020-04-01", "2023-07-01", "2023-12-01"
))

# --- 2. Prepare UNCOLLAPSED Waiver Data for Maps ---
# Use the 'data' object loaded in Step 2
map_data_prep <- data %>%
  filter(!is.na(COUNTY)) %>%
  mutate(Date = make_date(Year, Month, 1)) %>%
  filter(Date %in% selected_map_dates) %>%
  mutate(COUNTY_CLEAN = str_to_upper(str_remove(COUNTY, " County"))) %>%
  mutate(
    WaiverStatus_Map = factor(WaiverStatus, levels = c(0, 1), labels = c("Not Waived", "Waived"))
  ) %>%
  select(COUNTY_CLEAN, Date, WaiverStatus_Map) %>%
  distinct(COUNTY_CLEAN, Date, .keep_all = TRUE)

if(nrow(map_data_prep) == 0) {
  stop("No waiver data found for the selected map dates. Check 'selected_map_dates' and the input data.")
}

# --- 3. Get Kentucky County Shapefiles ---
options(tigris_use_cache = TRUE)
ky_counties_sf <- counties(state = "KY", cb = TRUE, class = "sf") %>%
  mutate(COUNTY_CLEAN = str_to_upper(str_remove(NAME, " County"))) %>%
  select(COUNTY_CLEAN, geometry)

# --- 4. Merge Spatial Data with Waiver Data ---
ky_map_data_merged <- ky_counties_sf %>%
  left_join(map_data_prep, by = "COUNTY_CLEAN") %>%
  filter(!is.na(Date)) # Keep only counties/dates with matching waiver status

if(nrow(ky_map_data_merged) == 0) {
  stop("Map data is empty after merging shapefile with waiver data. Check county name matching.")
}
# Handle potential missing matches
if(any(is.na(ky_map_data_merged$WaiverStatus_Map))) {
  warning("Some counties could not be matched with waiver status for the selected dates.")
  ky_map_data_merged <- ky_map_data_merged %>%
    mutate(WaiverStatus_Map = factor(ifelse(is.na(WaiverStatus_Map), "Missing Data", as.character(WaiverStatus_Map)),
                                     levels = c("Not Waived", "Waived", "Missing Data")))
}

# --- 5. Define Colors (Matching Bar Chart) ---
map_color_values <- c(
  "Not Waived"   = "#92B2E7", # Light Blue
  "Waived"       = "#21314D", # Dark Blue
  "Missing Data" = "grey80"   # Grey
)

# --- 6. Create and Save Individual Maps (Explicitly for each date) ---

# --- Map for 2017-01-01 ---
map_date_1 <- as.Date("2017-01-01")
map_data_1 <- ky_map_data_merged %>% filter(Date == map_date_1)
if(nrow(map_data_1) > 0) {
  map_plot_1 <- ggplot(data = map_data_1) +
    geom_sf(aes(fill = WaiverStatus_Map), color = "black", size = 0.1) + # Black borders
    scale_fill_manual(values = map_color_values, name = NULL, na.value = "grey80", drop = FALSE) + # No legend title
    labs(title = paste("Kentucky SNAP ABAWD Waiver Status by County:", format(map_date_1, "%B %Y")), # Date in Title
         subtitle = "Based on Approved Waiver Requests") + # Updated subtitle
    theme_void(base_size = 11) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
          plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40"), # Grey subtitle
          legend.position = "bottom") # Legend at bottom
  # Save
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2017_01.png"), plot = map_plot_1, width = 8, height = 6, dpi = 300)
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2017_01.pdf"), plot = map_plot_1, width = 8, height = 6, device = cairo_pdf)
  message("Map saved for January 2017")
} else { warning("No map data for 2017-01-01") }

# --- Map for 2018-01-01 ---
map_date_2 <- as.Date("2018-01-01")
map_data_2 <- ky_map_data_merged %>% filter(Date == map_date_2)
if(nrow(map_data_2) > 0) {
  map_plot_2 <- ggplot(data = map_data_2) +
    geom_sf(aes(fill = WaiverStatus_Map), color = "black", size = 0.1) + # Black borders
    scale_fill_manual(values = map_color_values, name = NULL, na.value = "grey80", drop = FALSE) + # No legend title
    labs(title = paste("Kentucky SNAP ABAWD Waiver Status by County:", format(map_date_2, "%B %Y")), # Date in Title
         subtitle = "Based on Approved Waiver Requests") + # Updated subtitle
    theme_void(base_size = 11) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
          plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40"), # Grey subtitle
          legend.position = "bottom") # Legend at bottom
  # Save
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2018_01.png"), plot = map_plot_2, width = 8, height = 6, dpi = 300)
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2018_01.pdf"), plot = map_plot_2, width = 8, height = 6, device = cairo_pdf)
  message("Map saved for January 2018")
} else { warning("No map data for 2018-01-01") }

# --- Map for 2019-01-01 ---
map_date_3 <- as.Date("2019-01-01")
map_data_3 <- ky_map_data_merged %>% filter(Date == map_date_3)
if(nrow(map_data_3) > 0) {
  map_plot_3 <- ggplot(data = map_data_3) +
    geom_sf(aes(fill = WaiverStatus_Map), color = "black", size = 0.1) + # Black borders
    scale_fill_manual(values = map_color_values, name = NULL, na.value = "grey80", drop = FALSE) + # No legend title
    labs(title = paste("Kentucky SNAP ABAWD Waiver Status by County:", format(map_date_3, "%B %Y")), # Date in Title
         subtitle = "Based on Approved Waiver Requests") + # Updated subtitle
    theme_void(base_size = 11) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
          plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40"), # Grey subtitle
          legend.position = "bottom") # Legend at bottom
  # Save
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2019_01.png"), plot = map_plot_3, width = 8, height = 6, dpi = 300)
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2019_01.pdf"), plot = map_plot_3, width = 8, height = 6, device = cairo_pdf)
  message("Map saved for January 2019")
} else { warning("No map data for 2019-01-01") }

# --- Map for 2020-01-01 ---
map_date_4 <- as.Date("2020-01-01")
map_data_4 <- ky_map_data_merged %>% filter(Date == map_date_4)
if(nrow(map_data_4) > 0) {
  map_plot_4 <- ggplot(data = map_data_4) +
    geom_sf(aes(fill = WaiverStatus_Map), color = "black", size = 0.1) + # Black borders
    scale_fill_manual(values = map_color_values, name = NULL, na.value = "grey80", drop = FALSE) + # No legend title
    labs(title = paste("Kentucky SNAP ABAWD Waiver Status by County:", format(map_date_4, "%B %Y")), # Date in Title
         subtitle = "Based on Approved Waiver Requests") + # Updated subtitle
    theme_void(base_size = 11) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
          plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40"), # Grey subtitle
          legend.position = "bottom") # Legend at bottom
  # Save
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2020_01.png"), plot = map_plot_4, width = 8, height = 6, dpi = 300)
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2020_01.pdf"), plot = map_plot_4, width = 8, height = 6, device = cairo_pdf)
  message("Map saved for January 2020")
} else { warning("No map data for 2020-01-01") }

# --- Map for 2020-04-01 ---
map_date_5 <- as.Date("2020-04-01")
map_data_5 <- ky_map_data_merged %>% filter(Date == map_date_5)
if(nrow(map_data_5) > 0) {
  map_plot_5 <- ggplot(data = map_data_5) +
    geom_sf(aes(fill = WaiverStatus_Map), color = "black", size = 0.1) + # Black borders
    scale_fill_manual(values = map_color_values, name = NULL, na.value = "grey80", drop = FALSE) + # No legend title
    labs(title = paste("Kentucky SNAP ABAWD Waiver Status by County:", format(map_date_5, "%B %Y")), # Date in Title
         subtitle = "Based on Approved Waiver Requests (COVID Waiver)") + # Updated subtitle
    theme_void(base_size = 11) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
          plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40"), # Grey subtitle
          legend.position = "bottom") # Legend at bottom
  # Save
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2020_04.png"), plot = map_plot_5, width = 8, height = 6, dpi = 300)
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2020_04.pdf"), plot = map_plot_5, width = 8, height = 6, device = cairo_pdf)
  message("Map saved for April 2020")
} else { warning("No map data for 2020-04-01") }

# --- Map for 2023-07-01 ---
map_date_6 <- as.Date("2023-07-01")
map_data_6 <- ky_map_data_merged %>% filter(Date == map_date_6)
if(nrow(map_data_6) > 0) {
  map_plot_6 <- ggplot(data = map_data_6) +
    geom_sf(aes(fill = WaiverStatus_Map), color = "black", size = 0.1) + # Black borders
    scale_fill_manual(values = map_color_values, name = NULL, na.value = "grey80", drop = FALSE) + # No legend title
    labs(title = paste("Kentucky SNAP ABAWD Waiver Status by County:", format(map_date_6, "%B %Y")), # Date in Title
         subtitle = "Based on Approved Waiver Requests") + # Updated subtitle
    theme_void(base_size = 11) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
          plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40"), # Grey subtitle
          legend.position = "bottom") # Legend at bottom
  # Save
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2023_07.png"), plot = map_plot_6, width = 8, height = 6, dpi = 300)
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2023_07.pdf"), plot = map_plot_6, width = 8, height = 6, device = cairo_pdf)
  message("Map saved for July 2023")
} else { warning("No map data for 2023-07-01") }

# --- Map for 2023-12-01 ---
map_date_7 <- as.Date("2023-12-01")
map_data_7 <- ky_map_data_merged %>% filter(Date == map_date_7)
if(nrow(map_data_7) > 0) {
  map_plot_7 <- ggplot(data = map_data_7) +
    geom_sf(aes(fill = WaiverStatus_Map), color = "black", size = 0.1) + # Black borders
    scale_fill_manual(values = map_color_values, name = NULL, na.value = "grey80", drop = FALSE) + # No legend title
    labs(title = paste("Kentucky SNAP ABAWD Waiver Status by County:", format(map_date_7, "%B %Y")), # Date in Title
         subtitle = "Based on Approved Waiver Requests") + # Updated subtitle
    theme_void(base_size = 11) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
          plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40"), # Grey subtitle
          legend.position = "bottom") # Legend at bottom
  # Save
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2023_12.png"), plot = map_plot_7, width = 8, height = 6, dpi = 300)
  ggsave(filename = file.path(viz_path, "ky_snap_waiver_status_map_R_2023_12.pdf"), plot = map_plot_7, width = 8, height = 6, device = cairo_pdf)
  message("Map saved for December 2023")
} else { warning("No map data for 2023-12-01") }

message("Finished generating individual maps.")


### ------------------------ Step 7c: Generate Visualizations (Single Line ABAWD using COLLAPSED data) --- ###
message("Generating single line ABAWD plot...")

# This section uses the COLLAPSED 'final_data' as originally intended

# 1) Summarize Data from final_data
line_data <- final_data %>%
  # Handle potential NAs before check
  mutate(Mnthly_ABAWD_Comply = ifelse(is.na(Mnthly_ABAWD_Comply), 0, Mnthly_ABAWD_Comply)) %>%
  # Replace 0 with NA for plotting gaps (original logic)
  mutate(
    Mnthly_ABAWD_Comply_Plot = if_else(Mnthly_ABAWD_Comply == 0, NA_real_, Mnthly_ABAWD_Comply)
  ) %>%
  group_by(Year, Month, YearMonth) %>% # Use YearMonth already created
  summarise(
    Total_ABAWDs = sum(Mnthly_ABAWD_Comply_Plot, na.rm = TRUE), # Sum the version with NAs for gaps
    # Check if all contributing values were NA. If so, result should be NA.
    All_NA = all(is.na(Mnthly_ABAWD_Comply_Plot)),
    .groups = 'drop'
  ) %>%
  mutate(Total_ABAWDs = ifelse(All_NA & Total_ABAWDs == 0, NA_real_, Total_ABAWDs)) %>%
  select(-All_NA) %>%
  # ADDED FIX: Filter out NA and Inf values before plotting
  filter(!is.na(Total_ABAWDs), is.finite(Total_ABAWDs))

# Check if data exists and proceed only if it does
if (nrow(line_data) > 0) {
  # --- ALL PLOTTING CODE MOVED INSIDE THE ELSE BLOCK ---
  
  # Calculate annotation position ONLY if data exists
  annotation_y_line <- min(line_data$Total_ABAWDs, na.rm = TRUE)
  # ADDED FIX: Check if min returned Inf
  if (is.infinite(annotation_y_line)) annotation_y_line <- 0
  
  # Calculate x-axis range ONLY if data exists
  x_range_line <- range(line_data$YearMonth, na.rm = TRUE)
  
  # 3) Plot the Single-Line Chart
  p_line <- ggplot(line_data, aes(x = YearMonth, y = Total_ABAWDs)) +
    geom_line(linewidth = 1.2, color = "#21314D", na.rm = TRUE) + # Use dark blue from map/bar
    labs(
      title = "Monthly Total ABAWDs Required to Comply with Work Requirements",
      subtitle = "All Kentucky Counties (Collapsed Sum)",
      x = "Year",
      y = "Number of Individuals",
      caption = "Dashed lines reflect key policy/waiver dates.\nGaps indicate months with missing data in original source."
    ) +
    # MODIFIED FIX: Let ggplot handle date breaks, just format labels
    scale_x_date(date_labels = "%Y") +
    # scale_x_date( # Original line with seq breaks
    #   breaks = seq(x_range_line[1], x_range_line[2], by = "year"),
    #   date_labels = "%Y"
    # ) +
    # Restore label_comma formatting
    scale_y_continuous(labels = label_comma()) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
      legend.position = "none",
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(color = "gray85", linetype = "dotted"),
      axis.line = element_line(color = "gray70"),
      axis.ticks = element_line(color = "gray70"),
      axis.title.y = element_text(size = 10, margin = margin(r = 10))
    ) +
    geom_hline(yintercept = 0, color = "gray70", linewidth = 0.5) +
    geom_vline(
      xintercept = as.numeric(key_dates_lines),
      linetype = "dashed",
      color = "gray40",
      linewidth = 0.8
    )
  
  # Add annotation ONLY if data exists and range is valid
  # Add check for NA range values before comparison
  if (!is.na(x_range_line[1]) && !is.na(x_range_line[2]) && !is.na(covid_annotation_date) && covid_annotation_date >= x_range_line[1] && covid_annotation_date <= x_range_line[2]) {
    p_line <- p_line + annotate(
      "text", x = covid_annotation_date, y = annotation_y_line, label = "COVID Waiver",
      vjust = -0.5, hjust = 0, size = 3, color = "gray30", angle = 90
    )
  }
  
  
  # 4) Print the plot
  print(p_line)
  
  # 5) Save the plot
  line_plot_filename <- file.path(viz_path, "ABAWDs_Total_NoMissingSpike_R.png")
  ggsave(
    filename = line_plot_filename,
    plot = p_line,
    width = 10,
    height = 6,
    dpi = 300
  )
  message("Line plot saved to: ", line_plot_filename)
  # Also save as PDF if desired
  # line_plot_filename_pdf <- file.path(viz_path, "ABAWDs_Total_NoMissingSpike_R.pdf")
  # ggsave(filename = line_plot_filename_pdf, plot = p_line, width = 10, height = 6, device = cairo_pdf)
  
} else {
  warning("No valid ABAWD data found after aggregation for line plot. Skipping plot.")
} # End check for line_data

message("Script finished.")

### ------------------------ Step 8: Pre-Pandemic Weighted Average Differences ------------------------ ###
message("Calculating pre-pandemic average differences...")

# Ensure required packages are loaded
if (!require(tidyr)) { stop("Package 'tidyr' is required but not installed.") }
if (!require(stringr)) { stop("Package 'stringr' is required but not installed.") }
if (!require(dplyr)) { stop("Package 'dplyr' is required but not installed.") }
if (!require(writexl)) { stop("Package 'writexl' is required but not installed. Please install it.") } # For saving Excel
if (!require(tibble)) { stop("Package 'tibble' is required but not installed.") } # For rownames_to_column

# Define pre-pandemic end date (inclusive: ends Feb 2020)
pre_pandemic_end_year <- 2020
pre_pandemic_end_month <- 2

# Define the variables to analyze (original weighted means from final_data)
vars_for_diff <- c(
  "Ann_Perc_NH_White", "Ann_Perc_NH_Black", "Ann_Perc_NH_AIAN",
  "Ann_Perc_NH_Asian", "Ann_Perc_NH_NHOPI", "Ann_Perc_NH_Other",
  "Ann_Perc_NH_TwoOrMore", "Ann_Perc_Hispanic_Latino",
  "Mnthly_Unemployment_Rate", "Ann_FoodInsecurePerc", "Ann_RuralPopPerc",
  "Ann_Perc_Below_Poverty", "Quart_Wkly_Wage", # Note: Quart_Wkly_Wage is NOT a percentage
  "Ann_Perc_HS_25_Over", "Ann_Perc_Bach_25_Over"
)

# --- Check if final_data exists ---
if (!exists("final_data")) {
  stop("The 'final_data' dataframe does not exist. Please ensure Step 5 has run successfully.")
}

# --- Check if required columns exist in final_data ---
required_base_cols <- c("Year", "Month", "WaiverStatus")
missing_cols <- setdiff(c(required_base_cols, vars_for_diff), names(final_data))
if (length(missing_cols) > 0) {
  stop("The following required columns are missing from 'final_data': ", paste(missing_cols, collapse=", "))
}

# Filter final_data for the pre-pandemic period
pre_pandemic_data <- final_data %>%
  filter(Year < pre_pandemic_end_year | (Year == pre_pandemic_end_year & Month <= pre_pandemic_end_month))

# Check if pre-pandemic data exists after filtering and contains both waiver statuses
if (nrow(pre_pandemic_data) == 0) {
  warning("No data found for the specified pre-pandemic period (Jan 2017 - Feb 2020). Skipping difference calculation.")
} else if (length(unique(pre_pandemic_data$WaiverStatus)) < 2) {
  warning("Data for only one WaiverStatus (", paste(unique(pre_pandemic_data$WaiverStatus), collapse=","), ") found in the pre-pandemic period. Cannot calculate differences. Skipping.")
} else {
  
  # Calculate the average for each variable within the pre-pandemic period, grouped by WaiverStatus
  pre_pandemic_averages <- pre_pandemic_data %>%
    group_by(WaiverStatus) %>%
    summarise(across(all_of(vars_for_diff), ~ mean(.x, na.rm = TRUE)), .groups = 'drop')
  
  # Check if averages were calculated successfully for both statuses
  if (!all(c(0, 1) %in% pre_pandemic_averages$WaiverStatus)) {
    warning("Averages for both Waived (1) and Non-Waived (0) statuses were not successfully calculated from the pre-pandemic data. Skipping difference calculation.")
  } else {
    # Pivot the data wider
    pre_pandemic_pivoted <- pre_pandemic_averages %>%
      tidyr::pivot_wider(names_from = WaiverStatus,
                         values_from = all_of(vars_for_diff)
      )
    
    # Create an empty tibble/df to store results
    pre_pandemic_diffs <- tibble::tibble(.rows = 1)
    
    # Calculate differences column by column
    warnings_generated <- list()
    for (i in seq_along(vars_for_diff)) {
      var_name <- vars_for_diff[i]
      waived_col_name <- paste0(var_name, "_1")
      nonwaived_col_name <- paste0(var_name, "_0")
      
      if (waived_col_name %in% names(pre_pandemic_pivoted) && nonwaived_col_name %in% names(pre_pandemic_pivoted)) {
        diff_value <- pre_pandemic_pivoted[[waived_col_name]] - pre_pandemic_pivoted[[nonwaived_col_name]]
        pre_pandemic_diffs <- pre_pandemic_diffs %>%
          mutate(!!var_name := diff_value)
      } else {
        warning_message <- paste("Could not calculate difference for", var_name, "- missing required column(s) after pivoting. Looked for:", waived_col_name, "and", nonwaived_col_name)
        warnings_generated[[var_name]] <- warning_message
        warning(warning_message, immediate. = TRUE)
        pre_pandemic_diffs <- pre_pandemic_diffs %>%
          mutate(!!var_name := NA_real_)
      }
    } # End for loop
    
    # --- Percentage Point Conversion ---
    # Define variables that represent proportions/percentages
    percent_vars <- c(
      "Ann_Perc_NH_White", "Ann_Perc_NH_Black", "Ann_Perc_NH_AIAN",
      "Ann_Perc_NH_Asian", "Ann_Perc_NH_NHOPI", "Ann_Perc_NH_Other",
      "Ann_Perc_NH_TwoOrMore", "Ann_Perc_Hispanic_Latino",
      "Mnthly_Unemployment_Rate", "Ann_FoodInsecurePerc", "Ann_RuralPopPerc",
      "Ann_Perc_Below_Poverty", "Ann_Perc_HS_25_Over", "Ann_Perc_Bach_25_Over"
    )
    # Identify which percentage variables are actually present as columns in the results
    percent_vars_in_results <- intersect(percent_vars, names(pre_pandemic_diffs))
    
    # Multiply the difference for these variables by 100
    if (length(percent_vars_in_results) > 0) {
      pre_pandemic_diffs <- pre_pandemic_diffs %>%
        mutate(across(all_of(percent_vars_in_results), ~ .x * 100))
      message("Converted percentage variables to percentage points (multiplied by 100).")
    }
    # --- End Conversion ---
    
    
    # Print the results (now potentially in percentage points)
    cat("\n\n### Average Difference (Waived - Not Waived) in Weighted Means ###\n")
    cat("### Pre-Pandemic Period: January 2017 - February 2020 (Percentages as Pts.) ###\n\n")
    if(nrow(pre_pandemic_diffs) > 0 && ncol(pre_pandemic_diffs) > 0 && !all(sapply(pre_pandemic_diffs, is.na))) {
      print(t(as.data.frame(pre_pandemic_diffs)), quote = FALSE)
    } else {
      cat("No valid differences could be calculated or all differences resulted in NA.\n")
    }
    
    
    # --- Save to Excel ---
  
    output_dir <- viz_path
    output_filename <- "pre_pandemic_differences.xlsx"
    output_path <- file.path(output_dir, output_filename)
    
    
    # Create the directory if it doesn't exist
    if (!dir.exists(output_dir)) {
      tryCatch({
        dir.create(output_dir, recursive = TRUE)
        message("Created output directory: ", output_dir)
      }, error = function(e){
        warning("Could not create output directory: ", output_dir, ". Error: ", e$message)
        # Avoid stopping the whole script if dir creation fails, maybe save locally?
        # For now, just warn and proceed (saving will likely fail too)
      })
    }
    
    # Prepare data frame for saving: Transpose, add column names, make variables a column
    if(nrow(pre_pandemic_diffs) > 0 && ncol(pre_pandemic_diffs) > 0 && !all(sapply(pre_pandemic_diffs, is.na))) {
      diffs_to_save <- as.data.frame(t(pre_pandemic_diffs))
      colnames(diffs_to_save) <- c("Difference_Waived_minus_NonWaived_Pts") # Pts indicates percentage points where applicable
      diffs_to_save <- tibble::rownames_to_column(diffs_to_save, var = "Variable")
      
      # Attempt to write the Excel file
      tryCatch({
        write_xlsx(diffs_to_save, path = output_path)
        message("Pre-pandemic differences saved successfully to: ", output_path)
      }, error = function(e) {
        warning("Failed to save results to Excel file: ", output_path, "\nError: ", e$message)
      })
    } else {
      message("Skipping Excel save as no valid differences were calculated or all were NA.")
    }
    # --- End Save to Excel ---
    
    
    message("Finished calculating pre-pandemic average differences.")
    
    # Optionally print summary of specific warnings generated during the loop, if any
    if(length(warnings_generated) > 0) {
      cat("\nSummary of difference calculation issues (if any):\n")
      for(msg in warnings_generated) { cat("- ", msg, "\n") }
    }
    
  } # End check for both statuses in averages
} # End check for pre-pandemic data / number of statuses

# --- END OF SCRIPT SECTION ---