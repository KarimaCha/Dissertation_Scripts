# script to analyze outputs from computational modeling
# 
# written by: Karima Chakroun, UKE, Hamburg, 2017


library(rstan)
library(ggplot2)
library(loo)


# =============================================================================
#  Model Summary and Diagnostics 
# =============================================================================

modelname <- fit_rl@model_name
model_pars <- fit_rl@model_pars
model_pars_print <- setdiff(model_pars, c('v', 'vc', 'pe', 'eb', 'persev', 'log_lik', 'log_lik_t', 'log_lik_h', 'sig', 'Kgain'))
model_pars_plot  <- setdiff(model_pars_print, 'lp__')
model_hyperpars_plot <- setdiff(model_pars_plot, c('lr', 'beta', 'phi', 'lr_raw', 'beta_raw', 'phi_raw'))

plot_dens_sep <- stan_dens(fit_rl, pars = model_hyperpars_plot, separate_chains = T)
print(plot_dens_sep)

print(fit_rl, pars= model_pars_print)  #print(fit_rl, pars=c('vc', 'pe', 'v'), include=FALSE)

#========================

stan_diag(fit_rl, information = "sample", chain = 0)
stan_diag(fit_rl, information = "stepsize", chain = 0)
stan_diag(fit_rl, information = "treedepth", chain = 0)
stan_diag(fit_rl, information = "divergence", chain = 0)

stan_par(fit_rl, par = 'beta_mu', chain = 0)

stan_rhat(fit_rl, pars = model_hyperpars_plot)
stan_ess(fit_rl, pars = model_hyperpars_plot)
stan_mcse(fit_rl, pars = model_hyperpars_plot)

count_divergences <- function(fit) {
  sampler_params <- get_sampler_params(fit, inc_warmup=FALSE)
  sum(sapply(sampler_params, function(x) c(x[,'n_divergent__']))[,1])
} 

count_divergences(fit_rl)



# =============================================================================
#  Use Shinystan
# =============================================================================

library("shinystan")
DeltaSMf_sp_ss <- launch_shinystan(fit_rl)
save(DeltaSMf_sp_ss, file = "_shiny/DeltaSMf_sp_ss")
load('_shiny/DeltaSMf_sp_ss')
DeltaSMf_sp_ss <- launch_shinystan(DeltaSMf_sp_ss)



# =============================================================================
#  Plot Stanfit and Parameters
# =============================================================================

#modelname <- paste0(fit_rl@model_name,'_Hald')
plotname_trunc <- paste('_plots/dabandit_', modelname, '_', sep="")


# TRACE PLOTS
#===================
#model_hyperpars_plot = c('beta_mu','phi_mu','persev_mu') #,'sigD','decay','decay_center','v1','sig1')
plot_trace_excl_warm_up <- stan_trace(fit_rl, pars = model_hyperpars_plot, inc_warmup = F)
plot_dens <- stan_plot(fit_rl, pars = model_hyperpars_plot, show_density = T, fill_color = 'skyblue') #+xlim(-1,8)

b <- stan_plot(fit_rl, pars = 'phi', show_density = T, fill_color = 'skyblue') #+xlim(-1,8)
b <- stan_plot(fit_rl, pars = 'persev', show_density = T, fill_color = 'skyblue') #+xlim(-10,30)
b <- b + geom_vline(xintercept = 0, color="black") 
b

plot_dens_cmb <- stan_dens(fit_rl, pars = model_hyperpars_plot, separate_chains = F)
plot_dens_sep <- stan_dens(fit_rl, pars = model_hyperpars_plot, separate_chains = T)
# plot_dens_sep <- stan_dens(fit_rl, pars = c('beta_mu', 'phi_mu'), separate_chains = T)

print(plot_trace_excl_warm_up)
dev.copy(png, paste(plotname_trunc,'trace.png',sep="")); dev.off();
print(plot_dens)
dev.copy(png, paste(plotname_trunc,'dens.png',sep="")); dev.off();
print(plot_dens_cmb)
dev.copy(png, paste(plotname_trunc,'dens_cmb.png',sep="")); dev.off();
print(plot_dens_sep)
dev.copy(png, paste(plotname_trunc,'dens_sep.png',sep="")); dev.off();


# DENSITY PLOTS
#===================

# LR
plot_dens_lr  <- stan_plot(fit_rl, pars = c('lr_mu', 'lr_sd', 'lr'), show_density = T, fill_color = 'skyblue')
print(plot_dens_lr)
dev.copy(png, paste(plotname_trunc,'dens_lr.png',sep="")); dev.off();

