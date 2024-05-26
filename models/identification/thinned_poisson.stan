data {
  int<lower=0> N; 
  vector[N] x; 
  vector[N] z;
  array[N] int<lower=0> y; 
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
  // For now, no prior
  vector[N] mu = exp(alpha + beta * x_demeaned);
  vector[N] pie = inv_logit(gamma + delta * z_demeaned);
  vector[N] lambda = mu .* pie; // elementwise product
  y ~ poisson(lambda); 
}

