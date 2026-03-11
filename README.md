# Individual Assignment - Finance Dashboard in Shiny for R

Dashboard for tracking key financial metrics of a portfolio made up of the Magnificent Seven stocks.

## Live Demo

- **Stable:** 
- **Preview:** 

## About

This dashboard is an individual re-implementation of my group project, originally built in Shiny for Python, now recreated in **Shiny for R**.

The app tracks key financial metrics for a portfolio composed of the Magnificent Seven stocks: Apple, Microsoft, Amazon, Alphabet, Meta, Nvidia, and Tesla. It allows users to interactively explore stock performance, compare trends across companies, and view financial indicators such as prices, returns, volatility, and portfolio behaviour relative to the S&P 500 index.

The goal of this assignment is to reproduce the core ideas of the original group project while implementing them in a different Shiny language framework.

## How to Run Locally

To set up and run the dashboard locally:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vytphan/dsci-532-individual-assignment.git
   ```

2. **Navigate to the repository folder:**
   ```bash
   cd dsci-532-individual-assignment
   ```

3. **Open R or RStudio and install required packages:**
   ```bash
   install.packages(c("shiny", "tidyverse"))
   install.packages(c("plotly", "DT"))
   ```

4. **Run the Shiny app:**
   ```bash
   shiny::runApp()
   ```

The dashboard will be available at the URL shown in the terminal (typically `http://127.0.0.1:8000`).