# BETA
plot_dens_beta <- stan_plot(fit_rl, pars = c('beta_mu', 'beta_sd', 'beta'), show_density = T, fill_color = 'skyblue')
print(plot_dens_beta)
dev.copy(png, paste(plotname_trunc,'dens_beta.png',sep="")); dev.off();

# PHI
plot_dens_phi  <- stan_plot(fit_rl, pars = c('phi_mu', 'phi_sd', 'phi'), show_density = T, fill_color = 'skyblue')
print(plot_dens_phi)
dev.copy(png, paste(plotname_trunc,'dens_phi.png',sep="")); dev.off();

# PERSEV
plot_dens_persev  <- stan_plot(fit_rl, pars = c('persev_mu', 'persev_sd', 'persev'), show_density = T, fill_color = 'skyblue')
print(plot_dens_persev)
dev.copy(png, paste(plotname_trunc,'dens_persev.png',sep="")); dev.off();



# =============================================================================
#  Extract log_likelihood and compare models  
# =============================================================================

library(loo)

LL <- extract_log_lik(fit_rl)
LL1 <- extract_log_lik(fit_rl1)
LL2 <- extract_log_lik(fit_rl2)
LL3 <- extract_log_lik(fit_rl3)
LL4 <- extract_log_lik(fit_rl4)

myLoo <- loo(LL)
plot(myLoo)

loo1 <- loo(LL1)
loo2 <- loo(LL2)
loo3 <- loo(LL3)
loo4 <- loo(LL4)
compare(loo2, loo4) # positive difference indicates the 2nd model's predictive accuracy is higher

# Karima:

print(fit_rl, pars='log_lik')
LL     <- extract_log_lik(fit_rl)
(myLoo  <- loo(LL))
(myWaic <- waic(LL))
plot(myLoo)

a = fit_rl@sim$samples[[2]]$`log_lik_h[1]`
b = fit_rl@sim$samples[[2]]$`log_lik_h[2]`

temp <- summary(fit_rl, pars="log_lik_h")
temp$summary[,1]

plot_dens_lr  <- stan_plot(fit_rl1, pars = c('phi'), show_density = T, fill_color = 'skyblue')
print(plot_dens_lr)

plot_dens_LLt <- stan_plot(fit_rl, pars = c('log_lik_t'), show_density = T, fill_color = 'skyblue')
print(plot_dens_LLt)

plot_dens_LLh <- stan_plot(fit_rl, pars = c('log_lik'), show_density = T, fill_color = 'skyblue')
print(plot_dens_LLh)



# =============================================================================
#### Plot Generated quantities (Regressors)
# =============================================================================


if (level == 1) {
  nSubjects <- 1
  dataList <- list(nTrials = nTrials,
                   choice = dabandit_data[1,1,,1],  # only Placebo of 1. subject
                   reward = dabandit_data[1,1,,2])  # only Placebo of 1. subject
} else {
  nSubjects <- sz[2]
  dataList <- list(nSubjects = nSubjects,
                   nTrials = nTrials,
                   choice = dabandit_data[1,,,1],  # only Placebo of all subjects
                   reward = dabandit_data[1,,,2])  # only Placebo of all subjects
}  


model_pars_plot <- setdiff(model_pars, c('v', 'vc', 'pe', 'log_lik', 'lp__'))
plotname_trunc <- paste('_plots/', modelname, '_', sep="")

dec_var <- get_posterior_mean(fit_rl, pars=c('vc', 'pe', 'v'))[,5]  # vc:1-300; pe:301-600; v1=601-901; v2 = 902-1202; v3=1203-1503; v4=1504-1804
vc <- dec_var[1:(nSubjects*nTrials)]
pe <- dec_var[(1:(nSubjects*nTrials)) + nSubjects*nTrials]
vc <- matrix(vc, nrow = nSubjects, ncol = nTrials, byrow = T)
pe <- matrix(pe, nrow = nSubjects, ncol = nTrials, byrow = T)

vc[vc==999] <- NA
pe[pe==999] <- NA

#### take one participants as an example, subj = 1
vc_sub1 <- vc[1,]
pe_sub1 <- pe[1,]

if (level == 1) {
  ch_sub1 <- dataList$choice
  rw_sub1 <- dataList$reward
} else {
  ch_sub1 <- dataList$choice[1,]
  rw_sub1 <- dataList$reward[1,]
}

