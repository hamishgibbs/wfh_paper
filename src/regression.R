suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(magrittr)
  library(rstan)
})

if (interactive()) {
  .args <- c(
    "src/utils.R",
    "data/regression/regression_data.csv",
    "output/cor_plot.png",
    "output/cor_matrix.csv",
    "output/regression_predictions.png",
    "output/coefficient_values.png",
    "data/regression/models.rds",
    "output/model_fit_summary.csv"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

source(.args[1])
reg_data <- fread(.args[2])
.outputs <- tail(.args, 6)

p <- ggplot(data=reg_data) + 
  geom_point(aes(x = value, y = propWFH21), size=0.1) + 
  facet_wrap(~variable, scales="free") + 
  theme_classic() + 
  labs(x = "Google Mobility", y = "Proportion working from home (Census)")

ggsave(.outputs[1],
       p,
       width=10,
       height=6, 
       units="in")

reg_data_wide <- dcast(reg_data[, c("lad19cd", "variable", "value")], lad19cd ~ variable)

reg_data_wide[reg_data, on=c("lad19cd"), propWFH21 := propWFH21]

reg_data_wide[, lad19cd := NULL]

setcolorder(reg_data_wide, 
            c("propWFH21", 
              "Residential", 
              "Workplaces", 
              "Retail and Recreation", 
              "Grocery and Pharmacy", 
              "Transit Stations", 
              "Parks"))

cor_matrix <- data.frame(cor(as.matrix(reg_data_wide), use="complete.obs"))

cor_matrix <- round(cor_matrix, 2)

cor_matrix$`variable` <- rownames(cor_matrix)

setcolorder(cor_matrix, c("variable"))

names(cor_matrix) <- gsub("[.]", " ", gsub(".Inverse.", "(Inverse)", names(cor_matrix)))

fwrite(cor_matrix, .outputs[2])

estimates_all_settings <- list()
predictions_all_settings <- list()
stan_cases_all_settings <- list()
models <- list()

for (i in 1:length(unique(reg_data$variable))){
  
  subset_variable <- unique(reg_data$variable)[i]
  
  stan.cases <- data.frame(y = reg_data_wide[, get("propWFH21")], 
                           x = reg_data_wide[, get(subset_variable)])  
  
  
  # Check where these NAs are coming from
  stan.cases <- subset(stan.cases, complete.cases(stan.cases))
  
  stan.data <- list(
    N = length(stan.cases$y),
    y = stan.cases$y,
    x = stan.cases$x
  )  

  prior <- c(brms::set_prior("normal(0, 1)", class = "b", coef = "x"),
             brms::set_prior("normal(0, 1)", class = "Intercept"),
             brms::set_prior("normal(0, 1)", class = "sigma"))
    
  res <- brms::brm(y ~ x,
              data = stan.data, 
              chains = 8,
              iter = 5000,
              warmup = 2000,
              prior = prior)
  
  estimates <- tidybayes::spread_draws(res$fit, 
                                       c(b_x, sigma, b_Intercept), 
                                       ndraws = 1000)
  estimates$variable <- subset_variable
  
  estimates_all_settings[[i]] <- estimates
  
  predictions <- stan.cases %>% 
    modelr::data_grid(x = modelr::seq_range(x, n=101)) %>% 
    tidybayes::add_predicted_draws(res)
  predictions$variable <- subset_variable
  
  predictions_all_settings[[i]] <- predictions
  
  stan.cases$variable <- subset_variable
  
  stan_cases_all_settings[[i]] <- stan.cases
  
  models[[subset_variable]] <- res
  
}

estimates_all_settings <- do.call(rbind, estimates_all_settings)
predictions_all_settings <- do.call(rbind, predictions_all_settings)
stan_cases_all_settings <- do.call(rbind, stan_cases_all_settings)

p <- predictions_all_settings %>% 
  ggplot(aes(x = x, y=y)) +
  ggdist::stat_lineribbon(aes(y = .prediction), .width = c(.99, .95, .8, .5), 
                          color = "#08519C") +
  geom_point(data = stan_cases_all_settings, size = 0.5) +
  scale_fill_brewer() + 
  facet_wrap(~variable, scales = "free") + 
  theme_classic() + 
  labs(x = "Google Mobility", y = "Proportion working from home (Census)", fill = "Credible\ninterval")

ggsave(.outputs[3],
       p,
       width=10,
       height=8, 
       units="in")

estimates_all_settings_long <- melt(data.table(estimates_all_settings), 
     id=c("variable"), 
     measure.vars=c("b_x"),
     variable.name="parameter")

estimates_all_settings_long$parameter <- "Google mobility coefficient"

p <- ggplot(data = estimates_all_settings_long, 
       aes(x = value, y = variable, fill=variable)) +
  geom_vline(xintercept=0, linetype="dashed", size=0.2) + 
  tidybayes::stat_eye(scale = 1.8) + 
  scale_fill_manual(values = google_settings_pal) + 
  facet_wrap(~parameter, scales="free_x") + 
  theme_classic() + 
  theme(legend.position = "none") +
  labs(x = "Coefficient estimates", y = "Mobility setting")

ggsave(.outputs[4],
       p,
       width=10,
       height=6, 
       units="in")

readr::write_rds(models, .outputs[5])

format_model_summary <- function(i, models){
  coef_summary <- summary(models[[i]])
  coef_summary <- coef_summary$fixed
  coef_summary <- round(coef_summary, 2)
  coef_summary$Coefficient <- rownames(coef_summary)
  coef_summary$Setting <- names(models)[i]
  setcolorder(coef_summary, c("Setting", "Coefficient"))
  coef_summary
}

model_fit_summary <- do.call(rbind, lapply(1:length(models), format_model_summary, models=models))

fwrite(model_fit_summary, .outputs[6])
