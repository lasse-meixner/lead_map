data {
    int<lower=0> N_obs;
    int<lower=0> N_cens;
    array[N_obs] int<lower=0> y_obs; 
    // add P predictors (median_income, house_price, poverty, black_prop, building_period, svi) as individual vectors - to be able to specify priors on individual coefs
    vector[N_obs] median_income_obs;
    vector[N_obs] house_price_obs;
    vector[N_obs] poverty_obs;
    vector[N_obs] black_prop_obs;
    vector[N_obs] building_period_obs;
    vector[N_obs] svi_obs;
    // censored data
    vector[N_cens] median_income_cens;
    vector[N_cens] house_price_cens;
    vector[N_cens] poverty_cens;
    vector[N_cens] black_prop_cens;
    vector[N_cens] building_period_cens;
    vector[N_cens] svi_cens;
    // pediatrician as exclusion 
    vector[N_obs] z_obs; // exclusion
    vector[N_cens] z_cens;
    vector[N_obs] kids_obs; // offset
    vector[N_cens] kids_cens;
    // array[N_cens] int<lower=0> ell;
 }

 transformed data {
    int<lower=0> N = N_obs + N_cens;
    vector[N_obs] log_kids_obs = log(kids_obs);
    vector[N_cens] log_kids_cens = log(kids_cens);
    // create composite vectors for predictors (ignoring the censoring for PPC)
    vector[N] median_income = append_row(median_income_obs, median_income_cens);
    vector[N] house_price = append_row(house_price_obs, house_price_cens);
    vector[N] poverty = append_row(poverty_obs, poverty_cens);
    vector[N] black_prop = append_row(black_prop_obs, black_prop_cens);
    vector[N] building_period = append_row(building_period_obs, building_period_cens);
    vector[N] svi = append_row(svi_obs, svi_cens);
    // create composite vectors for exclusion
    vector[N] z = append_row(z_obs, z_cens);
    // create composite vectors for kids
    vector[N] log_kids = append_row(log_kids_obs, log_kids_cens);
}

// Note: commented out here since we are not estimating yet, just for oversight
// parameters {
//     // poisson params
//     real alpha;
//     real beta_inc;
//     real beta_hp;
//     real beta_poverty;
//     real beta_black;
//     real beta_bp;
//     real beta_svi;
//     // logit params
//     real gamma;
//     real delta; // for pediatricians
//     real kappa_inc;
//     real kappa_bp;
//     real kappa_svi;
//  }

// omit model for now -> want to do prior predictive checks. we want these priors to a) include some additional information we have about these predictors effect on testing & lead, and b) regularize estimation in the weakly identified model.

generated quantities {
    // poisson priors (Note: It's quite "easy" to hit the upper bound on the rate...)
    real alpha = normal_rng(-1.69, 4);
    real beta_inc = normal_rng(0, 0.1);
    real beta_hp = normal_rng(0, 0.1);
    real beta_poverty = normal_rng(0, 0.1);
    real beta_black = normal_rng(0, 0.1);
    real beta_bp = normal_rng(0, 0.1);
    real beta_svi = normal_rng(0, 0.1);

    // logit priors
    real gamma = normal_rng(0, 1.2); // for logit intercept - from "Rethinking" playlist suggestion
    real delta = normal_rng(0, 1); // for pediatricians
    real kappa_inc = normal_rng(0, 1);
    real kappa_bp = normal_rng(0, 1); //lognormal_rng(0, 0.4);
    real kappa_svi = normal_rng(0, 1);

    // simulate quantities
    vector[N] mu = exp(alpha + beta_inc * median_income + beta_hp * house_price + beta_poverty * poverty + beta_black * black_prop + beta_bp * building_period + beta_svi * svi);
    vector[N] pi = inv_logit(gamma + delta * z + kappa_inc * median_income + kappa_bp * building_period + kappa_svi * svi);
    vector[N] lambda = mu .* pi;
    array[N] int<lower=0> y_thinned = poisson_rng(lambda);
    array[N] int<lower=0> y_star = poisson_rng(mu);
}