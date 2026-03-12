# Individual Assignment - Finance Dashboard in Shiny for R

Dashboard for tracking key financial metrics of a portfolio made up of the Magnificent Seven stocks.

---

# Live Demo

- **Stable: https://019ce02a-f912-3b6c-77af-73a8546999ca.share.connect.posit.cloud/**  
- **Preview: https://019ce02f-8dc5-1f90-9b7a-59075103d801.share.connect.posit.cloud/**  

---

# About

This dashboard is an individual re-implementation of my group project, originally built in **Shiny for Python**, now recreated in **Shiny for R**.

The app tracks key financial metrics for a portfolio composed of the Magnificent Seven stocks:

- Apple
- Microsoft
- Amazon
- Alphabet
- Meta
- Nvidia
- Tesla

# How to Use the Dashboard:

The dashboard has three panels:

**1. Historical Closing Price Trend (top-left)**
A line chart comparing the daily closing prices of all seven stocks over a chosen date range. Use the Select Date Range input to filter the view.

**2. Stock Price Heatmap (top-center)**
A heatmap showing daily price patterns across all seven stocks. Darker colours indicate higher prices; lighter colours indicate lower prices.

**3. Watchlist & Alerts (top-right)**
A quick-glance table of stocks you may want to monitor. The Change column highlights daily moves — red for losses, green for gains. Toggle Show % to switch between dollar and percentage change.

---

# How to Run Locally

Follow these steps to run the dashboard locally.

**1. Clone the repository**
```bash
git clone https://github.com/vytphan/dsci-532-individual-assignment.git
```
 
**2. Navigate to the repository folder**
```bash
cd dsci-532-individual-assignment
```
 
**3. Open the project in RStudio**
```bash
open dsci-532-individual-assignment.Rproj
```
 
This opens the project in RStudio and automatically sets the correct working directory.
 
**4. Install required R packages**
 
In the RStudio **Console**, run:
```r
install.packages(c("shiny", "tidyverse", "plotly", "DT", "bslib", "htmltools"))
```
 
**5. Run the Shiny app**
 
In the RStudio **Console**, run:
```r
shiny::runApp("src")
```

The dashboard will be available at the URL shown in the terminal (typically `http://127.0.0.1:7872`).
