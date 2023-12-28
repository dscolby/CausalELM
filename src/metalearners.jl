"""Abstract type for metalearners"""
abstract type Metalearner <: NonTimeSeriesEstimator end

"""S-Learner for CATE estimation."""
mutable struct SLearner <: Metalearner
    """Covariates"""
    X::Array{Float64}
    """Outomes variable"""
    Y::Array{Float64}
    """Treatment statuses"""
    T::Array{Float64}
    """Either regression or classification"""
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
    """This will always be set to CATE and is only used by summarized methods"""
    quantity_of_interest::String
    """This will always be set to false and is only accessed by summarize methods"""
    temporal::Bool
    """Number of neurons in the ELM used for estimating the abnormal returns"""
    num_neurons::Int64
    """The effect of exposure or treatment"""
    causal_effect::Array{Float64}
    """The model used to predict the outcomes"""
    learner::ExtremeLearningMachine

"""
SLearner(X, Y, T, task, regularized, activation, validation_metric, min_neurons, 
    max_neurons, folds, iterations, approximator_neurons)

Initialize a S-Learner.

For an overview of S-Learners and other metalearners see:
    Künzel, Sören R., Jasjeet S. Sekhon, Peter J. Bickel, and Bin Yu. "Metalearners for 
    estimating heterogeneous treatment effects using machine learning." Proceedings of the 
    national academy of sciences 116, no. 10 (2019): 4156-4165.

Note that X, Y, and T must all contain floating point numbers.

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = SLearner(X, Y, T)
julia> m2 = SLearner(X, Y, T; task="regression")
julia> m3 = SLearner(X, Y, T; task="regression", regularized=true)
```
"""
    function SLearner(X, Y, T; task="regression", regularized=false, activation=relu, 
        validation_metric=mse, min_neurons=1, max_neurons=100, folds=5, 
        iterations=Int(round(size(X, 1)/10)), 
        approximator_neurons=Int(round(size(X, 1)/10)))

        if task ∉ ("regression", "classification")
            throw(ArgumentError("task must be either regression or classification"))
        end

        new(Float64.(X), Float64.(Y), Float64.(T), task, regularized, activation,  
            validation_metric, min_neurons, max_neurons, folds, iterations, 
            approximator_neurons, "CATE", false, 0)
    end
end

"""T-Learner for CATE estimation."""
mutable struct TLearner <: Metalearner
    """Covariates"""
    X::Array{Float64}
    """Outomes variable"""
    Y::Array{Float64}
    """Treatment statuses"""
    T::Array{Float64}
    """Either regression or classification"""
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
    """This will always be CATE and is used by summarize methods"""
    quantity_of_interest::String
    """This will always be set to false and is only accessed by summarize methods"""
    temporal::Bool
    """Number of neurons in the ELM used for estimating the abnormal returns"""
    num_neurons::Int64
    """Weights learned during training"""
    causal_effect::Array{Float64}
    """Extreme Learning Machine used for the first stage of estimation"""
    μ₀::ExtremeLearningMachine
    """Extreme Learning Machine used for the first stage of estimation"""
    μ₁::ExtremeLearningMachine

"""
TLearner(X, Y, T, task, regularized, activation, validation_metric, min_neurons, 
    max_neurons, folds, iterations, approximator_neurons)

Initialize a T-Learner.

For an overview of T-Learners and other metalearners see:
    Künzel, Sören R., Jasjeet S. Sekhon, Peter J. Bickel, and Bin Yu. "Metalearners for 
    estimating heterogeneous treatment effects using machine learning." Proceedings of the 
    national academy of sciences 116, no. 10 (2019): 4156-4165.

Note that X, Y, and T must all be floating point numbers.

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = TLearner(X, Y, T)
julia> m2 = TLearner(X, Y, T; task="regression")
julia> m3 = TLearner(X, Y, T; task="regression", regularized=true)
```
"""
    function TLearner(X, Y, T; task="regression", regularized=false, activation=relu, 
        validation_metric=mse, min_neurons=1, max_neurons=100, folds=5, 
        iterations=Int(round(size(X, 1)/10)), 
        approximator_neurons=Int(round(size(X, 1)/10)))

        if task ∉ ("regression", "classification")
            throw(ArgumentError("task must be either regression or classification"))
        end

        new(Float64.(X), Float64.(Y), Float64.(T), task, regularized, activation,  
            validation_metric, min_neurons, max_neurons, folds, iterations, 
            approximator_neurons, "CATE", false, 0)
    end
end

