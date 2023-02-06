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

goog_mob_density$variable <- paste(goog_mob_density$variable, "(Google)")

mob_density %>% 
  ggplot() + 
  geom_vline(aes(xintercept=as.Date("2021-03-21")), color="blue", linetype="dashed") + 
  geom_ribbon(aes(x = date, ymin = lower_80, ymax = upper_80, fill = variable), alpha = ALPHA) + 
  geom_ribbon(aes(x = date, ymin = lower_50, ymax = upper_50, fill = variable), alpha = ALPHA) + 
  geom_ribbon(aes(x = date, ymin = lower_20, ymax = upper_20, fill = variable), alpha = ALPHA) + 
  geom_path(aes(x = date, y = median, color = variable)) + 
  theme_classic() + 
  facet_wrap(~variable, ncol=1)
