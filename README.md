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

Users can interactively:

- Explore stock price trends
- Monitor a watchlist of selected stocks

The goal of this assignment is to reproduce the core ideas of the original group project while implementing them in a different **Shiny language framework**.

---

# How to Run Locally

Follow these steps to run the dashboard locally.

1. Clone the repository

```bash
git clone https://github.com/vytphan/dsci-532-individual-assignment.git
```

2. **Navigate to the repository folder:**
   ```bash
   cd dsci-532-individual-assignment
   ```

3. **Open R or RStudio and install required packages:**
   ```bash
   nstall.packages(c("shiny", "tidyverse", "plotly", "DT", "bslib", "htmltools"))
   ```

4. **Run the Shiny app:**
   ```bash
   shiny::runApp("src")
   ```

The dashboard will be available at the URL shown in the terminal (typically `http://127.0.0.1:3838`).