"""X-Learner for CATE estimation."""
mutable struct XLearner <: Metalearner
    """Covariates"""
    X::Array{Float64}
    """Outomes variable"""
    Y::Array{Float64}
    """Treatment statuses"""
    T::Array{Float64}
    """Either regression or classification"""
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
    """This will always be CATE and is used by summarize methods"""
    quantity_of_interest::String
    """This will always be set to false and is only accessed by summarize methods"""
    temporal::Bool
    """Number of neurons in the ELM used for estimating the abnormal returns"""
    num_neurons::Int64
    """Extreme Learning Machine used for the first stage of estimation"""
    μ₀::ExtremeLearningMachine
    """Extreme Learning Machine used for the first stage of estimation"""
    μ₁::ExtremeLearningMachine
    """Individual propensity scores"""
    ps::Array{Float64}
    """The effect of exposure or treatment"""
    causal_effect::Array{Float64}

"""
XLearner(X, Y, T, task, regularized, activation, validation_metric, min_neurons, 
    max_neurons, folds, iterations, approximator_neurons)

Initialize an X-Learner.

For an overview of X-Learners and other metalearners see:
    Künzel, Sören R., Jasjeet S. Sekhon, Peter J. Bickel, and Bin Yu. "Metalearners for 
    estimating heterogeneous treatment effects using machine learning." Proceedings of the 
    national academy of sciences 116, no. 10 (2019): 4156-4165.

Note that X, Y, and T must all be floating point numbers.

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = XLearner(X, Y, T)
julia> m2 = XLearner(X, Y, T; task="regression")
julia> m3 = XLearner(X, Y, T; task="regression", regularized=true)
```
"""
    function XLearner(X, Y, T; task="regression", regularized=false, activation=relu, 
        validation_metric=mse, min_neurons=1, max_neurons=100, folds=5, 
        iterations=Int(round(size(X, 1)/10)), 
        approximator_neurons=Int(round(size(X, 1)/10)))

        if task ∉ ("regression", "classification")
            throw(ArgumentError("task must be either regression or classification"))
        end

        new(Float64.(X), Float64.(Y), Float64.(T), task, regularized, activation,  
            validation_metric, min_neurons, max_neurons, folds, iterations, 
            approximator_neurons, "CATE", false, 0)
    end
end

"""Container for the results of an R-learner"""
mutable struct RLearner <: Metalearner
    dml::DoubleMachineLearning
    """The effect of exposure or treatment"""
    causal_effect::Array{Float64}

    function RLearner(X, Y, T; task="regression", quantity_of_interest="CATE", 
        activation=relu, validation_metric=mse, min_neurons=1, max_neurons=100, folds=5, 
        iterations=Int(round(size(X, 1)/10)), 
        approximator_neurons=Int(round(size(X, 1)/10)))

        new(DoubleMachineLearning(X, Y, T; task=task, regularized=true, 
            activation=activation, validation_metric=validation_metric, 
            min_neurons=min_neurons, max_neurons=max_neurons, folds=folds, 
            iterations=iterations, approximator_neurons=approximator_neurons))
    end
end

"""
    estimate_causal_effect!(s)

Estimate the CATE using an S-learner.

For an overview of S-learning see:

    Künzel, Sören R., Jasjeet S. Sekhon, Peter J. Bickel, and Bin Yu. "Metalearners for 
    estimating heterogeneous treatment effects using machine learning." Proceedings of the 
    national academy of sciences 116, no. 10 (2019): 4156-4165.

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m4 = SLearner(X, Y, T)
julia> estimate_causal_effect!(m4)
[0.20729633391630697, 0.20729633391630697, 0.20729633391630692, 0.20729633391630697, 
0.20729633391630697, 0.20729633391630697, 0.20729633391630697, 0.20729633391630703, 
0.20729633391630697, 0.20729633391630697  …  0.20729633391630703, 0.20729633391630697, 
0.20729633391630692, 0.20729633391630703, 0.20729633391630697, 0.20729633391630697, 
0.20729633391630692, 0.20729633391630697, 0.20729633391630697, 0.20729633391630697]
```
"""
function estimate_causal_effect!(s::SLearner)
    full_covariates = hcat(s.X, s.T)
    Xₜ, Xᵤ= hcat(s.X, ones(size(s.T, 1))), hcat(s.X, zeros(size(s.T, 1)))

    # We will not find the best number of neurons after we have already estimated the causal
    # effect and are getting p-values, confidence intervals, or standard errors. We will use
    # the same number that was found when calling this method.
    if s.num_neurons === 0
        s.num_neurons = best_size(full_covariates, s.Y, s.validation_metric, s.task, 
            s.activation, s.min_neurons, s.max_neurons, s.regularized, s.folds, false,
            s.iterations, s.approximator_neurons)
    end

    if s.regularized
        s.learner = RegularizedExtremeLearner(full_covariates, s.Y, s.num_neurons, 
            s.activation)
    else
        s.learner = ExtremeLearner(full_covariates, s.Y, s.num_neurons, s.activation)
    end

    fit!(s.learner)
    predictionsₜ, predictionsᵪ = predict(s.learner, Xₜ), predict(s.learner, Xᵤ)
    s.causal_effect = @fastmath vec(predictionsₜ .- predictionsᵪ)

    return s.causal_effect
