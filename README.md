# KY-SNAP-ABAWD-Waivers

This project processes, cleans, merges, and analyzes county-level datasets relevant to **Supplemental Nutrition Assistance Program (SNAP) Able-Bodied Adults Without Dependents (ABAWD)** work requirement waivers in Kentucky (2017–2024).  
The workflow uses **Stata (.do)** and **R** scripts to create a harmonized dataset for descriptive statistics, regression analysis, and visualization.

---

## 📂 Project Structure
- `Raw_Data/` – Source data (ACS, BLS, USDA, CHFS, County Health Rankings, etc.)
- `Scripts/` – Stata `.do` scripts and R scripts for cleaning, merging, and analysis
- `Data_Outputs/` – Final cleaned datasets and collapsed summary outputs
- `Visualizations/` – Trend plots, maps, pre/post comparisons
- `Docs/` – Reports and supporting documentation

---

## ⚙️ Workflow Overview
1. **Cleaning Scripts**: Each raw dataset is cleaned and standardized at the county–year–month level.  
2. **Master Cleaning**: Merges cleaned datasets into `Final_Cleaned_Data.dta`.  
3. **Master Data Analysis**: Produces summary statistics, regression models, and visualizations.  
4. **R Scripts**: Supplementary visualization and analysis (maps, time trends, pre-pandemic comparisons).  

---

## 🚀 How to Run
1. Run **`MASTER_DO_FILE.do`** in Stata  
   - This executes all cleaning and merging steps → outputs `Final_Cleaned_Data.dta`.  
2. Run **`Master_Data_Analysis.R`** in R  
   - This collapses the dataset, generates maps, line plots, and summary statistics.  

---

## 🧾 Key Scripts
- **MASTER_DO_FILE.do** → Driver file, sets path and runs all scripts in order  
- **ACS_Poverty_Cleaning.do** → Processes ACS poverty data (county-level estimates)  
- **ACS_Education_Cleaning.do** → Processes ACS education attainment variables  
- **Kentucky_County_ABAWD_Cleaning.do** → Standardizes CHFS ABAWD caseload data  
- **LAUS_County_Cleaning.do** → Cleans BLS county unemployment statistics  
- **QCEW_County_Cleaning.do** → Processes BLS wage data (monthly expansion)  
- **Data_Cleaning.do** → Master cleaning, merges datasets into `Final_Cleaned_Data.dta`  
- **Data_Analysis.do** → Collapses data by waiver status, produces regressions & outputs  
- **Master_Data_Analysis.R** → R-based visualizations (maps, trend plots, pre-pandemic analysis)  

---

## 📊 Data Sources
- **ACS 5-Year Estimates** – population, poverty, education, race  
- **Bureau of Labor Statistics** – LAUS (unemployment), QCEW (wages)  
- **USDA-FNS** – County waiver approval data  
- **Kentucky CHFS** – ABAWD caseload reports  
- **County Health Rankings** – food insecurity, rural population  
