"""
Estimate causal effects with event study designs, G-computation, and doubly robust 
estiamtion using Extreme Learning machines.
   """
module Estimators

using ..ActivationFunctions: relu
using CausalELM: mean
using ..Metrics: mse
using ..CrossValidation: bestsize
using ..Models: ExtremeLearningMachine, ExtremeLearner, RegularizedExtremeLearner, fit!, 
    predictcounterfactual!, placebotest, predict

import CausalELM: estimatecausaleffect!

"""Abstract type for GComputation and DoublyRobust"""
abstract type  CausalEstimator end

"""Container for the results of an event study"""
mutable struct EventStudy
    """Covariates for the pre-event period"""
    X₀::Array{Float64}
    """Outcomes for the pre-event period"""
    Y₀::Array{Float64}
    """Covariates for the post-event period"""
    X₁::Array{Float64}
    """Outcomes for the post-event period"""
    Y₁::Array{Float64}
    """Either \"regression\" of \"classification\""""
    task::String
    """Whether to use L2 regularization"""
    regularized::Bool
    """Activation function to apply to the outputs from each neuron"""
    activation::Function
    """Validation metric to use when tuning the number of neurons"""
    validation_metric::Function
    """Minimum number of neurons to test in the hidden layer"""
    min_neurons::Int64
    """Maximum number of neurons to test in the hidden layer"""
    max_neurons::Int64
    """Number of cross validation folds"""
    folds::Int64
    """Number of iterations to perform cross validation"""
    iterations::Int64
    """Number of neurons in the hidden layer of the approximator ELM for cross validation"""
    approximator_neurons::Int64
    """Number of neurons in the ELM used for estimating the abnormal returns"""
    num_neurons::Int64
    """Extreme Learning Machine used to estimate the abnormal returns"""
    learner::ExtremeLearningMachine
    """Weights learned during training"""
    β::Array{Float64}
    """
    Counterfactual predicted for the post-treatment period using wieghts learned in the 
    pre-treatment period

    """
    Ŷ::Array{Float64}
    """
    The difference betwen the predicted counterfactual and the observed data at each 
    interval during the post-treatment period

    """
    abnormal_returns::Array{Float64}
    """
    Predictions of the counterfactual using covariates from the pre-treatment period and the 
    post-treatment period. If they are significantly different, there is likely an omitted 
    variable bias or other flaw in the experimental design.

    """
    placebo_test::Tuple{Vector{Float64}, Vector{Float64}}

"""
    EventStudy(X₀, Y₀, X₁, Y₁; task, regularized, activation, validation_metric, 
        min_neurons, max_neurons, folds, iterations, approximator_neurons)

Initialize an event study estimator, also known as interrupted time series analysis.

Note that X₀, Y₀, X₁, and Y₁ must all be floating point numbers.

Examples
```julia-repl
julia> X₀, Y₀, X₁, Y₁ =  rand(100, 5), rand(100), rand(10, 5), rand(10)
julia> m1 = EventStudy(X₀, Y₀, X₁, Y₁)
julia> m2 = EventStudy(X₀, Y₀, X₁, Y₁; task="regression")
julia> m3 = EventStudy(X₀, Y₀, X₁, Y₁; task="regression", regularized=true)
julia> m4 = EventStudy(X₀, Y₀, X₁, Y₁; task="regression", regularized=true, activation=relu)
```
"""
    function EventStudy(X₀, Y₀, X₁, Y₁; task="regression", regularized=true, 
        activation=relu, validation_metric=mse, min_neurons=1, max_neurons=100, folds=5, 
        iterations=Int(round(size(X₀, 1)/10)), 
        approximator_neurons=Int(round(size(X₀, 1)/10)))

        if task ∉ ("regression", "classification")
            throw(ArgumentError("task must be either regression or classification"))
        end

        new(Float64.(X₀), Float64.(Y₀), Float64.(X₁), Float64.(Y₁), task, regularized, 
            activation, validation_metric, min_neurons, max_neurons, folds, iterations, 
            approximator_neurons, 0)
    end
end