end

"""
    estimate_causal_effect!(t)

Estimate the CATE using an T-learner.

For an overview of T-learning see:

    Künzel, Sören R., Jasjeet S. Sekhon, Peter J. Bickel, and Bin Yu. "Metalearners for 
    estimating heterogeneous treatment effects using machine learning." Proceedings of the 
    national academy of sciences 116, no. 10 (2019): 4156-4165.

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m5 = TLearner(X, Y, T)
julia> estimatecausaleffect!(m5)
[0.0493951571746305, 0.049395157174630444, 0.0493951571746305, 0.049395157174630444, 
0.04939515717463039, 0.04939515717463039, 0.04939515717463039, 0.04939515717463039, 
0.049395157174630444, 0.04939515717463061  …  0.0493951571746305, 0.04939515717463039, 
0.0493951571746305, 0.04939515717463039, 0.0493951571746305, 0.04939515717463039, 
0.04939515717463039, 0.049395157174630444, 0.04939515717463039, 0.049395157174630444]
```
"""
function estimate_causal_effect!(t::TLearner)
    x₀, x₁, y₀, y₁ = t.X[t.T .== 0,:], t.X[t.T .== 1,:], t.Y[t.T .== 0], t.Y[t.T .== 1]

    # We will not find the best number of neurons after we have already estimated the causal
    # effect and are getting p-values, confidence intervals, or standard errors. We will use
    # the same number that was found when calling this method.
    if t.num_neurons === 0
        t.num_neurons = best_size(t.X, t.Y, t.validation_metric, t.task, t.activation, 
            t.min_neurons, t.max_neurons, t.regularized, t.folds, false, t.iterations, 
            t.approximator_neurons)
    end

    if t.regularized
        t.μ₀ = RegularizedExtremeLearner(x₀, y₀, t.num_neurons, t.activation) 
        t.μ₁ = RegularizedExtremeLearner(x₁, y₁, t.num_neurons, t.activation)
    else
        t.μ₀ = ExtremeLearner(x₀, y₀, t.num_neurons, t.activation) 
        t.μ₁ = ExtremeLearner(x₁, y₁, t.num_neurons, t.activation)
    end

    fit!(t.μ₀); fit!(t.μ₁)
    predictionsₜ, predictionsᵪ = predict(t.μ₁, t.X), predict(t.μ₀, t.X)
    t.causal_effect = @fastmath vec(predictionsₜ .- predictionsᵪ)

    return t.causal_effect
end

"""
estimate_causal_effect!(x)

Estimate the CATE using an X-learner.

For an overview of X-learning see:

    Künzel, Sören R., Jasjeet S. Sekhon, Peter J. Bickel, and Bin Yu. "Metalearners for 
    estimating heterogeneous treatment effects using machine learning." Proceedings of the 
    national academy of sciences 116, no. 10 (2019): 4156-4165.

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = XLearner(X, Y, T)
julia> estimatecausaleffect!(m1)
[-0.025012644892878473, -0.024634294305967294, -0.022144246680543364, -0.023983138957276127, 
-0.024756239357838557, -0.019409519377053822, -0.02312807640357356, -0.016967113188439076, 
-0.020188871831409317, -0.02546526148141366  …  -0.019811641136866287, 
-0.020780821058711863, -0.013588359417922776, -0.020438648396328824, -0.016169487825519843, 
-0.024031422484491572, -0.01884713946778991, -0.021163590874553318, -0.014607310062509895, 
-0.022449034332142046]
```
"""
function estimate_causal_effect!(x::XLearner)
    # We will not find the best number of neurons after we have already estimated the causal
    # effect and are getting p-values, confidence intervals, or standard errors. We will use
    # the same number that was found when calling this method.
    if x.num_neurons === 0
        x.num_neurons = best_size(x.X, x.Y, x.validation_metric, x.task, x.activation, 
            x.min_neurons, x.max_neurons, x.regularized, x.folds, false, x.iterations, 
            x.approximator_neurons)
    end
    
    stage1!(x)
    μχ₀, μχ₁ = stage2!(x)

    x.causal_effect = @fastmath vec(((x.ps.*predict(μχ₀, x.X)) .+ 
        ((1 .- x.ps).*predict(μχ₁, x.X))))

    return x.causal_effect
end

