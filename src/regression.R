suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(magrittr)
  library(rstan)
})

if (interactive()) {
  .args <- c(
    "src/linear_regression.stan",
    "data/regression/regression_data.csv",
    "output/cor_plot.png",
    "output/cor_matrix.csv",
    "output/coefficient_values.png"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

mod <- stan_model(.args[1])
reg_data <- fread(.args[2])
.outputs <- tail(.args, 3)

p <- ggplot(data=reg_data) + 
  geom_point(aes(x = propWFH21, y = value), size=0.1) + 
  facet_wrap(~variable) + 
  theme_classic()

ggsave(.outputs[1],
       p,
       width=10,
       height=8, 
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

fwrite(cor_matrix, .outputs[2])

estimates_all_settings <- list()

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
  
  res <- sampling(mod, 
                  chains = 8,
                  iter = 3000,
                  warmup = 1000,
                  data = stan.data,
                  # Perhaps remove these params for simple methods
                  control = list(adapt_delta = 0.9, 
                                 stepsize = 0.75,
                                 max_treedepth = 13))
  prior1 <- brms::prior(normal(0,1))
  res <- brms::brm(y ~ x,
              data = stan.data, 
              family = gaussian(), 
              prior = prior1,
              chains = 8,
              iter = 3000,
              warmup = 1000)
  
  estimates <- tidybayes::spread_draws(res, c(alpha, beta))
  estimates$variable <- subset_variable
  
  estimates_all_settings[[i]] <- estimates
  
}

estimates_all_settings <- do.call(rbind, estimates_all_settings)

estimates_all_settings_long <- melt(data.table(estimates_all_settings), 
     id=c("variable"), 
     measure.vars=c("alpha", "beta"),
     variable.name="parameter")

p <- ggplot(data = estimates_all_settings_long, 
       aes(x = value, y = variable, fill=variable)) +
  geom_vline(xintercept=0, linetype="dashed", size=0.2) + 
  tidybayes::stat_eye() + 
  facet_wrap(~parameter) + 
  theme_classic() + 
  theme(legend.position = "none") +
  labs(x = "Coefficient", y = "Mobility setting")

ggsave(.outputs[3],
       p,
       width=10,
       height=8, 
       units="in")

N_PRED_DRAWS = 1000

param_draws <- tidybayes::spread_draws(res, c(alpha, beta, sigma), ndraws=N_PRED_DRAWS)

params <- data.table(param_draws)[, .(alpha = mean(alpha), beta = mean(beta))]

prediction <- data.table(
  x = rep(seq(from=min(reg_data_wide$Residential, na.rm=T),
          to=max(reg_data_wide$Residential, na.rm=T),
          length.out = 1000),
          N_PRED_DRAWS),
  alpha = rep(param_draws$alpha, N_PRED_DRAWS),
  beta = rep(param_draws$beta, N_PRED_DRAWS)
)
prediction[, y_pred := params$alpha + params$beta * x]

prediction <- prediction[order(x)]
fit <- extract(res)

fit

traceplot(res, inc_warmup=T)

ggplot() + 
  ggdist::stat_lineribbon(data=as.data.frame(prediction) %>% dplyr::group_by(x), aes(x = x, y = y_pred)) + 
  geom_point(data=reg_data_wide, aes(x = propWFH21, y = `Retail and Recreation`))
  

geom_point(data=reg_data_wide, aes(x = propWFH21, y = Residential)) + 
  geom_path(data=prediction, aes(x=x, y=y_pred))

pred_df

extract(res)

tidybayes::linpred_draws(res, data.frame(y = reg_data_wide$propWFH21), ndraws = 100)



data.frame(x = 1:10) %>%
  dplyr::group_by_all() %>%
  dplyr::do(data.frame(y = rnorm(100, .$x))) %>% 
  ggplot(aes(x = x, y = y)) +
  ggdist::stat_lineribbon() +
  scale_fill_brewer()