"""Container for the results of G-Computation"""
mutable struct GComputation <: CausalEstimator
    """Covariates"""
    X::Array{Float64}
    """Outomes variable"""
    Y::Array{Float64}
    """Treatment statuses"""
    T::Array{Float64}
    """Either regression or classification"""
    task::String
    """Either ATE, ITT, or ATT"""
    quantity_of_interest::String
    """Whether to use L2 regularization"""
    regularized::Bool
    """Activation function to apply to the outputs from each neuron"""
    activation::Function
    """Whether the data is of a temporal nature eg. (time series, panel data)"""
    temporal::Bool
    """Validation metric to use when tuning the number of neurons"""
    validation_metric::Function
    """Minimum number of neurons to test in the hidden layer"""
    min_neurons::Int64
    """Maximum number of neurons to test in the hidden layer"""
    max_neurons::Int64
    """Number of cross validation folds"""
    folds::Int64
    """Number of iterations to perform cross validation"""
    iterations::Int64
    """Number of neurons in the hidden layer of the approximator ELM for cross validation"""
    approximator_neurons::Int64
    """Number of neurons in the ELM used for estimating the abnormal returns"""
    num_neurons::Int64
    """Extreme Learning Machine used to estimate the causal effect"""
    learner::ExtremeLearningMachine
    """Weights learned during training"""
    β::Array{Float64}
    """The effect of exposure or treatment"""
    causal_effect::Float64

"""
GComputation(X, Y, T, task, quantity_of_interest, regularized, activation, temporal, 
    validation_metric, min_neurons, max_neurons, folds, iterations, approximator_neurons)

Initialize a G-Computation estimator.

Note that X, Y, and T must all be floating point numbers.

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = GComputation(X, Y, T)
julia> m2 = GComputation(X, Y, T; task="regression")
julia> m3 = GComputation(X, Y, T; task="regression", quantity_of_interest="ATE)
julia> m4 = GComputation(X, Y, T; task="regression", quantity_of_interest="ATE, 
julia> regularized=true)
```
"""
    function GComputation(X, Y, T; task="regression", quantity_of_interest="ATE", 
        regularized=true,activation=relu, temporal=false, validation_metric=mse, 
        min_neurons=1, max_neurons=100, folds=5, iterations=Int(round(size(X, 1)/10)), 
        approximator_neurons=Int(round(size(X, 1)/10)))

        if task ∉ ("regression", "classification")
            throw(ArgumentError("task must be either regression or classification"))
        elseif quantity_of_interest ∉ ("ATE", "ITT", "ATT")
            throw(ArgumentError("quantity_of_interest must be ATE, ITT, or ATT"))
        end

        new(Float64.(X), Float64.(Y), Float64.(T), task, quantity_of_interest, regularized, 
            activation, temporal, validation_metric, min_neurons, max_neurons, folds, 
            iterations, approximator_neurons, 0)
    end
end

"""Container for the results of doubly robust estimation"""
mutable struct DoublyRobust <: CausalEstimator
    """Covariates"""
    X::Array{Float64}
    """Propensity score covariates"""
    Xₚ::Array{Float64}
    """Outomes variable"""
    Y::Array{Float64}
    """Treatment statuses"""
    T::Array{Float64}
    """Either regression or classification"""
    task::String
    """Either ATE, ITT, or ATT"""
    quantity_of_interest::String
    """Whether to use L2 regularization"""
    regularized::Bool
    """Activation function to apply to the outputs from each neuron"""
    activation::Function
    """Validation metric to use when tuning the number of neurons"""
    validation_metric::Function
    """Minimum number of neurons to test in the hidden layer"""
    min_neurons::Int64
    """Maximum number of neurons to test in the hidden layer"""
    max_neurons::Int64
    """Number of cross validation folds"""
    folds::Int64
    """Number of iterations to perform cross validation"""
    iterations::Int64
    """Number of neurons in the hidden layer of the approximator ELM for cross validation"""
    approximator_neurons::Int64
    """Number of neurons in the ELM used for estimating the abnormal returns"""
    num_neurons::Int64
    """Propensity scores"""
    ps::Array{Float64}
    """Predicted outcomes for teh control group"""
    μ₀::Array{Float64}
    """Predicted outcomes for the treatment group"""
    μ₁::Array{Float64}
    """The effect of exposure or treatment"""
    causal_effect::Float64

    """
DoublyRobust(X, Xₚ, Y, T, task, quantity_of_interest, regularized, activation, 
    validation_metric, min_neurons, max_neurons, folds, iterations, approximator_neurons)

Initialize a doubly robust estimator.

Note that X, Y, and T must all be floating point numbers.

Examples
```julia-repl
julia> X, Xₚ, Y, T =  rand(100, 5), rand(100, 4), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = DoublyRobust(X, Xₚ, Y, T)
julia> m2 = DoublyRobust(X, Xₚ, Y, T; task="regression")
julia> m3 = DoublyRobust(X, Xₚ, Y, T; task="regression", quantity_of_interest="ATE)
```
"""
    function DoublyRobust(X, Xₚ, Y, T; task="regression", quantity_of_interest="ATE", 
        regularized=true,activation=relu, validation_metric=mse, min_neurons=1, 
        max_neurons=100, folds=5, iterations=Int(round(size(X, 1)/10)), 
        approximator_neurons=Int(round(size(X, 1)/10)))

        if task ∉ ("regression", "classification")
            throw(ArgumentError("task must be either regression or classification"))
        elseif quantity_of_interest ∉ ("ATE", "ITE", "ATT")
            throw(ArgumentError("quantity_of_interest must be ATE, ITE, or ATT"))
        end

        new(Float64.(X), Float64.(Xₚ), Float64.(Y), Float64.(T), task, quantity_of_interest, 
            regularized, activation, validation_metric, min_neurons, max_neurons, folds, 
            iterations, approximator_neurons, 0)
    end
