data {
   int<lower=0> N_obs;
   int<lower=0> N_cens;
   int<lower=1> K; // nr of predictors in poisson
   int<lower=1> L; // nr of predictors in logit
   array[N_obs] int<lower=0> y_obs; 
   matrix[N_obs, K] x_obs; 
   matrix[N_cens, K] x_cens;
   matrix[N_obs, L] z_obs; // logit predictors + exclusion
   matrix[N_cens, L] z_cens;
   vector[N_obs] kids_obs; // offset
   vector[N_cens] kids_cens;
   array[N_cens] int<lower=0> ell;
   array[N_cens] int<lower=0, upper=1> zero_sup;
 }

 transformed data {
    vector[N_obs] log_kids_obs = log(kids_obs);
    vector[N_cens] log_kids_cens = log(kids_cens);
    int<lower=0> N = N_obs + N_cens;
    matrix[N, K] X = append_row(x_obs, x_cens); // for posterior predictive checks
    matrix[N, L] Z = append_row(z_obs, z_cens); // for posterior predictive checks
    vector[N] log_kids = append_row(log_kids_obs, log_kids_cens); // for posterior predictive checks
}

 parameters {
   real alpha;
   vector[K] beta;
   real gamma;
   vector[L-1] delta; // all but last delta coefficient
   real<lower=0> delta_last; // last delta coefficient for exclusion restriction
 }

 model {
   alpha ~ normal(-4.12,0.416); // Note: see NHANES
   gamma ~ normal(0, 1.2); // logit intercept
   beta ~ normal(0, 0.5); // poisson coefficients (standardised)
   delta ~ normal(0, 0.4); // logit coefficients (standardised)
   delta_last ~ lognormal(-0.9, 0.4); // prior exclusion restriction
   vector[N_obs] mu_obs = exp(log_kids_obs + alpha + x_obs * beta); // this works for NxK * Kx1 (https://mc-stan.org/docs/2_18/stan-users-guide/vectorization.html)
   vector[N_obs] pi_obs = inv_logit(gamma + z_obs[, 1:(L-1)] * delta + z_obs[, L] * delta_last); // this works for NxL * Lx1 (order matters)
   vector[N_obs] lambda_obs = mu_obs .* pi_obs; // elementwise product
   y_obs ~ poisson(lambda_obs); 
   for (j in 1:N_cens) {
     real mu_cens = exp(log_kids_cens[j] + alpha + dot_product(beta,x_cens[j]));
     real pi_cens = inv_logit(gamma + dot_product(delta,z_cens[j, 1:(L-1)]) + delta_last * z_cens[j, L]);
     real lambda_cens = mu_cens * pi_cens;
     target += log_diff_exp(poisson_lcdf(ell[j] | lambda_cens), poisson_lpmf(0 | lambda_cens));
   }
 }


// add generated quantities?

generated quantities {
vector[N] mu = exp(log_kids + alpha + X * beta);
vector[N] pi = inv_logit(gamma + Z[, 1:(L-1)] * delta + Z[, L] * delta_last);
array[N] int<lower=0> y_star = poisson_log_rng(mu .* pi);
array[N] int<lower=0> y = poisson_log_rng(mu);
}

// generate estimates for the unknown P(tested|negative) = (Tested_i - pi-mu)/(kids-mu)?