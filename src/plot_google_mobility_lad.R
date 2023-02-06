p_names <- c('lower_80', 'upper_80', 'lower_50', 'upper_50', 'lower_20', 'upper_20', 'median')
p <- c(0.01, 0.9, 0.25, 0.75, 0.6, 0.7, 0.5)

p_funs <- map(p, ~partial(quantile, probs = .x, na.rm = TRUE))
p_funs <- set_names(p_funs, nm = p_names)

subset_variables <- c(
  "parks",
  "transit_stations",
  "grocery_and_pharmacy",
  "residential", 
  "retail_and_recreation",
  "workplaces"
)

goog_mob_density <- subset(goog_mob_smooth, variable %in% subset_variables) %>%
  group_by(date, variable) %>% 
  summarize_at(vars(value), p_funs) %>% 
  ungroup()