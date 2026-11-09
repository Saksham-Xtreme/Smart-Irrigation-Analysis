# ============================================================
# SMART IRRIGATION ANALYTICS DASHBOARD  (R Shiny + Plotly + DT)
# Design: dark Basedash stage + warm Steep colour surfaces
#
# PERFORMANCE NOTES (what changed vs. the previous version)
#  1. Hover: Plotly is resized ONCE, after the card transition ends
#     (event-driven via transitionrun/transitionend), never per frame.
#     While cards move the charts crossfade, so nothing stretches.
#  2. Filtering: one integer index vector (`row_idx`) is computed once per
#     filter change and shared by everything that needs raw rows.
#  3. KPIs, donut and the three stacked-bar charts read from a tiny
#     pre-aggregated table (a few hundred rows) instead of 630,000 rows.
#     The numbers are exact: means are sum/count, shares are counts.
#  4. Plots are cached per filter combination (bindCache).
#  5. The table's display columns are rounded ONCE at start-up.
#  6. CSV export is explicit (all 21 columns, every filtered row) and
#     shows a "preparing" notification while the file is written.
#  7. Hero glow animates `transform` only (compositor), no blur filter.
# Run from the project root:  shiny::runApp("app.R")
# ============================================================

library(shiny)
library(tidyverse)
library(plotly)
library(DT)
library(scales)

# -------------------- DATA LOADING ---------------------------

data_path <- "data/processed/cleaned_irrigation_data.csv"

if (!file.exists(data_path)) {
  stop("Dataset not found. Set the working directory to the project root ",
       "(the folder that contains 'data/').")
}

irrigation_data <- read_csv(data_path, show_col_types = FALSE) %>%
  mutate(
    Irrigation_Need = factor(Irrigation_Need, levels = c("Low", "Medium", "High")),
    across(c(Crop_Type, Season, Region, Soil_Type), as.factor)
  )

n_total <- nrow(irrigation_data)

# Pre-aggregated summary: one row per Crop x Season x Region x Demand.
# Sums let us recompute exact means for any filter without touching raw rows.
agg_data <- irrigation_data %>%
  group_by(Crop_Type, Season, Region, Irrigation_Need) %>%
  summarise(n = n(),
            sum_moisture = sum(Soil_Moisture),
            sum_rain = sum(Rainfall_mm),
            .groups = "drop")

# Table columns, selected and rounded once (not on every filter change).
table_data <- irrigation_data %>%
  select(Soil_Type, Soil_Moisture, Temperature_C, Rainfall_mm,
         Crop_Type, Season, Region, Irrigation_Need) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)))

# -------------------- DESIGN TOKENS --------------------------

ink      <- "#FFFFFF"
ash      <- "#B3B3B3"
steel    <- "#808080"
graphite <- "#333333"
carbon   <- "#050607"

demand_colors <- c("Low" = "#3FCB7F", "Medium" = "#9984D8", "High" = "#E8EAEE")

plot_font <- list(family = "Inter, Arial, sans-serif", color = ash, size = 13)

style_plot <- function(p, ...) {
  p %>%
    layout(
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor  = "rgba(0,0,0,0)",
      font = plot_font,
      hoverlabel = list(bgcolor = carbon, bordercolor = graphite,
                        font = list(color = ink, size = 13)),
      ...
    ) %>%
    # scrollZoom OFF: the mouse wheel must keep scrolling the page
    config(displayModeBar = "hover", displaylogo = FALSE, scrollZoom = FALSE,
           responsive = TRUE, doubleClick = "reset",
           modeBarButtonsToRemove = list("lasso2d", "select2d", "autoScale2d"))
}

axis_style <- function(title = NULL, ...) {
  list(title = list(text = title, font = list(color = steel, size = 12)),
       gridcolor = "rgba(255,255,255,0.07)", zeroline = FALSE,
       linecolor = graphite, tickfont = list(color = steel, size = 12), ...)
}

# -------------------- UI HELPERS ----------------------------

card <- function(title, subtitle, output_id) {
  div(class = "card",
      div(class = "card-head",
          div(class = "card-title", title),
          div(class = "card-sub", subtitle)),
      div(class = "card-body", plotlyOutput(output_id, height = "100%")))
}

