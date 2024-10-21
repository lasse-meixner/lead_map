data {
  int<lower=0> N_obs; 
  int<lower=0> N_cens; 
  array[N_obs] int<lower=0> y_obs; 
  int<lower=0> threshold; 
  vector[N_obs] x_obs; 
  vector[N_cens] x_cens; 
  vector[N_obs] z_obs;
  vector[N_cens] z_cens;
  real alpha_prior_var;
}

// skip data transform: pass data in as demeaned

parameters {
  real alpha;
  real beta;
  real gamma;
  real delta;
  real kappa;
}

model {
  // priors
  alpha ~ normal(0.5, alpha_prior_var);
  gamma ~ normal(0, 1.5);
  // model
  vector[N_obs] mu_obs = exp(alpha + beta * x_obs);
  vector[N_obs] pi_obs = inv_logit(gamma + delta * z_obs + kappa * x_obs);
  vector[N_obs] lambda_obs = mu_obs .* pi_obs; // elementwise product
  y_obs ~ poisson(lambda_obs); 
  for (j in 1:N_cens) {
    real mu_cens = exp(alpha + beta * x_cens[j]);
    real pi_cens = inv_logit(gamma + delta * z_cens[j] + kappa * x_cens[j]);
    real lambda_cens = mu_cens * pi_cens;
    target += log_diff_exp(poisson_lcdf(threshold | lambda_cens), poisson_lpmf(0 | lambda_cens));
  }
}

