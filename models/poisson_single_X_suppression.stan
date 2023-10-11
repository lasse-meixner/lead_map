data {
  int<lower=0> N_obs;
  int<lower=0> N_cens;
  array[N_obs] int<lower=0> y_obs; 
  vector[N_obs] x_obs; 
  vector[N_cens] x_cens;
  vector[N_obs] kids_obs;
  vector[N_cens] kids_cens;
  int<lower=0> ell;
}

transformed data {
    vector[N_obs] log_kids_obs = log(kids_obs);
    vector[N_cens] log_kids_cens = log(kids_cens);
}

parameters {
  real alpha;
  real beta;
}

model {
  y_obs ~ poisson_log(log_kids_obs + alpha + beta * x_obs); 
  real mu_j;
  for(j in 1:N_cens) {
    mu_j = exp(log_kids_cens[j] + alpha + beta * x_cens[j]);
    target += log_diff_exp(poisson_lcdf(ell | mu_j), poisson_lpmf(0 | mu_j));
  }
}