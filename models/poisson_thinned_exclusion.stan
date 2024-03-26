data {
   int<lower=0> N_obs;
   int<lower=0> N_cens;
   int<lower=1> K;
   array[N_obs] int<lower=0> y_obs; 
   matrix[N_obs, K] x_obs; 
   matrix[N_cens, K] x_cens;
   vector[N_obs] z_obs; // exclusion
   vector[N_cens] z_cens;
   vector[N_obs] kids_obs; // offset
   vector[N_cens] kids_cens;
   array[N_cens] int<lower=0> ell;
 }

 transformed data {
    vector[N_obs] log_kids_obs = log(kids_obs);
    vector[N_cens] log_kids_cens = log(kids_cens);
    int<lower=0> N = N_obs + N_cens;
    matrix[N, K] X = append_row(x_obs, x_cens); // for posterior predictive checks
    vector[N] log_kids = append_row(log_kids_obs, log_kids_cens); // for posterior predictive checks
}

 parameters {
   real alpha;
   vector[K] beta;
   real gamma;
   real delta;
 }

 model {
   // add priors?
   vector[N_obs] mu_obs = exp(log_kids_obs + alpha + x_obs * beta); // this works for NxK * Kx1 (https://mc-stan.org/docs/2_18/stan-users-guide/vectorization.html)
   vector[N_obs] pi_obs = inv_logit(gamma + delta * z_obs);
   vector[N_obs] lambda_obs = mu_obs .* pi_obs; // elementwise product
   y_obs ~ poisson(lambda_obs); 
   for (j in 1:N_cens) {
     real mu_cens = exp(log_kids_cens[j] + alpha + dot_product(beta,x_cens[j]));
     real pi_cens = inv_logit(gamma + delta * z_cens[j]);
     real lambda_cens = mu_cens * pi_cens;
     target += log_diff_exp(poisson_lcdf(ell[j] | lambda_cens), poisson_lpmf(0 | lambda_cens));
   }
 }

// add generated quantities?