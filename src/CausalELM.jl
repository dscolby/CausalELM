"""
Macros, functions, and structs for applying Extreme Learning Machines to causal inference
tasks where the counterfactual is unavailable or biased and must be predicted. Provides 
macros for event study designs, parametric G-computation, doubly robust estimation, and 
metalearners. Additionally, these tasks can be performed with or without L2 penalization and
will automatically choose the best number of neurons and L2 penalty. 

For more details on Extreme Learning Machines see:
    Huang, Guang-Bin, Qin-Yu Zhu, and Chee-Kheong Siew. "Extreme learning machine: theory 
    and applications." Neurocomputing 70, no. 1-3 (2006): 489-501.
"""
module CausalELM

export InterruptedTimeSeries, 
       GComputation, 
       DoublyRobust, 
       SLearner, 
       TLearner, 
       XLearner,
       estimatecausaleffect!, 
       summarize

function estimatecausaleffect!() end

function summarize() end

mean(x::Vector{<:Real}) = sum(x)/length(x)

function var(x::Vector{<:Real})
    x̄, n = mean(x), length(x)

    return sum((x .- x̄).^2)/(n-1)
end

const summarise = summarize

# Helpers to subtract consecutive elements in a vector
consecutive(v::Vector{<:Real}; f::String="minus") = [-(v[i+1], v[i]) for i = 1:length(v)-1]

include("activation.jl")
include("models.jl")
include("metrics.jl")
include("crossval.jl")
include("estimators.jl")
include("metalearners.jl")
include("inference.jl")
include("model_validation.jl")

end