df_sub1 <- data.frame(trial  = 1:nTrials,
                      choice = ch_sub1,
                      reward = rw_sub1,
                      value  = vc_sub1,
                      pe     = pe_sub1)

#### make plots of choice, reward, v(chn), and pe
library(ggplot2)
myconfig <- theme_bw(base_size = 20) +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank() )

g1 <- ggplot(df_sub1, aes(x=trial, y=value))
g1 <- g1 + geom_line(size = 2, color = 'black') + geom_point(size = 3, shape = 21, fill='black')
g1 <- g1 + myconfig + labs(x = 'Trial', y = 'Chosen Value')
print(g1)

g2 <- ggplot(df_sub1, aes(x=trial, y=pe))
g2 <- g2 + geom_line(size = 2, color = 'black') + geom_point(size = 3, shape = 21, fill='black')
g2 <- g2 + myconfig + labs(x = 'Trial', y = 'Prediction Error')
print(g2)

bandit_colors = c('white','red','green','blue','yellow')

g2b <- ggplot(df_sub1, aes(x=trial, y=choice)) #y=choice))
g2b <- g2b + geom_point(size = 3, shape = 21, color=bandit_colors[df_sub1$choice+1], fill=bandit_colors[df_sub1$choice+1])  #geom_point(size = 2) +
g2b <- g2b + myconfig + labs(x = 'Trial', y = 'Choice')
print(g2b)

g2c <- ggplot(df_sub1, aes(x=trial, y=reward))
g2c <- g2c + geom_line(size = 2, color = 'black') + geom_point(size = 3, shape = 21, fill='black')
g2c <- g2c + myconfig + labs(x = 'Trial', y = 'Reward')
print(g2c)

ggsave(plot = g1, paste(plotname_trunc, "_sub1_value.png", sep=""), width = 10, height = 4, type = "cairo-png", units = "in")
ggsave(plot = g2, paste(plotname_trunc, "_sub1_pe.png", sep=""), width = 10, height = 4, type = "cairo-png", units = "in")
ggsave(plot = g2b, paste(plotname_trunc, "_sub1_reward.png", sep=""), width = 10, height = 4, type = "cairo-png", units = "in")
ggsave(plot = g2c, paste(plotname_trunc, "_sub1_choice.png", sep=""), width = 10, height = 4, type = "cairo-png", units = "in")


#### EXERCISE: extract and plot the value of option2 ####
v <- dec_var[((nSubjects*nTrials)*2+1):length(dec_var)]
v <- matrix(v, nrow = 4, ncol = length(v)/4) # 1st row for bandit1, ..., 4th row for bandit 4

v_op1 <- v[1,]
v_op1 <- matrix(v_op1, nrow = nSubjects, ncol = nTrials+1, byrow = T)
v_op1 <- v_op1[1:nSubjects, 1:nTrials]  # remove the 101th trial
if (level == 1) {
  v_op1_sub1 <- v_op1
} else {
  v_op1_sub1 <- v_op1[1,]
}


v_op2 <- v[2,]
v_op2 <- matrix(v_op2, nrow = nSubjects, ncol = nTrials+1, byrow = T)
v_op2 <- v_op2[1:nSubjects, 1:nTrials]  # remove the 101th trial
if (level == 1) {
  v_op2_sub1 <- v_op2
} else {
  v_op2_sub1 <- v_op2[1,]
}

v_op3 <- v[3,]
v_op3 <- matrix(v_op3, nrow = nSubjects, ncol = nTrials+1, byrow = T)
v_op3 <- v_op3[1:nSubjects, 1:nTrials]  # remove the 101th trial
if (level == 1) {
  v_op3_sub1 <- v_op3
} else {
  v_op3_sub1 <- v_op3[1,]
}

v_op4 <- v[4,]
v_op4 <- matrix(v_op4, nrow = nSubjects, ncol = nTrials+1, byrow = T)
v_op4 <- v_op4[1:nSubjects, 1:nTrials]  # remove the 101th trial
if (level == 1) {
  v_op4_sub1 <- v_op4
} else {
  v_op4_sub1 <- v_op4[1,]
}


df2_sub1 <- data.frame(trial  = 1:nTrials,
                       value1 = v_op1_sub1,
                       value2 = v_op2_sub1,
                       value3 = v_op3_sub1,
                       value4 = v_op4_sub1)

