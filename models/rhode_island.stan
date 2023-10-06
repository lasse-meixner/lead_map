data {
  int<lower=0> N;
  array[N] int<lower=0> y; 
  vector[N] x; 
  vector[N] kids;
}

transformed data {
    vector[N] log_kids = log(kids);
}

parameters {
  real alpha;
  real beta;
}

model {
  y ~ poisson_log(log_kids + alpha + beta * x); 
}