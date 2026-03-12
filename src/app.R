library(shiny)
library(bslib)
library(dplyr)
library(plotly)
library(DT)
library(htmltools)

# Load data ------------------------------------------------------------------
close_df <- read.csv("../data/close.csv", stringsAsFactors = FALSE)
metric_df <- read.csv("../data/metric.csv", stringsAsFactors = FALSE)
spy_df <- read.csv("../data/spy.csv", stringsAsFactors = FALSE)
watchlist_df <- read.csv("../data/watchlist.csv", stringsAsFactors = FALSE)

close_df$Date <- as.Date(close_df$Date)
spy_df$Date <- as.Date(spy_df$Date)

if ("Date" %in% names(watchlist_df)) {
  watchlist_df$Date <- as.Date(watchlist_df$Date)
}

DATE_MIN <- min(close_df$Date, na.rm = TRUE)
DATE_MAX <- max(close_df$Date, na.rm = TRUE)

stocks <- setdiff(names(close_df), "Date")

# Make this match the actual ticker columns in watchlist.csv
watchlist_dict <- c(
  MU   = "Micron",
  AMD  = "AMD",
  NFLX = "Netflix",
  INTC = "Intel",
  QCOM = "Qualcomm",
  CRM  = "Salesforce"
)

# CSS ------------------------------------------------------------------------
dark_css <- HTML("
body, .bslib-page-fill {
  background-color: #131722 !important;
  color: #d1d4dc !important;
}

.card {
  background-color: #1e222d !important;
  border: 1px solid #2a2e39 !important;
  color: #d1d4dc !important;
  height: 100%;
  border-radius: 10px !important;
}

.card-header {
  background-color: #232837 !important;
  color: #e5e7eb !important;
  font-size: 1rem !important;
  font-weight: 700 !important;
  border-bottom: 1px solid #2a2e39 !important;
  padding: 14px 18px !important;
}

.bslib-sidebar-layout > .sidebar {
  background-color: #131722 !important;
  border-right: 1px solid #2a2e39 !important;
}

.bslib-sidebar-layout .sidebar,
.bslib-sidebar-layout .sidebar * {
  color: #d1d4dc !important;
}

.bslib-sidebar-layout .sidebar .form-control,
.bslib-sidebar-layout .sidebar select,
.bslib-sidebar-layout .sidebar input {
  background-color: #1e222d !important;
  color: #d1d4dc !important;
  border: 1px solid #2a2e39 !important;
}

.bslib-sidebar-layout .sidebar .selectize-input {
  background-color: #1e222d !important;
  color: #ffffff !important;
  border: 1px solid #2a2e39 !important;
}

.bslib-sidebar-layout .sidebar .selectize-dropdown {
  background-color: #1e222d !important;
  color: #ffffff !important;
  border: 1px solid #2a2e39 !important;
}

.bslib-sidebar-layout .sidebar .selectize-dropdown .option {
  background-color: #1e222d !important;
  color: #d1d4dc !important;
}

.bslib-sidebar-layout .sidebar .selectize-dropdown .active {
  background-color: #1f6aa5 !important;
  color: #ffffff !important;
}

.nav-tabs {
  background-color: #131722 !important;
  border-bottom: 1px solid #2a2e39 !important;
}

.nav-tabs .nav-link {
  color: #d1d4dc !important;
  background-color: transparent !important;
  border-color: transparent !important;
}

.nav-tabs .nav-link.active,
.nav-tabs .nav-item.show .nav-link {
  background-color: #1e222d !important;
  color: #ffffff !important;
  border-color: #2a2e39 #2a2e39 #1e222d !important;
}

.tab-content {
  background-color: #131722 !important;
}

.chart-card {
  min-height: 420px;
}

.watchlist-card {
  min-height: 420px;
}

.watchlist-card .card-body {
  padding: 16px 16px 10px 16px !important;
}

.watchlist-toggle-wrap {
  margin-bottom: 14px;
}

.watchlist-toggle-wrap .shiny-input-container {
  margin-bottom: 0 !important;
}

.watchlist-table-wrap {
  border-top: 1px solid rgba(255,255,255,0.10);
  padding-top: 10px;
}

/* switch */
.form-switch .form-check-input {
  background-color: #d9d9d9 !important;
  border-color: #d9d9d9 !important;
}

.form-switch .form-check-input:checked {
  background-color: #1f6aa5 !important;
  border-color: #1f6aa5 !important;
}

.form-check-label {
  color: #d1d4dc !important;
  font-size: 15px !important;
  font-weight: 600 !important;
}

/* DT */
table.dataTable {
  background-color: transparent !important;
  color: #d1d4dc !important;
  border-collapse: collapse !important;
  width: 100% !important;
}

table.dataTable thead th,
table.dataTable thead td {
  background-color: transparent !important;
  color: #d1d4dc !important;
  border-bottom: 1px solid rgba(255,255,255,0.18) !important;
  font-size: 15px !important;
  font-weight: 700 !important;
  padding: 8px 6px !important;
}

table.dataTable tbody tr {
  background-color: transparent !important;
}

table.dataTable tbody td {
  background-color: transparent !important;
  border-bottom: none !important;
  font-size: 15px !important;
  padding: 8px 6px !important;
}

table.dataTable.no-footer {
  border-bottom: none !important;
}

.dataTables_wrapper .dataTables_scrollBody {
  border-bottom: none !important;
  background-color: transparent !important;
}

.dataTables_wrapper .dataTables_scrollHead {
  border-bottom: none !important;
}

.dataTables_wrapper .dataTables_info,
.dataTables_wrapper .dataTables_length,
.dataTables_wrapper .dataTables_filter,
.dataTables_wrapper .dataTables_paginate {
  color: #d1d4dc !important;
}
")

# Helpers --------------------------------------------------------------------
empty_plot <- function(msg) {
  plot_ly() %>%
    layout(
      paper_bgcolor = "#131722",
      plot_bgcolor = "#1e222d",
      margin = list(l = 10, r = 10, t = 10, b = 10),
      annotations = list(
        list(
          text = msg,
          x = 0.5,
          y = 0.5,
          xref = "paper",
          yref = "paper",
          showarrow = FALSE,
          font = list(color = "#d1d4dc", size = 14)
        )
      )
    )
}

# UI -------------------------------------------------------------------------
ui <- page_fillable(
  title = "Stock Explorer",
  theme = bs_theme(
    version = 5,
    bg = "#131722",
    fg = "#d1d4dc",
    primary = "#1f6aa5",
    secondary = "#2a2e39",
    base_font = font_google("Inter", local = FALSE)
  ),
  tags$head(tags$style(dark_css)),
  
  navset_tab(
    id = "main_tabs",
    nav_panel(
      "Dashboard",
      layout_sidebar(
        sidebar = sidebar(
          bg = "#131722",
          dateRangeInput(
            inputId = "dates",
            label = "Select Date Range",
            start = DATE_MIN,
            end = DATE_MAX,
            min = DATE_MIN,
            max = DATE_MAX,
            format = "yyyy-mm-dd",
            separator = " - "
          ),
          selectizeInput(
            inputId = "ticker",
            label = "Highlight Ticker",
            choices = stocks,
            selected = if ("AAPL" %in% stocks) "AAPL" else stocks[1]
          ),
          open = "desktop"
        ),
        
        layout_columns(
          col_widths = c(6, 3, 3),
          
          card(
            class = "chart-card",
            full_screen = TRUE,
            card_header("Historical Closing Price Trend"),
            card_body(
              fill = TRUE,
              plotlyOutput("price_series_chart", height = "100%")
            )
          ),
          
          card(
            class = "chart-card",
            full_screen = TRUE,
            card_header("Portfolio Overview"),
            card_body(
              fill = TRUE,
              plotlyOutput("current_price_treemap", height = "100%")
            )
          ),
          
          card(
            class = "watchlist-card",
            full_screen = TRUE,
            card_header("Watchlist & Alerts"),
            card_body(
              div(
                class = "watchlist-toggle-wrap",
                input_switch("watchlist_toggle", "Show %", value = FALSE)
              ),
              div(
                class = "watchlist-table-wrap",
                DTOutput("watchlist_table")
              )
            )
          )
        )
      )
    )
  )
)

# Server ---------------------------------------------------------------------
server <- function(input, output, session) {
  
  filtered_close <- reactive({
    req(input$dates)
    close_df %>%
      filter(Date >= as.Date(input$dates[1]), Date <= as.Date(input$dates[2])) %>%
      arrange(Date)
  })
  
  # 1) Historical Closing Price Trend --------------------------------------------------
  output$price_series_chart <- renderPlotly({
    df <- filtered_close()
    
    if (is.null(df) || nrow(df) == 0) {
      return(empty_plot("No data available for the current filter."))
    }
    
    if (!("Date" %in% names(df)) || ncol(df) < 2) {
      return(empty_plot("No stock columns to plot."))
    }
    
    ticker_cols <- setdiff(names(df), "Date")
    if (length(ticker_cols) == 0) {
      return(empty_plot("No stock columns to plot."))
    }
    
    selected_ticker <- input$ticker
    
    fig <- plot_ly()
    
    for (col in ticker_cols) {
      is_selected <- identical(col, selected_ticker)
      
      line_color <- if (is_selected) {
        "#4da3ff"
      } else {
        "rgba(209, 212, 220, 0.22)"
      }
      
      line_width <- if (is_selected) 3 else 1.25
      
      fig <- fig %>%
        add_lines(
          data = df,
          x = ~Date,
          y = as.formula(paste0("~`", col, "`")),
          name = col,
          line = list(color = line_color, width = line_width),
          opacity = if (is_selected) 1 else 0.9,
          hovertemplate = paste0(
            "<b>%{x|%Y-%m-%d}</b><br>",
            col,
            ": $%{y:.2f}<extra></extra>"
          )
        )
    }
    
    fig %>%
      layout(
        paper_bgcolor = "#131722",
        plot_bgcolor = "#1e222d",
        margin = list(l = 10, r = 10, t = 30, b = 10),
        hovermode = "x unified",
        xaxis = list(
          title = "Date",
          showgrid = TRUE,
          gridcolor = "rgba(255,255,255,0.06)"
        ),
        yaxis = list(
          title = "Close Price ($)",
          showgrid = TRUE,
          gridcolor = "rgba(255,255,255,0.06)",
          tickprefix = "$"
        ),
        showlegend = TRUE,
        font = list(color = "#d1d4dc")
      )
  })
  # 2) Portfolio Overview Treemap --------------------------------------------
  output$current_price_treemap <- renderPlotly({
    df <- filtered_close()
    req(input$ticker)
    
    if (is.null(df) || nrow(df) < 2) {
      return(empty_plot("Need at least 2 rows to compute daily change."))
    }
    
    if (nrow(metric_df) == 0 || !all(c("Ticker", "MarketCap") %in% names(metric_df))) {
      return(empty_plot("metric.csv must contain Ticker and MarketCap columns."))
    }
    
    cur <- df[nrow(df), , drop = FALSE]
    prev <- df[nrow(df) - 1, , drop = FALSE]
    selected_ticker <- input$ticker
    
    GREEN <- "#44bb70"
    RED   <- "#d62728"
    GRAY  <- "#787b86"
    DIM_OPACITY <- 0.45
    
    labels <- c()
    values <- c()
    colors <- c()
    text_colors <- c()
    prices <- c()
    pcts <- c()
    text_info <- c()
    
    for (i in seq_len(nrow(metric_df))) {
      ticker <- as.character(metric_df$Ticker[i])
      
      if (!(ticker %in% names(cur)) || !(ticker %in% names(prev))) next
      
      current <- suppressWarnings(as.numeric(cur[[ticker]]))
      previous <- suppressWarnings(as.numeric(prev[[ticker]]))
      market_cap <- suppressWarnings(as.numeric(metric_df$MarketCap[i]))
      
      if (is.na(current) || is.na(previous) || is.na(market_cap) || previous == 0) next
      
      pct <- (current / previous - 1) * 100
      
      if (pct > 0) {
        base_color <- GREEN
        arrow <- "\u25B2"
      } else if (pct < 0) {
        base_color <- RED
        arrow <- "\u25BC"
      } else {
        base_color <- GRAY
        arrow <- "\u2022"
      }
      
      rgb_vals <- col2rgb(base_color)
      
      fill_color <- if (ticker == selected_ticker) {
        base_color
      } else {
        sprintf("rgba(%d,%d,%d,%.2f)", rgb_vals[1], rgb_vals[2], rgb_vals[3], DIM_OPACITY)
      }
      
      text_color <- if (ticker == selected_ticker) "#ffffff" else "#33414b"
      
      labels <- c(labels, ticker)
      values <- c(values, market_cap)
      colors <- c(colors, fill_color)
      text_colors <- c(text_colors, text_color)
      prices <- c(prices, current)
      pcts <- c(pcts, pct)
      text_info <- c(text_info, sprintf("%s<br>$%.2f %s %+.2f%%", ticker, current, arrow, pct))
    }
    
    if (length(labels) == 0) {
      return(empty_plot("No instruments available to plot."))
    }
    
    plot_ly(
      type = "treemap",
      labels = labels,
      parents = rep("", length(labels)),
      values = values,
      text = text_info,
      textinfo = "text",
      textposition = "middle center",
      marker = list(
        colors = colors,
        line = list(color = "#2a2e39", width = 2)
      ),
      customdata = Map(function(price, pct) list(price, pct), prices, pcts),
      hovertemplate = paste0(
        "<b>%{label}</b><br>",
        "Price: $%{customdata[0]:.2f}<br>",
        "Change: %{customdata[1]:+.2f}%<extra></extra>"
      ),
      pathbar = list(visible = FALSE),
      tiling = list(pad = 4)
    ) %>%
      style(
        textfont = list(color = text_colors, size = 18)
      ) %>%
      layout(
        paper_bgcolor = "#131722",
        plot_bgcolor = "#1e222d",
        font = list(color = "#d1d4dc"),
        margin = list(l = 10, r = 10, t = 10, b = 10)
      )
  })
  
  # 3) Watchlist --------------------------------------------------------------
  output$watchlist_table <- renderDT({
    validate(
      need(nrow(watchlist_df) >= 2, "Need at least 2 rows in watchlist.csv.")
    )
    
    current_prices <- watchlist_df[nrow(watchlist_df), , drop = FALSE]
    previous_prices <- watchlist_df[nrow(watchlist_df) - 1, , drop = FALSE]
    
    watchlist_data <- lapply(names(watchlist_dict), function(ticker) {
      if (!(ticker %in% names(current_prices)) || !(ticker %in% names(previous_prices))) {
        return(NULL)
      }
      
      current <- suppressWarnings(as.numeric(current_prices[[ticker]]))
      previous <- suppressWarnings(as.numeric(previous_prices[[ticker]]))
      
      if (is.na(current) || is.na(previous) || previous == 0) {
        return(NULL)
      }
      
      dollar_change <- current - previous
      percent_change <- (dollar_change / previous) * 100
      
      change_value <- if (isTRUE(input$watchlist_toggle)) {
        sprintf("%+.2f%%", percent_change)
      } else {
        sprintf("$%+.2f", dollar_change)
      }
      
      data.frame(
        Symbol = ticker,
        Change = change_value,
        RawChange = dollar_change,
        stringsAsFactors = FALSE
      )
    }) %>%
      bind_rows()
    
    validate(
      need(nrow(watchlist_data) > 0, "No matching ticker columns found in watchlist.csv.")
    )
    
    datatable(
      watchlist_data[, c("Symbol", "Change", "RawChange")],
      rownames = FALSE,
      escape = FALSE,
      selection = "none",
      class = "display compact",
      options = list(
        dom = "t",
        paging = FALSE,
        searching = FALSE,
        ordering = FALSE,
        info = FALSE,
        autoWidth = TRUE,
        scrollY = "260px",
        columnDefs = list(
          list(visible = FALSE, targets = 2)
        )
      )
    ) %>%
      formatStyle(
        columns = c("Symbol", "Change"),
        valueColumns = "RawChange",
        color = styleInterval(0, c("#ff2d2d", "#44bb70")),
        fontWeight = "600",
        backgroundColor = "transparent"
      )
  })
}

shinyApp(ui = ui, server = server)