data {
  int<lower=0> N; 
  array[N] int<lower=0> y; 
  vector[N] x; 
  vector[N] z;
  real alpha_prior_var;
}

transformed data {
  real x_bar = mean(x); 
  real z_bar = mean(z); 
  vector[N] x_demeaned = (x - x_bar); 
  vector[N] z_demeaned = (z - z_bar);
}

parameters {
  real alpha;
  real beta;
  real gamma;
  real delta;
}

model {
  // priors
  alpha ~ normal(0.5, alpha_prior_var);
  gamma ~ normal(0, 1.5);
  // model
  vector[N] mu = exp(alpha + beta * x_demeaned);
  vector[N] pie = inv_logit(gamma + delta * z_demeaned); // (inverse of logit is logistic function 1/(1+exp(-x)))
  vector[N] lambda = mu .* pie; // elementwise product
  y ~ poisson(lambda); 
}