end

"""
    estimatecausaleffect!(study)

Estimate the abnormal returns in an event study.

Examples
```julia-repl
julia> X₀, Y₀, X₁, Y₁ =  rand(100, 5), rand(100), rand(10, 5), rand(10)
julia> m1 = EventStudy(X₀, Y₀, X₁, Y₁)
julia> estimatecausaleffect!(m1)
0.25714308
```
"""
function estimatecausaleffect!(study::EventStudy)
    # We will not find the best number of neurons after we have already estimated the causal
    # effect and are getting p-values, confidence intervals, or standard errors. We will use
    # the same number that was found when calling this method.
    if study.num_neurons === 0
        study.num_neurons = bestsize(study.X₀, study.Y₀, study.validation_metric, 
            study.task, study.activation, study.min_neurons, study.max_neurons, 
            study.regularized, study.folds, true, study.iterations, 
            study.approximator_neurons)
    end

    if study.regularized
        study.learner = RegularizedExtremeLearner(study.X₀, study.Y₀, study.num_neurons, 
            study.activation)
    else
        study.learner = ExtremeLearner(study.X₀, study.Y₀, study.num_neurons, 
            study.activation)
    end

    study.β, study.Ŷ = fit!(study.learner), predictcounterfactual!(study.learner, study.X₁)
    study.abnormal_returns, study.placebo_test = study.Ŷ - study.Y₁, 
        placebotest(study.learner)

    return study.abnormal_returns
end

"""
    estimatecausaleffect!(g)

Estimate a causal effect of interest using G-Computation.

If treatents are administered at multiple time periods, the effect will be estimated as the average
difference between the outcome of being treated in all periods and being treated in no periods.
For example, given that individuals 1, 2, ..., i ∈ I recieved either a treatment or a placebo in p 
different periods, the model would estimate the average treatment effect as 
E[Yᵢ|T₁=1, T₂=1, ... Tₚ=1, Xₚ] - E[Yᵢ|T₁=0, T₂=0, ... Tₚ=0, Xₚ].

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = GComputation(X, Y, T)
julia> estimatecausaleffect!(m1)
0.31067439
```
"""
function estimatecausaleffect!(g::GComputation)
    full_covariates = hcat(g.X, g.T)

    if g.quantity_of_interest ∈ ("ITT", "ATE")
        Xₜ, Xᵤ= hcat(g.X, ones(size(g.T, 1))), hcat(g.X, zeros(size(g.T, 1)))
    else
        Xₜ, Xᵤ = hcat(g.X, g.T), hcat(g.X, zeros(size(g.Y, 1)))
    end

    # We will not find the best number of neurons after we have already estimated the causal
    # effect and are getting p-values, confidence intervals, or standard errors. We will use
    # the same number that was found when calling this method.
    if g.num_neurons === 0
        g.num_neurons = bestsize(full_covariates, g.Y, g.validation_metric, g.task, 
            g.activation, g.min_neurons, g.max_neurons, g.regularized, g.folds, g.temporal, 
            g.iterations, g.approximator_neurons)
    end

    if g.regularized
        g.learner = RegularizedExtremeLearner(full_covariates, g.Y, g.num_neurons, 
            g.activation)
    else
        g.learner = ExtremeLearner(full_covariates, g.Y, g.num_neurons, g.activation)
    end

    g.β = fit!(g.learner)
    g.causal_effect = sum(predict(g.learner, Xₜ) - predict(g.learner, Xᵤ))/size(Xₜ, 1)

    return g.causal_effect
