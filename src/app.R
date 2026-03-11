library(shiny)
library(bslib)
library(dplyr)
library(plotly)
library(ggridges)
library(ggplot2)

ui <- page_fillable(
  title = "Magnificent 7 Stock Explorer",

  tags$style(HTML("
/* Finviz-style strip */
.tickerstrip {
  display: flex;
  align-items: stretch;
  border: 1px solid #2a2e39;
  border-radius: 10px;
  overflow: hidden;
  background: #1e222d;
}

/* Each tile */
.tickerbox {
  flex: 1;
  padding: 10px 10px 8px 10px;
  min-width: 0;
  text-align: left;
}

/* Thin vertical separators between boxes */
.tickerbox + .tickerbox {
  border-left: 1px solid #2a2e39;
}

.tickerbox-ticker {
  font-weight: 700;
  font-size: 12px;
  letter-spacing: 0.04em;
  color: #d1d4dc;
  text-transform: uppercase;
  margin-bottom: 4px;
}

/* Price row */
.tickerbox-price {
  font-weight: 700;
  font-size: 16px;
  color: #ffffff;
  line-height: 1.1;
}

/* Return row */
.tickerbox-ret {
  margin-top: 4px;
  font-weight: 600;
  font-size: 12px;
  line-height: 1.1;
  display: inline-flex;
  gap: 6px;
  align-items: center;
}

.ret-pos { color: #44bb70; }
.ret-neg { color: #d62728; }
.ret-flat { color: #9aa0a6; }

/* Arrow style */
.ret-arrow {
  font-size: 12px;
  opacity: 0.95;
}

/* Subtle hover like finviz */
.tickerbox:hover {
  background: #232a37;
}

/* Small screens */
@media (max-width: 900px) {
  .tickerstrip {
    overflow-x: auto;
  }
  .tickerbox {
    flex: 0 0 140px;
  }
}

/* Fix DataGrid hover in dark mode */
.shiny-data-grid table tbody tr:hover {
  background-color: #2a3a4a !important;
  color: #ffffff !important;
}

.shiny-data-grid table tbody tr:hover td {
  background-color: #2a3a4a !important;
  color: #ffffff !important;
}

[data-row]:hover {
  background-color: #2a3a4a !important;
  color: #ffffff !important;
}

/* Card header title */
.card-header {
  font-size: 1rem !important;
}

/* Labels and controls */
label[for='metrics_sort_by'],
label[for='metrics_sort_dir'] {
  font-size: 0.875rem !important;
}

/* Sort by */
#metrics_sort_by {
  font-size: 0.875rem !important;
  background-color: #ffffff !important;
  color: #000000 !important;
  border: 1px solid #cccccc !important;
}

.selectize-control .selectize-dropdown {
  font-size: 0.875rem !important;
  background-color: #ffffff !important;
  color: #000000 !important;
}

#metrics_sort_dir label {
  font-size: 0.875rem !important;
}

/* Table cells */
.shiny-data-grid table td,
.shiny-data-grid table th {
  font-size: 0.8125rem !important;
}

/* Risk-return dropdown */
#rr_period + .selectize-control .selectize-input {
  font-size: 0.875rem !important;
}

#rr_period + .selectize-control .selectize-dropdown {
  font-size: 0.875rem !important;
}

/* Sidebar */
.bslib-sidebar-layout .sidebar,
.bslib-sidebar-layout .sidebar * {
  color: #d1d4dc !important;
}

.bslib-sidebar-layout .sidebar label,
.bslib-sidebar-layout .sidebar .control-label,
.bslib-sidebar-layout .sidebar .shiny-input-container label {
  color: #d1d4dc !important;
}

.bslib-sidebar-layout .sidebar .form-control,
.bslib-sidebar-layout .sidebar select,
.bslib-sidebar-layout .sidebar textarea,
.bslib-sidebar-layout .sidebar input {
  background-color: #1e222d !important;
  color: #d1d4dc !important;
  border: 1px solid #2a2e39 !important;
}

.bslib-sidebar-layout > .sidebar {
  background-color: #131722 !important;
}

.bslib-sidebar-layout .sidebar .selectize-input {
  background-color: #1e222d !important;
  color: #ffffff !important;
}

.bslib-sidebar-layout .sidebar .selectize-input input {
  color: #ffffff !important;
}

.bslib-sidebar-layout .sidebar .selectize-dropdown {
  background-color: #1e222d !important;
  color: #ffffff !important;
  border: 1px solid #2a2e39 !important;
}

.bslib-sidebar-layout .sidebar .selectize-dropdown .option {
  color: #d1d4dc !important;
}

.bslib-sidebar-layout .sidebar .selectize-dropdown .option.active {
  background-color: #1f6aa5 !important;
  color: #ffffff !important;
}
  ")),

  layout_sidebar(
    sidebar = sidebar(
      "Sidebar inputs go here",
      open = "desktop"
    ),

    "Main content goes here"
  )
)

# -----------------------------------------------------------------------------
# Reactive Data Calculations
# -----------------------------------------------------------------------------

filtered_close <- reactive({
  req(input$dates)

  close_df %>%
    filter(Date >= as.Date(input$dates[1]),
           Date <= as.Date(input$dates[2]))
})

current_price <- reactive({
  req(input$ticker)

  ticker <- input$ticker

  if (!(ticker %in% names(close_df))) {
    return(NULL)
  }

  as.numeric(tail(close_df[[ticker]], 1))
})

selected_stock_series <- reactive({
  req(input$ticker)

  ticker <- input$ticker
  df <- filtered_close()

  if (!(ticker %in% names(df))) {
    return(numeric(0))
  }

  df %>%
    select(Date, all_of(ticker))
})

rr_tickers <- setdiff(names(close_df), "Date")

padded_range <- function(vals, pad_frac = 0.15) {
  vals <- as.numeric(vals)
  vals <- vals[!is.na(vals)]

  if (length(vals) == 0) {
    return(NULL)
  }

  vmin <- min(vals)
  vmax <- max(vals)

  if (isTRUE(all.equal(vmin, vmax))) {
    pad <- ifelse(vmin != 0, abs(vmin) * pad_frac, 0.01)
    return(c(vmin - pad, vmax + pad))
  }

  pad <- (vmax - vmin) * pad_frac
  c(vmin - pad, vmax + pad)
}

analysis_close <- reactive({
  req(input$dates, input$rr_period)

  df <- close_df %>%
    filter(Date >= as.Date(input$dates[1]),
           Date <= as.Date(input$dates[2])) %>%
    arrange(Date)

  if (nrow(df) == 0) {
    return(df)
  }

  period <- input$rr_period

  if (period == "Full") {
    return(df)
  }

  years <- c("1Y" = 1, "5Y" = 5, "10Y" = 10)[period]
  end_date <- max(df$Date)
  start_date <- end_date %m-% years(as.numeric(years))

  df %>%
    filter(Date >= start_date)
})

risk_return_df <- reactive({
  req(input$rr_period)

  df <- analysis_close()
  period <- input$rr_period

  if (nrow(df) == 0) {
    return(data.frame(Ticker = character(),
                      AnnReturn = numeric(),
                      AnnVol = numeric()))
  }

  prices <- df %>%
    select(Date, all_of(rr_tickers))

  if (period != "Full") {
    years_n <- as.numeric(gsub("Y", "", period))
    cutoff <- Sys.Date() %m-% years(years_n)
    prices <- prices %>% filter(Date >= cutoff)
  }

  prices_mat <- prices %>%
    select(-Date)

  rets <- prices_mat / dplyr::lag(prices_mat) - 1
  rets <- rets[-1, , drop = FALSE]

  if (nrow(rets) == 0) {
    return(data.frame(Ticker = character(),
                      AnnReturn = numeric(),
                      AnnVol = numeric()))
  }

  mean_daily <- sapply(rets, function(x) mean(x, na.rm = TRUE))
  std_daily  <- sapply(rets, function(x) sd(x, na.rm = TRUE))

  out <- data.frame(
    Ticker = names(mean_daily),
    AnnReturn = as.numeric(mean_daily) * 252,
    AnnVol = as.numeric(std_daily) * sqrt(252)
  )

  out %>%
    filter(!is.na(AnnReturn), !is.na(AnnVol))
})

# ---- UI ----
ui <- page_fillable(
  title = "Magnificent 7 Stock Explorer",

  tags$style(HTML("
    .bslib-sidebar-layout > .sidebar {
      background-color: #131722 !important;
      color: #d1d4dc !important;
    }
  ")),

  navset_tab(
    id = "main_tabs",

    nav_panel(
      "Dashboard",

      layout_sidebar(
        sidebar = sidebar(
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
            label = "Select Stock",
            choices = stocks,
            selected = "AAPL"
          )
        ),

        layout_columns(
          col_widths = c(7, 3, 2),

          card(
            full_screen = TRUE,
            card_header("Historical Closing Price Trend"),
            plotlyOutput("stock_price_chart")
          )

          # add your other cards here
          # ,card(...)
          # ,card(...)
        )
      )
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {

  filtered_close <- reactive({
    req(input$dates)

    close_df %>%
      filter(
        Date >= as.Date(input$dates[1]),
        Date <= as.Date(input$dates[2])
      )
  })

  output$stock_price_chart <- renderPlotly({
    req(input$ticker)

    ticker <- input$ticker
    df <- filtered_close()

    if (nrow(df) == 0 || !(ticker %in% names(df))) {
      fig <- plot_ly()
      fig <- fig %>% layout(
        template = "plotly_dark",
        autosize = TRUE,
        paper_bgcolor = "#131722",
        plot_bgcolor = "#1e222d",
        margin = list(l = 10, r = 10, t = 10, b = 10),
        annotations = list(
          list(
            text = "No data available for the selected range/ticker.",
            x = 0.5, y = 0.5,
            xref = "paper", yref = "paper",
            showarrow = FALSE,
            font = list(color = "#d1d4dc", size = 14)
          )
        )
      )
      return(fig)
    }

    df <- df %>% arrange(Date)
    x <- df$Date
    y <- as.numeric(df[[ticker]])

    start_price <- y[1]
    end_price <- y[length(y)]
    pct_change <- if (!is.na(start_price) && start_price != 0) {
      (end_price / start_price - 1) * 100
    } else {
      0
    }

    pct_color <- if (pct_change >= 0) "#44bb70" else "#d62728"

    plot_ly(
      data = df,
      x = ~Date,
      y = as.formula(paste0("~`", ticker, "`")),
      type = "scatter",
      mode = "lines",
      line = list(color = "#2962ff", width = 2.5),
      hovertemplate = paste0(
        "<b>%{x|%Y-%m-%d}</b><br>",
        ticker, ": $%{y:.2f}<extra></extra>"
      )
    ) %>%
      layout(
        template = "plotly_dark",
        paper_bgcolor = "#131722",
        plot_bgcolor = "#1e222d",
        margin = list(l = 10, r = 10, t = 30, b = 10),
        hovermode = "x unified",
        xaxis = list(
          title = "Date",
          showgrid = TRUE,
          gridcolor = "rgba(255,255,255,0.06)",
          rangeslider = list(visible = TRUE),
          rangeselector = NULL
        ),
        yaxis = list(
          title = "Close Price ($)",
          showgrid = TRUE,
          gridcolor = "rgba(255,255,255,0.06)",
          tickprefix = "$"
        ),
        title = list(
          text = paste0(
            ticker,
            " Close Price  <span style='color:",
            pct_color,
            "; font-size:12px;'>(",
            sprintf("%+.2f", pct_change),
            "%)</span>"
          ),
          x = 0.01,
          xanchor = "left",
          font = list(size = 16, color = "#d1d4dc")
        ),
        showlegend = FALSE
      )
  })
}

# ---- UI card ----
card(
  card_header("Portfolio Overview"),
  plotlyOutput("current_price_treemap")
)

# ---- Server output ----
output$current_price_treemap <- renderPlotly({
  req(input$ticker)

  selected_ticker <- input$ticker
  cur <- close_df[nrow(close_df), ]
  prev <- close_df[nrow(close_df) - 1, ]

  GREEN <- "#44bb70"
  RED <- "#d62728"
  GRAY <- "#787b86"
  DIM_OPACITY <- 0.45

  labels <- c()
  values <- c()
  text_info <- c()
  colors <- c()
  custom_price <- c()
  custom_pct <- c()

  for (i in seq_len(nrow(metric_df))) {
    ticker <- as.character(metric_df$Ticker[i])

    if (!(ticker %in% names(close_df))) next

    market_cap <- metric_df$MarketCap[i]
    current <- as.numeric(cur[[ticker]])
    previous <- as.numeric(prev[[ticker]])

    pct <- if (is.na(previous) || previous == 0) {
      0
    } else {
      (current / previous - 1) * 100
    }

    if (pct > 0.05) {
      base_color <- GREEN
      arrow <- "\u25B2"
    } else if (pct < -0.05) {
      base_color <- RED
      arrow <- "\u25BC"
    } else {
      base_color <- GRAY
      arrow <- "\u2022"
    }

    is_selected <- ticker == selected_ticker

    if (is_selected) {
      fill_color <- base_color
    } else {
      rgb <- col2rgb(base_color)
      fill_color <- sprintf(
        "rgba(%d,%d,%d,%.2f)",
        rgb[1], rgb[2], rgb[3], DIM_OPACITY
      )
    }

    labels <- c(labels, ticker)
    values <- c(values, market_cap)
    text_info <- c(text_info, sprintf("$%s %s%.2f%%", format(round(current, 2), big.mark = ","), arrow, pct))
    colors <- c(colors, fill_color)
    custom_price <- c(custom_price, current)
    custom_pct <- c(custom_pct, pct)
  }

  customdata <- cbind(custom_price, custom_pct)

  plot_ly(
    type = "treemap",
    labels = labels,
    parents = rep("", length(labels)),
    values = values,
    text = text_info,
    textposition = "middle center",
    customdata = customdata,
    marker = list(
      colors = colors,
      line = list(color = "#2a2e39", width = 2)
    ),
    hovertemplate = paste0(
      "<b>%{label}</b><br>",
      "Price: $%{customdata[0]:,.2f}<br>",
      "Change: %{customdata[1]:+.2f}%<br>",
      "Market Cap: $%{value:,.0f}<extra></extra>"
    )
  ) %>%
    layout(
      paper_bgcolor = "#131722",
      plot_bgcolor = "#1e222d",
      font = list(color = "#d1d4dc", size = 14),
      margin = list(l = 10, r = 10, t = 10, b = 10)
    )
})

# ---- UI card ----
card(
  card_header("Watchlist & Alerts"),
  input_switch("watchlist_toggle", "Show as $ or %", value = FALSE),
  DTOutput("watchlist_table")
)

# ---- Server output ----
output$watchlist_table <- renderDT({
  req(nrow(watchlist_df) >= 2)

  current_prices <- watchlist_df[nrow(watchlist_df), ]
  previous_prices <- watchlist_df[nrow(watchlist_df) - 1, ]

  watchlist_data <- lapply(names(watchlist_dict), function(ticker) {
    current <- as.numeric(current_prices[[ticker]])
    previous <- as.numeric(previous_prices[[ticker]])

    dollar_change <- current - previous
    percent_change <- if (!is.na(previous) && previous != 0) {
      (dollar_change / previous) * 100
    } else {
      NA_real_
    }

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

  datatable(
    watchlist_data %>% select(Symbol, Change),
    rownames = FALSE,
    escape = FALSE,
    options = list(
      dom = "t",
      paging = FALSE,
      searching = FALSE,
      ordering = FALSE
    )
  ) %>%
    formatStyle(
      columns = c("Symbol", "Change"),
      valueColumns = "RawChange",
      color = styleInterval(0, c("#d62728", "#44bb70")),
      fontWeight = "600",
      backgroundColor = "transparent"
    )
})

# Create app
shinyApp(ui = ui, server = server)
