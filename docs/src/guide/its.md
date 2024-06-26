# Interrupted Time Series Analysis
Sometimes we want to know how an outcome variable for a single unit changed after an event 
or intervention. For example, if regulators announce sanctions against company A, we might 
want to know how the price of stock A changed after the announcement. Since we do not know
what the price of Company A's stock would have been if the santions were not announced, we
need some way to predict those values. An interrupted time series analysis does this by 
using some covariates that are related to the oucome variable but not related to whether the 
event happened to predict what would have happened. The estimated effects are the 
differences between the predicted post-event counterfactual outcomes and the observed 
post-event outcomes, which can also be aggregated to mean or cumulative effects. 
Estimating an interrupted time series design in CausalELM consists of three steps.

!!! note
    If regularized is set to true then the ridge penalty will be estimated using generalized 
    cross validation where the maximum number of iterations is 2 * folds for the successive 
    halving procedure. However, if the penalty in on iteration is approximately the same as in 
    the previous penalty, then the procedure will stop early.

!!! note
    For a deeper dive on interrupted time series estimation see:
    
        Bernal, James Lopez, Steven Cummins, and Antonio Gasparrini. "Interrupted time series 
        regression for the evaluation of public health interventions: a tutorial." International 
        journal of epidemiology 46, no. 1 (2017): 348-355.

!!! note
    The flavor of interrupted time series implemented here is similar to the variant proposed 
    in:

        Brodersen, Kay H., Fabian Gallusser, Jim Koehler, Nicolas Remy, and Steven L. Scott. 
        "Inferring causal impact using Bayesian structural time-series models." (2015): 247-274.

    in that, although it is not Bayesian, it uses a nonparametric model of the pre-treatment 
    period and uses that model to forecast the counterfactual in the post-treatment period, as 
    opposed to the commonly used segment linear regression.

## Step 1: Initialize an interrupted time series estimator
The InterruptedTimeSeries method takes at least four agruments: an array of pre-event 
covariates, a vector of pre-event outcomes, an array of post-event covariates, and a vector 
of post-event outcomes. The interrupted time series estimator assumes outcomes are either 
continuous, count, or time to event variables.

!!! note
    Since extreme learning machines minimize the MSE, count outcomes will be predicted as 
    continuous variables.

!!! tip
    You can also specify whether or not to use L2 regularization, which activation function to 
    use, the metric to use when using cross validation to find the best number of neurons, the 
    minimum number of neurons to consider, the maximum number of neurons to consider, the number 
    of folds to use during cross caidation, the number of neurons to use in the ELM that learns 
    a mapping from number of neurons to validation loss, and whether to include a rolling 
    average autoregressive term. These options can be specified using the keyword arguments 
    regularized, activation, validation\_metric, min\_neurons, max\_neurons, folds, iterations, 
    approximator\_neurons, and autoregression.

```julia
# Generate some data to use
X₀, Y₀, X₁, Y₁ =  rand(1000, 5), rand(1000), rand(100, 5), rand(100)

# We could also use DataFrames
# using DataFrames
# X₀ = DataFrame(x1=rand(1000), x2=rand(1000), x3=rand(1000), x4=rand(1000), x5=rand(1000))
# X₁ = DataFrame(x1=rand(1000), x2=rand(1000), x3=rand(1000), x4=rand(1000), x5=rand(1000))
# Y₀, Y₁ = DataFrame(y=rand(1000)), DataFrame(y=rand(1000))

its = InterruptedTimeSeries(X₀, Y₀, X₁, Y₁)
```

## Step 2: Estimate the Treatment Effect
Estimating the treatment effect only requires one argument: an InterruptedTimeSeries struct.

```julia
estimate_causal_effect!(its)
```

## Step 3: Get a Summary
We can get a summary of the model, including a p-value and statndard via asymptotic 
randomization inference, by pasing the model to the summarize method.

Calling the summarize method returns a dictionary with the estimator's task (always 
regression for interrupted time series analysis), whether the model uses an L2 penalty, 
the activation function used in the model's outcome predictors, the validation metric used 
for cross validation to find the best number of neurons, the number of neurons used in the 
ELMs used by the estimator, the number of neurons used in the ELM used to learn a mapping 
from number of neurons to validation loss during cross validation, the causal effect, 
standard error, and p-value.
```julia
summarize(its)
```

## Step 4: Validate the Model
For an interrupted time series design to work well we need to be able to get an unbiased 
prediction of the counterfactual outcomes. If the event or intervention effected the 
covariates we are using to predict the counterfactual outcomes, then we will not be able to 
get unbiased predictions. We can verify this by conducting a Chow Test on the covariates. An
ITS design also assumes that any observed effect is due to the hypothesized intervention, 
rather than any simultaneous interventions, anticipation of the intervention, or any 
intervention that ocurred after the hypothesized intervention. We can use a Wald supremum 
test to see if the hypothesized intervention ocurred where there is the largest structural 
break in the outcome or if there was a larger, statistically significant break in the 
outcome that could confound an ITS analysis. The covariates in an ITS analysis should be 
good predictors of the outcome. If this is the case, then adding irrelevant predictors 
should not have much of a change on the results of the analysis. We can conduct all these 
tests in one line of code.

!!! tip
    One can also specify the number of simulated confounders to generate to test the sensitivity 
    of the model to confounding and the minimum and maximum proportion of data to use in the 
    Wald supremum test by including the n, low, and high keyword arguments.

!!! danger
    Obtaining correct estimates is dependent on meeting the assumptions for interrupted time 
    series estimation. If the assumptions are not met then any estimates may be biased and 
    lead to incorrect conclusions.

!!! note
    For a review of interrupted time series identifying assumptions and robustness checks, see:

        Baicker, Katherine, and Theodore Svoronos. Testing the validity of the single 
        interrupted time series design. No. w26080. National Bureau of Economic Research, 2019.

```julia
validate(its)
```