end

"""
    estimatecausaleffect!(DRE)

Estimate a causal effect of interest using doubly robust estimation.

Unlike other estimators, this method does not support time series or panel data. This method also 
does not work as well with smaller datasets because it estimates separate outcome models for the 
treatment and control groups.

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = DoublyRobust(X, Y, T)
julia> estimatecausaleffect!(m1)
0.31067439
```
"""
function estimatecausaleffect!(DRE::DoublyRobust)
    x₀, x₁, y₀, y₁ = DRE.X[DRE.T .== 0,:], DRE.X[DRE.T .== 1,:], DRE.Y[DRE.T .== 0], 
        DRE.Y[DRE.T .== 1]

    # We will not find the best number of neurons after we have already estimated the causal
    # effect and are getting p-values, confidence intervals, or standard errors. We will use
    # the same number that was found when calling this method.
    if DRE.num_neurons === 0
        DRE.num_neurons = bestsize(DRE.X, DRE.Y, DRE.validation_metric, DRE.task, 
            DRE.activation, DRE.min_neurons, DRE.max_neurons, DRE.regularized, DRE.folds, 
            false, DRE.iterations, DRE.approximator_neurons)
    end

    if DRE.regularized && DRE.quantity_of_interest ∈ ("ATE", "ITE")
        ps_model, μ₀_model = dre_att!(DRE, x₀, y₀)
        dre_ate!(DRE, x₁, y₁)

    elseif DRE.regularized && DRE.quantity_of_interest === "ATT"
        DRE.causal_effect = mean(((1 .- DRE.T).*(DRE.Y .- DRE.μ₀))/((1 .- DRE.ps) .+ DRE.μ₀))

    elseif !DRE.regularized && DRE.quantity_of_interest ∈ ("ATE", "ITE")
        ps_model, μ₀_model = dre_att!(DRE, x₀, y₀)
        dre_ate!(DRE, x₁, y₁)
        
    else
        DRE.causal_effect = mean(((1 .- DRE.T).*(DRE.Y .- DRE.μ₀))/((1 .- DRE.ps).+ DRE.μ₀))
    end
    return DRE.causal_effect
end

"""
    dre_att!(DRE, x₀, y₀)

Estimate the average treatment for the treated for a boudlby robust estimator.

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = DoublyRobust(X, Y, T)
julia> dre_att!(m1, x₀, y₀)
-0.0003169188577114481s
```
"""
function dre_att!(DRE::DoublyRobust, x₀::Array{Float64}, y₀::Array{Float64})
    # Propensity score and separate outcome models
    ps_model = RegularizedExtremeLearner(DRE.Xₚ, DRE.T, DRE.num_neurons, DRE.activation)
    μ₀_model = RegularizedExtremeLearner(x₀, y₀, DRE.num_neurons, DRE.activation)

    fit!(ps_model); fit!(μ₀_model)
    DRE.ps, DRE.μ₀ = predict(ps_model, DRE.X), predict(μ₀_model, DRE.X)

    return ps_model, μ₀_model
end

"""
    dre_ate!(DRE, x₁, y₁)

Estimate the average treatment effect for a boudlby robust estimator.

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = DoublyRobust(X, Y, T)
julia> dre_ate!(m1, x₀, y₀)
0.007359646691854193
```
"""
function dre_ate!(DRE::DoublyRobust, x₁::Array{Float64}, y₁::Array{Float64})
    μ₁_model = RegularizedExtremeLearner(x₁, y₁, DRE.num_neurons, DRE.activation)
            fit!(μ₁_model)
            DRE.μ₁ = predict(μ₁_model, DRE.X)

            E₁ = mean(DRE.T.*(DRE.Y .- DRE.μ₁)/(DRE.ps .+ DRE.μ₁))
            E₀ = mean(((1 .- DRE.T).*(DRE.Y .- DRE.μ₀))/((1 .- DRE.ps) .+ DRE.μ₀))
            DRE.causal_effect = E₁ - E₀
end

end