"""
estimate_causal_effect!(r)

Estimate the CATE using an R-learner.

For an overview of R-learning see:

    Künzel, Sören R., Jasjeet S. Sekhon, Peter J. Bickel, and Bin Yu. "Metalearners for 
    estimating heterogeneous treatment effects using machine learning." Proceedings of the 
    national academy of sciences 116, no. 10 (2019): 4156-4165.

Examples
```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = RLearner(X, Y, T)
julia> estimatecausaleffect!(m1)
[-0.025012644892878473, -0.024634294305967294, -0.022144246680543364, -0.023983138957276127, 
-0.024756239357838557, -0.019409519377053822, -0.02312807640357356, -0.016967113188439076, 
-0.020188871831409317, -0.02546526148141366  …  -0.019811641136866287, 
-0.020780821058711863, -0.013588359417922776, -0.020438648396328824, -0.016169487825519843, 
-0.024031422484491572, -0.01884713946778991, -0.021163590874553318, -0.014607310062509895, 
-0.022449034332142046]
```
"""
function estimate_causal_effect!(R::RLearner)
    # Uses the same number of neurons for all phases of estimation
    if R.dml.num_neurons === 0
        R.dml.num_neurons = best_size(R.dml.X, R.dml.Y, R.dml.validation_metric, R.dml.task, 
            R.dml.activation, R.dml.min_neurons, R.dml.max_neurons, R.dml.regularized, 
            R.dml.folds, false, R.dml.iterations, R.dml.approximator_neurons)
    end

    # Just estimate the causal effect using the underlying DML and the weight trick
    R.causal_effect = estimate_effect!(R.dml, true)
    R.dml.quantity_of_interest = "CATE"

    return R.causal_effect
end

"""
stage1!(x)

Estimate the first stage models for an X-learner.

This method should not be called by the user.

```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = XLearner(X, Y, T)
julia> stage1!(m1)
```
"""
function stage1!(x::XLearner)
    if x.regularized
        g = RegularizedExtremeLearner(x.X, x.T, x.num_neurons, x.activation)
        x.μ₀ = RegularizedExtremeLearner(x.X[x.T .== 0,:], x.Y[x.T .== 0], x.num_neurons, 
            x.activation)
        x.μ₁ = RegularizedExtremeLearner(x.X[x.T .== 1,:], x.Y[x.T .== 1], x.num_neurons, 
            x.activation)
    else
        g = ExtremeLearner(x.X, x.T, x.num_neurons, x.activation)
        x.μ₀ = ExtremeLearner(x.X[x.T .== 0,:], x.Y[x.T .== 0], x.num_neurons, x.activation)
        x.μ₁ = ExtremeLearner(x.X[x.T .== 1,:], x.Y[x.T .== 1], x.num_neurons, x.activation)
    end

    # Get propensity scores
    fit!(g)
    x.ps = predict(g, x.X)

    # Fit first stage outcome models
    fit!(x.μ₀); fit!(x.μ₁)
end

"""
stage2!(x)

Estimate the second stage models for an X-learner.

This method should not be called by the user.

```julia-repl
julia> X, Y, T =  rand(100, 5), rand(100), [rand()<0.4 for i in 1:100]
julia> m1 = XLearner(X, Y, T)
julia> stage1!(m1)
julia> stage2!(m1)
([0.6579129842054047, 0.7644471766429705, 0.5462780002052421, 0.3532457241687176, 
0.5285202160177137, 0.6700637463326441, 0.7396669577462894, 0.19575273123932924, 
0.19090472359968091, 0.816401557016116  …  0.18732867917588836, 0.014605992930188605, 
0.8767780635957382, 0.7703598462892363, 0.304425208945448, 0.7424001864151887, 
0.300635582310234, 0.7559907369824916, 0.8221711606659099, 0.17192370608856988], 
[0.5428608390478198, 0.8612643542118226, 0.5107814429638895, 0.18978928137486417, 
0.3075968091812413, 0.32970316141529354, 0.9008627764809055, 0.8658168542711414, 
0.24633419551012337, 0.07459024070407072  …  0.5922447815994394, 0.1460543738442427, 
0.8790479230019441, 0.03356517743258902, 0.648803884856812, 0.09028229529599152, 
0.29810643643033863, 0.8755515354984005, 0.947588000142362, 0.29294343704001025])
```
"""
function stage2!(x::XLearner)
    d = ifelse(x.T === 0, predict(x.μ₁, x.X .- x.Y), x.Y .- predict(x.μ₀, x.X))

    if x.regularized
        μχ₀ = RegularizedExtremeLearner(x.X[x.T .== 0,:], d[x.T .== 0], x.num_neurons, 
            x.activation)
        μχ₁ = RegularizedExtremeLearner(x.X[x.T .== 1,:], d[x.T .== 1], x.num_neurons, 
            x.activation)
    else
        μχ₀ = ExtremeLearner(x.X[x.T .== 0,:], d[x.T .== 0], x.num_neurons, x.activation)
        μχ₁ = ExtremeLearner(x.X[x.T .== 1,:], d[x.T .== 1], x.num_neurons, x.activation) 
    end 

    fit!(μχ₀); fit!(μχ₁)

    return μχ₀, μχ₁
end
