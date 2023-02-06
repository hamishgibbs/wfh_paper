suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

if (interactive()) {
  .args <- c(
    "data/census/Census-WFH.csv",
    ""
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

wfh <- fread(.args[1])

x <- wfh[, c("LAD21CD", "propWFH21")]
y <- wfh[, c("LAD21CD", "propWFH21")]

y[, propWFH21 := log(propWFH21)]

p_x <- ggplot(data=x) + 
  geom_density(aes(x = propWFH21)) + 
  theme_classic() + 
  labs(y = "Density", x = "Proportion working from home", title="a")

p_y <- ggplot(data=y) + 
  geom_density(aes(x = propWFH21)) + 
  theme_classic() + 
  labs(y = "Density", x = "Proportion working from home (log)", title="b")

p <- cowplot::plot_grid(p_x, p_y, nrow=1)

ggsave(tail(.args, 1),
       p,
       width=10, 
       height=5, 
       units="in")