kpi <- function(tone, label, output_id, hint, live = FALSE) {
  div(class = paste("kpi", tone),
      div(class = "kpi-label",
          label, if (live) span(class = "live", span(class = "dot"), "Live")),
      div(class = "kpi-value", textOutput(output_id, inline = TRUE)),
      div(class = "kpi-hint", hint))
}

# -------------------- USER INTERFACE ------------------------

ui <- fluidPage(
  title = "Smart Irrigation Analytics",
  
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(
      rel = "stylesheet",
      href = paste0("https://fonts.googleapis.com/css2?",
                    "family=Inter:wght@400;500;600&",
                    "family=Cormorant+Garamond:wght@400;500&display=swap")
    ),
    
    tags$style(HTML("
      :root {
        --void: #000; --carbon: #050607; --white: #fff; --bone: #E8EAEE;
        --ash: #B3B3B3; --steel: #808080; --graphite: #333;
        --violet: #9984D8; --mint: #3FCB7F;
        --peach: #FBE1D1; --sienna: #5D2A1A; --mist: #F2F2F3; --ink: #17191C; --slate: #777B86;
        --serif: 'Cormorant Garamond', 'EB Garamond', Georgia, serif;
        --sans: 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
        --ease: cubic-bezier(.25,.8,.25,1);
      }
      html, body { background: var(--void); }
      body { font-family: var(--sans); color: var(--ash); font-size: 16px; line-height: 1.5;
             letter-spacing: -0.03em; -webkit-font-smoothing: antialiased; }
      * { letter-spacing: inherit; }
      .container-fluid { max-width: 1200px; margin: 0 auto; padding: 0 24px 48px; position: relative; }
      .container-fluid > *:not(.glow) { position: relative; z-index: 1; }

      /* ---- hero glow: static gradients, animated with transform only ---- */
      .glow { position: absolute; left: 50%; top: -140px; width: 1100px; height: 640px;
              margin-left: -550px; pointer-events: none; z-index: 0; will-change: transform;
              background:
                radial-gradient(ellipse 40% 50% at 30% 45%, rgba(163,102,255,.34), transparent 70%),
                radial-gradient(ellipse 36% 46% at 70% 40%, rgba(63,203,127,.16), transparent 70%),
                radial-gradient(ellipse 45% 55% at 50% 60%, rgba(251,225,209,.10), transparent 70%);
              animation: drift 18s ease-in-out infinite alternate; }
      @keyframes drift { from { transform: translate3d(-3%, 0, 0) scale(1); }
                         to   { transform: translate3d(3%, 2%, 0) scale(1.06); } }

      /* ---- nav ---- */
      .topbar { display: flex; align-items: center; justify-content: space-between; height: 64px; }
      .brand { display: flex; align-items: center; gap: 10px; color: var(--white); font-weight: 500; }
      .logo { width: 24px; height: 24px; border-radius: 6px; border: 1px solid var(--steel);
              display: grid; place-items: center; }
      .logo i { width: 8px; height: 8px; border-radius: 50%; background: var(--violet); display: block; }
      .topbar-note { font-size: 14px; color: var(--steel); }

      .badge-pill { display: inline-flex; align-items: center; gap: 8px; padding: 4px 12px;
                    border: 1px solid var(--steel); border-radius: 999px; font-size: 13px;
                    font-weight: 500; color: var(--white); background: rgba(0,0,0,.35); }
      .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--mint); display: inline-block;
             box-shadow: 0 0 8px rgba(63,203,127,.8); }

      /* ---- hero ---- */
      .hero { text-align: center; padding: 64px 0 40px; }
      .hero h1 { font-family: var(--serif); font-weight: 400; font-size: 48px; line-height: 1;
                 letter-spacing: 0; color: var(--white); margin: 24px auto 20px; max-width: 760px; }
      .hero p { font-size: 18px; line-height: 1.56; max-width: 640px; margin: 0 auto; }

      /* ---- filter bar ---- */
      .container-fluid > .filters {
        position: sticky; top: 12px; z-index: 30;
        display: flex; flex-wrap: wrap; gap: 12px; align-items: flex-end;
        padding: 16px 20px; background: var(--mist); border-radius: 16px; margin-bottom: 16px;
        box-shadow: 0 10px 40px rgba(0,0,0,.55);
      }
      .filters .form-group { margin: 0; flex: 1 1 150px; min-width: 140px; }
      .filters label { font-size: 13px; font-weight: 500; color: var(--slate); margin: 0 0 6px; }
      .filters select.form-control {
        height: 40px; border-radius: 6px; background-color: #fff; color: var(--ink);
        border: 1px solid #E1E1E4; box-shadow: none; font-size: 14px; padding: 0 12px; }
      .filters select.form-control:hover { border-color: #b9bbc2; }
      .filters select.form-control:focus { border-color: var(--ink); box-shadow: none; }
      .btn-wrap { display: flex; gap: 10px; flex: 0 0 auto; }

      .btn.pill { display: inline-flex; align-items: center; justify-content: center; height: 40px;
                  padding: 0 20px; border-radius: 6px; font-size: 14px; font-weight: 500; line-height: 1;
                  box-shadow: none !important; text-decoration: none !important;
                  transition: background .15s, color .15s, border-color .15s; }
      .btn.pill-solid { background: var(--ink) !important; color: #fff !important; border: 1px solid var(--ink) !important; }
      .btn.pill-solid:hover { background: #33363c !important; }
      .btn.pill-ghost { background: transparent !important; color: var(--ink) !important; border: 1px solid #c9cbd1 !important; }
      .btn.pill-ghost:hover { border-color: var(--ink) !important; }
      .pill:focus-visible, select:focus-visible { outline: 2px solid var(--violet); outline-offset: 2px; }

      /* ---- KPI cards ---- */
      .kpi-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
      .kpi { border-radius: 16px; padding: 20px 22px 18px; min-height: 148px; display: flex;
             flex-direction: column; transition: transform .25s var(--ease); }
      .kpi:hover { transform: translateY(-3px); }
      .kpi-label { font-size: 14px; font-weight: 500; opacity: .8; }
      .kpi-value { font-size: 40px; font-weight: 600; line-height: 1.1; letter-spacing: -0.04em;
                   margin: auto 0 4px; padding-top: 14px; font-variant-numeric: tabular-nums; }
      .kpi-hint { font-size: 13px; opacity: .7; }
      .kpi.peach  { background: var(--peach);  color: var(--sienna); }
      .kpi.violet { background: var(--violet); color: #140b30; }
      .kpi.mint   { background: var(--mint);   color: #052713; }
      .kpi.bone   { background: var(--bone);   color: var(--ink); }
      .live { float: right; display: inline-flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 600; }
      .kpi.peach .dot { background: var(--sienna); box-shadow: none; }

      /* ---- section heads ---- */
      .section-head { text-align: center; margin: 88px auto 32px; }
      .section-head h2 { font-family: var(--serif); font-weight: 400; font-size: 48px; line-height: 1;
                         letter-spacing: 0; color: var(--white); margin: 0 0 16px; }
      .section-head p { font-size: 18px; max-width: 640px; margin: 0 auto; }

      /* ---- chart rows: fixed height, width-only expansion ---- */
      .flex-row { display: flex; gap: 16px; height: 520px; margin-bottom: 16px; }
      .card { flex: 1 1 0; min-width: 0; height: 100%; display: flex; flex-direction: column;
              overflow: hidden;                     /* nothing may spill into a neighbour */
              background: var(--carbon); border: 1px solid #16171a; border-radius: 16px;
              padding: 20px 16px 10px; contain: layout paint;
              transition: flex-grow .45s var(--ease), opacity .3s var(--ease), border-color .3s; }
      .card-head { padding: 0 4px; flex: 0 0 auto; }
      .card-title { font-size: 16px; font-weight: 500; color: var(--white); }
      .card-sub { font-size: 13px; color: var(--steel); margin: 2px 0 12px; }
      .card-body { flex: 1 1 auto; min-height: 0; position: relative; overflow: hidden; }
      .card-body .html-widget { position: absolute !important; inset: 0; width: 100% !important;
                                height: 100% !important; transition: opacity .3s ease; }

      /* While cards move, the chart fades; it is resized once, then fades back in. */
      .flex-row.moving .card-body .html-widget { opacity: .12; transition-duration: .12s; }

      /* Expansion only on devices that can really hover */
      @media (hover: hover) and (pointer: fine) {
        .flex-row.has-active .card { flex-grow: .62; opacity: .6; }
        .flex-row.has-active .card.active { flex-grow: 2.1; opacity: 1; border-color: #3a3b40; }
      }

      .modebar { background: transparent !important; }
      .modebar-btn path { fill: var(--steel) !important; }
      .modebar-btn:hover path { fill: var(--white) !important; }

      /* ---- insight ---- */
      .insight-card { background: var(--peach); color: var(--sienna); border-radius: 24px;
                      padding: 56px 48px; margin: 56px 0 16px; text-align: center; }
      .insight-card h3 { font-family: var(--serif); font-weight: 500; font-size: 48px; line-height: 1;
                         letter-spacing: 0; color: var(--sienna); margin: 0 auto 24px; max-width: 800px; }
      .insight-card p { font-size: 18px; line-height: 1.56; max-width: 640px; margin: 0 auto 10px; color: var(--sienna); }
      .insight-card .fine { font-size: 13px; opacity: .75; margin-top: 20px; }

      /* ---- table ---- */
      .table-card { background: #fff; border-radius: 24px; padding: 24px; color: var(--ink); }
      .dataTables_wrapper { color: var(--slate); font-size: 14px; position: relative; }
      table.dataTable { border-collapse: collapse !important; color: var(--ink); background: transparent; }
      table.dataTable thead th, table.dataTable thead td { border-bottom: 1px solid #E4E4E7 !important;
        color: var(--slate); font-weight: 500; }
      table.dataTable tbody tr { background: transparent !important; }
      table.dataTable tbody td { border-top: 1px solid #F2F2F3 !important; padding: 10px; }
      table.dataTable.hover tbody tr:hover { background: #FAFAFB !important; }
      .dataTables_wrapper input, .dataTables_wrapper select { background: #fff; color: var(--ink);
        border: 1px solid #E1E1E4; border-radius: 6px; padding: 4px 8px; outline: none; }
      .dataTables_wrapper .dataTables_paginate .paginate_button { color: var(--slate) !important;
        border-radius: 6px !important; border: 1px solid transparent !important; }
      .dataTables_wrapper .dataTables_paginate .paginate_button.current,
      .dataTables_wrapper .dataTables_paginate .paginate_button.current:hover {
        background: var(--ink) !important; color: #fff !important; border: 1px solid var(--ink) !important; }
      .dataTables_wrapper .dataTables_paginate .paginate_button:hover { background: var(--mist) !important; color: var(--ink) !important; }
      /* loading state while the server prepares a table page */
      .dataTables_wrapper .dataTables_processing { background: var(--ink); color: #fff; border: 0;
        border-radius: 999px; padding: 8px 18px; font-size: 13px; width: auto; height: auto;
        margin: 0; transform: translate(-50%, -50%); z-index: 5; }

      .footer { text-align: center; color: var(--steel); font-size: 13px; padding: 56px 0 8px; }
      .shiny-output-error-validation { color: var(--steel); padding: 40px 12px; font-size: 14px; text-align: center; }

      /* ---- responsive ---- */
      @media (max-width: 1000px) { .container-fluid > .filters { position: relative; top: 0; } }
      @media (max-width: 900px) {
        .kpi-row { grid-template-columns: 1fr 1fr; }
        .flex-row { flex-direction: column; height: auto; }
        .card { height: 420px; }
        .hero h1, .section-head h2, .insight-card h3 { font-size: 38px; }
        .insight-card { padding: 40px 24px; }
      }
      @media (max-width: 520px) { .kpi-row { grid-template-columns: 1fr; } }
      @media (prefers-reduced-motion: reduce) {
        .glow { animation: none; }
        .card, .kpi, .card-body .html-widget { transition: none !important; }
      }
    ")),
    
    tags$script(HTML("
      $(function () {
        var fine   = window.matchMedia('(hover: hover) and (pointer: fine)');
        var reduce = window.matchMedia('(prefers-reduced-motion: reduce)');

        /* One resize per row, only when the layout has settled. */
        function settle(row) {
          $(row).find('.js-plotly-plot').each(function () {
            try { Plotly.Plots.resize(this); } catch (err) {}
          });
          $(row).removeClass('moving');
        }

        function setActive($r, $c) {
          var changed = $c ? !$c.hasClass('active') : $r.hasClass('has-active');
          if (!changed) return;
          $r.data('running', 0);
          if (!reduce.matches) $r.addClass('moving');
          if ($c) {
            $r.addClass('has-active');
            $r.find('.card').removeClass('active');
            $c.addClass('active');
          } else {
            $r.removeClass('has-active').find('.card').removeClass('active');
          }
          if (reduce.matches) requestAnimationFrame(function () { settle($r[0]); });
        }

        /* Track running flex-grow transitions; resize when the last one ends. */
        function isFlex(e) {
          return e.originalEvent.propertyName === 'flex-grow' && e.target === e.currentTarget;
        }
        $(document).on('transitionrun', '.flex-row .card', function (e) {
          if (!isFlex(e)) return;
          var $r = $(this).closest('.flex-row');
          $r.data('running', ($r.data('running') || 0) + 1);
        });
        $(document).on('transitionend transitioncancel', '.flex-row .card', function (e) {
          if (!isFlex(e)) return;
          var $r = $(this).closest('.flex-row');
          var left = ($r.data('running') || 1) - 1;
          $r.data('running', left);
          if (left <= 0) settle($r[0]);
        });

        /* Hover intent: open after a brief dwell, close after a short grace
           period so crossing the gap between cards never flickers. */
        $(document).on('mouseenter', '.flex-row', function () {
          clearTimeout($(this).data('leave'));
        });
        $(document).on('mouseenter', '.flex-row .card', function () {
          if (!fine.matches) return;
          var $c = $(this), $r = $c.closest('.flex-row');
          clearTimeout($r.data('leave'));
          clearTimeout($r.data('enter'));
          $r.data('enter', setTimeout(function () { setActive($r, $c); }, 60));
        });
        $(document).on('mouseleave', '.flex-row', function () {
          if (!fine.matches) return;
          var $r = $(this);
          clearTimeout($r.data('enter'));
          $r.data('leave', setTimeout(function () { setActive($r, null); }, 200));
        });

        /* Count-up animation for KPI numbers (skipped for reduced motion). */
        function parse(t) {
          var m = t.replace(/,/g, '').match(/^(-?[0-9.]+)(.*)$/);
          if (!m) return null;
          return { v: parseFloat(m[1]), d: (m[1].split('.')[1] || '').length, suf: m[2] };
        }
        function fmt(n, d, suf) {
          return n.toLocaleString('en-US', { minimumFractionDigits: d, maximumFractionDigits: d }) + suf;
        }
        $('.kpi-value').each(function () {
          var el = this, from = 0, shown = '', raf = 0;
          new MutationObserver(function () {
            var txt = el.textContent;
            if (txt === shown) return;
            var to = parse(txt);
            if (!to || reduce.matches) { shown = txt; from = to ? to.v : 0; return; }
            cancelAnimationFrame(raf);
            var t0 = performance.now(), dur = 600, start = from;
            (function step(now) {
              var p = Math.min(1, (now - t0) / dur), e = 1 - Math.pow(1 - p, 3);
              shown = fmt(start + (to.v - start) * e, to.d, to.suf);
              el.textContent = shown;
              if (p < 1) raf = requestAnimationFrame(step); else from = to.v;
            })(t0);
          }).observe(el, { childList: true, characterData: true, subtree: true });
        });
      });
    "))
  ),
  
  div(class = "glow"),
  
  div(class = "topbar",
      div(class = "brand", div(class = "logo", tags$i()), "Smart Irrigation"),
      div(class = "topbar-note", "Synthetic Kaggle Playground data")),
  
  div(class = "hero",
      span(class = "badge-pill", span(class = "dot"),
           paste(comma(n_total), "field records")),
      h1("Which fields need the most water, and when?"),
      p("Filter by crop, season and region, then hover any chart to bring it forward.")),
  
  div(class = "filters",
      selectInput("crop", "Crop",
                  c("All crops" = "All", sort(levels(irrigation_data$Crop_Type))),
                  selectize = FALSE),
      selectInput("season", "Season",
                  c("All seasons" = "All", sort(levels(irrigation_data$Season))),
                  selectize = FALSE),
      selectInput("region", "Region",
                  c("All regions" = "All", sort(levels(irrigation_data$Region))),
                  selectize = FALSE),
      selectInput("demand", "Irrigation demand",
                  c("All levels" = "All", "Low", "Medium", "High"),
                  selectize = FALSE),
      div(class = "btn-wrap",
          actionButton("reset", "Reset filters", class = "pill pill-ghost"),
          downloadButton("download", "Download filtered CSV", class = "pill pill-solid",
                         title = "Exports every filtered row with all 21 columns"))),
  
  div(class = "kpi-row",
      kpi("peach",  "Records in view",       "total_records", "matching your filters", live = TRUE),
      kpi("violet", "Average soil moisture", "avg_moisture",  "dataset average is 37.3"),
      kpi("mint",   "High-demand share",     "high_demand",   "dataset average is 3.33%"),
      kpi("bone",   "Average rainfall (mm)", "avg_rainfall",  "millimetres per record")),
  
  div(class = "section-head",
      h2("Irrigation demand, chart by chart"),
      p("Hover a chart to widen it. Drag to zoom, double-click to reset, and use the toolbar for more.")),
  
  div(class = "flex-row",
      card("Demand mix", "Share of records in each irrigation category", "demand_plot"),
      card("Soil moisture by demand", "Distribution of moisture within each category", "moisture_plot")),
  
  div(class = "flex-row",
      card("Demand by crop", "Percentage within each crop, so crops are comparable", "crop_plot"),
      card("Demand by season", "Percentage within each season", "season_plot")),
  
  div(class = "flex-row",
      card("Demand by region", "Percentage within each region", "region_plot"),
      card("Rainfall and soil moisture", "Random sample of up to 8,000 records", "rainfall_plot")),
  
  uiOutput("insight"),
  
  div(class = "section-head",
      h2("Browse the records"),
      p("Sort, search and filter the rows behind every chart. The CSV button exports all columns, not just these eight.")),
  div(class = "table-card", DTOutput("data_table")),
  
  div(class = "footer",
      "Built with R Shiny. The data is synthetic, so patterns here describe this dataset, not verified farm conditions.")
)

# -------------------- SERVER LOGIC --------------------------

server <- function(input, output, session) {
  
  observeEvent(input$reset, {
    for (id in c("crop", "season", "region", "demand")) {
      updateSelectInput(session, id, selected = "All")
    }
  })
  
  # ---- shared filter state: computed once per filter change ----
  
  # Row positions matching the filters (integers, cheap to share).
  row_idx <- reactive({
    keep <- rep(TRUE, n_total)
    if (input$crop   != "All") keep <- keep & (irrigation_data$Crop_Type == input$crop)
    if (input$season != "All") keep <- keep & (irrigation_data$Season == input$season)
    if (input$region != "All") keep <- keep & (irrigation_data$Region == input$region)
    if (input$demand != "All") keep <- keep & (irrigation_data$Irrigation_Need == input$demand)
    which(keep)
  })
  
  # Same filters applied to the small aggregated table (a few hundred rows).
  agg_f <- reactive({
    a <- agg_data
    if (input$crop   != "All") a <- a[a$Crop_Type == input$crop, ]
    if (input$season != "All") a <- a[a$Season == input$season, ]
    if (input$region != "All") a <- a[a$Region == input$region, ]
    if (input$demand != "All") a <- a[a$Irrigation_Need == input$demand, ]
    a
  })
  
  # Subset helper that avoids copying when nothing is filtered.
  take_rows <- function(df, ix) if (length(ix) == nrow(df)) df else df[ix, , drop = FALSE]
  
  need_rows <- function(a) {
    validate(need(nrow(a) > 0 && sum(a$n) > 0,
                  "No records match these filters. Try resetting one of them."))
  }
  
  # Cache key shared by every plot: one render per filter combination.
  cache_key <- reactive(list(input$crop, input$season, input$region, input$demand))
  
  # ---------------- KPI cards (from aggregates, exact) ----------------
  
  output$total_records <- renderText(comma(sum(agg_f()$n)))
  
  output$avg_moisture <- renderText({
    a <- agg_f(); n <- sum(a$n)
    if (n == 0) return("–")
    sprintf("%.1f", sum(a$sum_moisture) / n)
  })
  
  output$high_demand <- renderText({
    a <- agg_f(); n <- sum(a$n)
    if (n == 0) return("–")
    paste0(sprintf("%.2f", sum(a$n[a$Irrigation_Need == "High"]) / n * 100), "%")
  })
  
  output$avg_rainfall <- renderText({
    a <- agg_f(); n <- sum(a$n)
    if (n == 0) return("–")
    sprintf("%.1f", sum(a$sum_rain) / n)
  })
  
  # ---------------- Demand donut ----------------
  
  output$demand_plot <- renderPlotly({
    a <- agg_f()
    need_rows(a)
    
    s <- a %>% group_by(Irrigation_Need) %>% summarise(n = sum(n), .groups = "drop") %>%
      filter(n > 0)
    
    plot_ly(
      s, labels = ~Irrigation_Need, values = ~n, type = "pie", hole = 0.62,
      sort = FALSE, direction = "clockwise",
      textinfo = "percent", textposition = "outside",
      textfont = list(color = ash),
      marker = list(colors = unname(demand_colors[as.character(s$Irrigation_Need)]),
                    line = list(color = "#050607", width = 3)),
      hovertemplate = "%{label}<br>%{value:,} records (%{percent})<extra></extra>"
    ) %>%
      style_plot(
        showlegend = TRUE,
        legend = list(orientation = "h", x = 0.5, xanchor = "center", y = -0.05),
        margin = list(t = 30, b = 40, l = 30, r = 30)
      )
  }) %>% bindCache(cache_key())
  
  # ---------------- Soil moisture box plot ----------------
  # Uses a random sample of up to 25,000 rows (same chart, fewer points).
  
  output$moisture_plot <- renderPlotly({
    ix <- row_idx()
    validate(need(length(ix) > 0, "No records match these filters. Try resetting one of them."))
    if (length(ix) > 25000) { set.seed(42); ix <- sample(ix, 25000) }
    
    d <- data.frame(Soil_Moisture = irrigation_data$Soil_Moisture[ix],
                    Irrigation_Need = irrigation_data$Irrigation_Need[ix])
    
    plot_ly(
      d, x = ~Irrigation_Need, y = ~Soil_Moisture, color = ~Irrigation_Need,
      colors = demand_colors, type = "box", boxpoints = FALSE
    ) %>%
      style_plot(
        xaxis = axis_style("Irrigation demand", showgrid = FALSE),
        yaxis = axis_style("Soil moisture"),
        showlegend = FALSE,
        margin = list(t = 10, b = 55, l = 55, r = 15)
      )
  }) %>% bindCache(cache_key())
  
  # ---------------- Stacked percentage bars (from aggregates, exact) ----------------
  
  stacked_bar <- function(a, var, xtitle) {
    s <- a %>%
      group_by(group = .data[[var]], Irrigation_Need) %>%
      summarise(n = sum(n), .groups = "drop") %>%
      group_by(group) %>%
      mutate(Percentage = n / sum(n) * 100) %>%
      ungroup() %>%
      mutate(group = as.character(group))
    
    plot_ly(
      s, x = ~group, y = ~Percentage, color = ~Irrigation_Need,
      colors = demand_colors, type = "bar", customdata = ~n,
      hovertemplate = paste0("%{x}<br>%{fullData.name}: %{y:.1f}%",
                             " (%{customdata:,} records)<extra></extra>")
    ) %>%
      style_plot(
        barmode = "stack", bargap = 0.35,
        xaxis = axis_style(xtitle, showgrid = FALSE),
        yaxis = axis_style(NULL, ticksuffix = "%", range = c(0, 100)),
        legend = list(orientation = "h", x = 0.5, xanchor = "center", y = -0.22),
        margin = list(t = 10, b = 80, l = 50, r = 15)
      )
  }
  
  output$crop_plot <- renderPlotly({
    a <- agg_f(); need_rows(a); stacked_bar(a, "Crop_Type", "Crop")
  }) %>% bindCache(cache_key())
  
  output$season_plot <- renderPlotly({
    a <- agg_f(); need_rows(a); stacked_bar(a, "Season", "Season")
  }) %>% bindCache(cache_key())
  
  output$region_plot <- renderPlotly({
    a <- agg_f(); need_rows(a); stacked_bar(a, "Region", "Region")
  }) %>% bindCache(cache_key())
  
  # ---------------- Rainfall scatter ----------------
  
  output$rainfall_plot <- renderPlotly({
    ix <- row_idx()
    validate(need(length(ix) > 0, "No records match these filters. Try resetting one of them."))
    if (length(ix) > 8000) { set.seed(42); ix <- sample(ix, 8000) }
    
    d <- data.frame(Rainfall_mm = irrigation_data$Rainfall_mm[ix],
                    Soil_Moisture = irrigation_data$Soil_Moisture[ix],
                    Irrigation_Need = irrigation_data$Irrigation_Need[ix])
    
    plot_ly(
      d, x = ~Rainfall_mm, y = ~Soil_Moisture, color = ~Irrigation_Need,
      colors = demand_colors, type = "scattergl", mode = "markers",
      marker = list(size = 5, opacity = 0.6),
      hovertemplate = "Rainfall %{x:.1f} mm<br>Moisture %{y:.1f}<extra></extra>"
    ) %>%
      style_plot(
        xaxis = axis_style("Rainfall (mm)"),
        yaxis = axis_style("Soil moisture"),
        legend = list(orientation = "h", x = 0.5, xanchor = "center", y = -0.22),
        margin = list(t = 10, b = 80, l = 55, r = 15)
      )
  }) %>% bindCache(cache_key())
  
  # ---------------- Insight (medians need raw rows; cached) ----------------
  
  output$insight <- renderUI({
    ix <- row_idx()
    m <- irrigation_data$Soil_Moisture[ix]
    g <- irrigation_data$Irrigation_Need[ix]
    
    low  <- if (any(g == "Low"))  median(m[g == "Low"])  else NA_real_
    high <- if (any(g == "High")) median(m[g == "High"]) else NA_real_
    
    body <- if (!is.na(low) && !is.na(high)) {
      p(sprintf(paste0("In the records you are viewing, High-demand fields have a median ",
                       "soil moisture of %.1f, compared with %.1f for Low-demand fields."),
                high, low))
    } else {
      p(paste0("High-demand records sit well below Low-demand records on soil moisture. ",
               "Clear the demand filter to compare them here."))
    }
    
    div(class = "insight-card",
        h3("Soil moisture tells the story. Crop, season and region barely do."),
        body,
        p(paste0("Across all 630,000 records the Kruskal-Wallis effect size for moisture is 0.20, ",
                 "while Cramér's V for crop, season and region stays below 0.03.")),
        div(class = "fine", "These are associations in synthetic data, not proof of cause."))
  }) %>% bindCache(cache_key())
  
  # ---------------- Data table (server-side, pre-rounded columns) ----------------
  
  output$data_table <- renderDT({
    datatable(
      take_rows(table_data, row_idx()),
      rownames = FALSE, filter = "top", class = "compact hover",
      colnames = c("Soil type", "Soil moisture", "Temperature (°C)", "Rainfall (mm)",
                   "Crop", "Season", "Region", "Irrigation demand"),
      options = list(pageLength = 10, lengthMenu = c(10, 25, 50, 100),
                     scrollX = TRUE, dom = "lrtip",
                     processing = TRUE,     # shows 'Processing...' pill
                     deferRender = TRUE,
                     searchDelay = 400)     # don't hit R on every keystroke
    ) %>%
      formatStyle(
        "Irrigation_Need",
        backgroundColor = styleEqual(names(demand_colors), unname(demand_colors)),
        color = "#000000", fontWeight = "500"
      )
  }, server = TRUE)
  
  # ---------------- CSV export: all rows matching filters, all 21 columns ----------------
  
  output$download <- downloadHandler(
    filename = function() paste0("irrigation_filtered_", Sys.Date(), ".csv"),
    content = function(file) {
      ix <- isolate(row_idx())
      showNotification(
        sprintf("Preparing %s rows (all %d columns). Large exports take a few seconds.",
                comma(length(ix)), ncol(irrigation_data)),
        id = "dl_note", duration = NULL, type = "message")
      on.exit(removeNotification("dl_note"), add = TRUE)
      
      tryCatch(
        write_csv(take_rows(irrigation_data, ix), file, progress = FALSE),
        error = function(e) {
          showNotification(paste("Export failed:", conditionMessage(e)),
                           type = "error", duration = 8)
          stop(e)
        }
      )
    }
  )
}

# -------------------- RUN APPLICATION -----------------------

shinyApp(ui = ui, server = server)