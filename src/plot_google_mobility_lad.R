suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(purrr)
  library(dplyr)
  library(zoo)
})

if (interactive()) {
  .args <- c(
    "src/utils.R",
    "data/mobility/clean/google_mobility_lad.csv",
    "output/mobility_overview_lad.png",
    "output/residential_mobility_dist_key_dates.csv",
    "output/head_tail_residential_mobility_census_date.csv"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

source(.args[1])
goog_mob <- fread(.args[2])
.outputs <- tail(.args, 3)

smooth_mobility <- function(x, K=14){
  x %>% 
    group_by(lad19cd, variable) %>% 
    mutate(value = rollmean(value, k=K, fill=NA, align='right'))
}

goog_mob_smooth <- smooth_mobility(goog_mob)

p_names <- c('lower_90', 'upper_90', 'lower_50', 'upper_50', 'lower_20', 'upper_20', 'median')
p <- c(0.05, 0.95, 0.25, 0.75, 0.6, 0.7, 0.5)

p_funs <- map(p, ~partial(quantile, probs = .x, na.rm = TRUE))
p_funs <- set_names(p_funs, nm = p_names)

goog_mob_density <- goog_mob_smooth %>%
  group_by(date, variable) %>% 
  summarize_at(vars(value), p_funs) %>% 
  ungroup()

goog_mob_density <- data.table(goog_mob_density)

goog_mob_density[, variable := factor(variable, levels = names(google_settings_pal))]

ALPHA = 0.3

p <- goog_mob_density %>% 
  ggplot() + 
  geom_vline(aes(xintercept=as.Date("2021-03-21")), color="red", linetype="dashed") + 
  geom_ribbon(aes(x = date, ymin = lower_90, ymax = upper_90, fill = variable), alpha = ALPHA) + 
  geom_ribbon(aes(x = date, ymin = lower_50, ymax = upper_50, fill = variable), alpha = ALPHA) + 
  geom_ribbon(aes(x = date, ymin = lower_20, ymax = upper_20, fill = variable), alpha = ALPHA) + 
  theme_classic() + 
  scale_fill_manual(values = google_settings_pal) + 
  facet_wrap(~variable, scales="free_y", ncol=2) + 
  theme(legend.position = "none") + 
  labs(x = "", y = "% change from baseline")

data_source_annotation <- paste0("Data: ", data_sources["google"])

p <- add_data_source_annotation(p, data_source_annotation)

ggsave(.outputs[1], 
       p, 
       width=11, 
       height = 10, 
       units = "in")

key_dates <- list(
  list(
    title="First Lockdown",
    date=as.Date("2020-04-10")), 
  list(title="Census Date",
       date=as.Date("2021-03-21")))

calc_mobility_distribution_table <- function(key_date, google, setting="Residential"){
  
  google_subset <- subset(google, date == key_date$date & variable == setting)
  
  return(
    data.frame(
      date_title = key_date$title,
      date = key_date$date,
      setting = setting,
      min = min(google_subset$value, na.rm=T),
      max = max(google_subset$value, na.rm=T),
      mean = mean(google_subset$value, na.rm=T),
      median = median(google_subset$value, na.rm=T),
      quartile_lower = quantile(google_subset$value, 0.25, na.rm=T),
      quartile_upper = quantile(google_subset$value, 0.75, na.rm=T)
    )
  )
  
}

residential_distribution <- lapply(key_dates, 
               calc_mobility_distribution_table, 
               google=goog_mob, 
               setting="Residential")

workplace_distribution <- lapply(key_dates, 
                                 calc_mobility_distribution_table, 
                                 google=goog_mob, 
                                 setting="Workplaces")

key_date_distributions <- do.call(rbind, c(residential_distribution, workplace_distribution))

fwrite(key_date_distributions, .outputs[2])

goog_mob_census_date_subset <- subset(goog_mob, 
                                     date == key_dates[[2]]$date & variable == "Residential")


format_top_change_table <- function(top_table){
  top_table <- top_table[, c("la_name", "value")]
  top_table[, value := scales::percent(value/100)]
  
  return(top_table)
}

top_bottom_change_table <- cbind(format_top_change_table(goog_mob_census_date_subset[order(value)][1:5, ]),
      format_top_change_table(goog_mob_census_date_subset[order(-value)][1:5, ]))

fwrite(top_bottom_change_table, .outputs[3])

