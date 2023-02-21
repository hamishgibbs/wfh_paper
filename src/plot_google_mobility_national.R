suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(ggrepel)
  library(purrr)
  library(dplyr)
  library(zoo)
})

if (interactive()) {
  .args <- c(
    "src/utils.R",
    "data/mobility/clean/google_mobility_national.csv",
    "data/interventions/key_interventions.csv",
    "output/mobility_overview_national.png"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

source(.args[1])
goog_mob <- fread(.args[2])
interventions <- fread(.args[3])

smooth_mobility <- function(x, K=30){
  x %>% 
    group_by(variable) %>% 
    mutate(value = rollmean(value, k=K, fill=NA, align='right'))
}

goog_mob_smooth <- smooth_mobility(goog_mob)

mob_smooth <- data.table(goog_mob_smooth)

mob_smooth[, variable := factor(variable, level = names(google_settings_pal))]

mob_smooth[, label_cap := date == max(date), by = c("variable")]

LABEL_NUDGE_X <- 30

label_coords <- mob_smooth[mob_smooth$label_cap]
label_coords[, label := variable]

interventions[, x := date + floor((date_end - date)/2)]
interventions[, y := c(-0.95, -0.8, -0.95)]

census_date <- data.frame(date = as.Date("2021-03-21"), value = NA, label="Census Date")

census_date$value <- max(subset(mob_smooth, date == census_date$date)$value)

p <- ggplot(data = mob_smooth) + 
  geom_rect(data = interventions, aes(xmin = date, xmax = date_end, ymin = -Inf, ymax=Inf),
            alpha = 0.2) + 
  geom_hline(yintercept = 0, color="black", linetype="dashed", size=0.2) + 
  geom_path(aes(x = date, y = value/100, color=variable), alpha=0.85) + 
  scale_color_manual(values = google_settings_pal) + 
  geom_label_repel(data=label_coords, 
                   aes(label=label, x = date, y = value/100, color=variable),
                   xlim = c(max(mob_smooth$date) + LABEL_NUDGE_X, NA),
                   na.rm = TRUE,
                   min.segment.length = 0,
                   segment.linetype = 3) + 
  geom_label(data=interventions, aes(x = x, y = y, label=label)) + 
  geom_label_repel(data=census_date, 
                   aes(x = date, y = value/100, label=label),
                   ylim = c(0.85, NA),
                   color="red",
                   fontface="bold",
                   direction = "x",
                   nudge_y = 3,
                   na.rm = TRUE,
                   min.segment.length = 0,
                   segment.linetype = 4) + 
  theme_classic() + 
  theme(legend.position = "none") + 
  scale_x_date(limits = c(min(mob_smooth$date), max(mob_smooth$date)+LABEL_NUDGE_X*8)) + 
  scale_y_continuous(labels = scales::percent, limits = c(-1, 1.1)) + 
  labs(x = "", y = "Percentage Change from Baseline")

data_source_annotation <- paste0("Data: ", data_sources["google"])

p <- add_data_source_annotation(p, data_source_annotation, size=9)

p <- p + theme(
  plot.margin = unit(c(0, 0, 0.25, 0), "cm"),
  plot.background = element_rect(fill = "white")
  )

ggsave(tail(.args, 1), 
       p, 
       width=9.5, 
       height = 6, 
       units = "in")