g3 <- ggplot(df2_sub1, aes(x=trial, y=value1))
g3 <- g3 + geom_line(size = 2, color = 'black') + geom_point(size = 3, shape = 21, fill='black')
g3 <- g3 + myconfig + labs(x = 'Trial', y = 'value of option 1')
print(g3)

g4 <- ggplot(df2_sub1, aes(x=trial, y=value2))
g4 <- g4 + geom_line(size = 2, color = 'black') + geom_point(size = 3, shape = 21, fill='black')
g4 <- g4 + myconfig + labs(x = 'Trial', y = 'value of option 2')
print(g4)

g5 <- ggplot(df2_sub1, aes(x=trial, y=value3))
g5 <- g5 + geom_line(size = 2, color = 'black') + geom_point(size = 3, shape = 21, fill='black')
g5 <- g5 + myconfig + labs(x = 'Trial', y = 'value of option 3')
print(g5)

g6 <- ggplot(df2_sub1, aes(x=trial, y=value4))
g6 <- g6 + geom_line(size = 2, color = 'black') + geom_point(size = 3, shape = 21, fill='black')
g6 <- g6 + myconfig + labs(x = 'Trial', y = 'value of option 4')
print(g6)

ggsave(plot = g3, paste(plotname_trunc, "_sub1_value_opt1.png", sep=""), width = 10, height = 4, type = "cairo-png", units = "in")
ggsave(plot = g4, paste(plotname_trunc, "_sub1_value_opt2.png", sep=""), width = 10, height = 4, type = "cairo-png", units = "in")
ggsave(plot = g5, paste(plotname_trunc, "_sub1_value_opt3.png", sep=""), width = 10, height = 4, type = "cairo-png", units = "in")
ggsave(plot = g6, paste(plotname_trunc, "_sub1_value_opt4.png", sep=""), width = 10, height = 4, type = "cairo-png", units = "in")



# =============================================================================
#### Violin plot of posterior means ####
# =============================================================================

# if (level > 2) {
#
# pars_value <- get_posterior_mean(fit_rl, pars = model_pars)[, 5]
# pars_name  <- as.factor(c(rep('lr', 31), rep('beta', 31)))
# df <- data.frame(pars_value = pars_value, pars_name = pars_name)
#
# myconfig <- theme_bw(base_size = 20) +
#   theme(panel.grid.major = element_blank(),
#     panel.grid.minor = element_blank(),
#     panel.background = element_blank()
#   )
#
# data_summary <- function(x) {
#   m <- mean(x)
#   ymin <- m - sd(x)
#   ymax <- m + sd(x)
#   return(c(y = m, ymin = ymin, ymax = ymax))
# }
#
# g1 <-
#   ggplot(df,
#          aes(
#            x = pars_name,
#            y = pars_value,
#            color = pars_name,
#            fill = pars_name))
#
# g1 <- g1 + geom_violin(trim = TRUE, size = 2)
# g1 <- g1 + stat_summary(fun.data = data_summary, geom = "pointrange", color = "black", size = 1.5)
# g1 <- g1 + scale_fill_manual(values = c("#2179b5", "#c60256"))
# g1 <- g1 + scale_color_manual(values = c("#2179b5", "#c60256"))
# g1 <- g1 + myconfig + theme(legend.position = "none")
# g1 <- g1 + labs(x = '', y = 'parameter value') + ylim(0.0, 1.0)
# print(g1)
#
# dev.copy(png, paste(plotname_trunc,'violin.png',sep="")); dev.off();
#
# }

# ### violin plot of true parameters
# load('_data/rl_mp_parms_optm.Rdata')
# pars_true_value <- rl_mp_parms
# pars_name  <- as.factor(c(rep('lr',31),rep('tau',31)))
# df2 <- data.frame(pars_true_value=pars_true_value, pars_name=pars_name)
#
# g2 <- ggplot(df2, aes(x=pars_name, y=pars_true_value, color = pars_name, fill=pars_name))
# g2 <- g2 + geom_violin(trim=TRUE, size=2)
# g2 <- g2 + stat_summary(fun.data=data_summary, geom="pointrange", color="black", size=1.5)
# g2 <- g2 + scale_fill_manual(values=c("#2179b5", "#c60256"))
# g2 <- g2 + scale_color_manual(values=c("#2179b5", "#c60256"))
# g2 <- g2 + myconfig + theme(legend.position="none")
# g2 <- g2 + labs(x = '', y = 'parameter value') + ylim(0.3,2.2)
# print(g2)

