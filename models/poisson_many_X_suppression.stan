data {
  int<lower=0> N_obs;
  int<lower=0> N_cens;
  int<lower=1> K;
  array[N_obs] int<lower=0> y_obs; 
  matrix[N_obs, K] x_obs; 
  matrix[N_cens, K] x_cens;
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
  vector[K] beta;
}

model {
  y_obs ~ poisson_log_glm(x_obs, alpha, beta); 
  real mu_j;
  for(j in 1:N_cens) {
    mu_j = exp(log_kids_cens[j] + alpha + dot_product(beta, x_cens[j])); // Is there a better way to do this?
    target += log_diff_exp(poisson_lcdf(ell | mu_j), poisson_lpmf(0 | mu_j));
  }
}