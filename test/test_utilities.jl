using Test

include("../src/utilities.jl")

struct Binary end
struct Count end

# Variables for checking the output of the model_config macro because it is difficult
model_config_avg_expr = @macroexpand @model_config average_effect
model_config_ind_expr = @macroexpand @model_config individual_effect
model_config_avg_idx = Int64.(collect(range(2, 26, 13)))
model_config_ind_idx = Int64.(collect(range(2, 26, 13)))
model_config_avg_ground_truth = quote
    quantity_of_interest::String
    temporal::Bool
    task::String
    regularized::Bool
    activation::Function
    validation_metric::Function
    min_neurons::Int64
    max_neurons::Int64
    folds::Int64
    iterations::Int64
    approximator_neurons::Int64
    num_neurons::Int64
    causal_effect::Float64
end

model_config_ind_ground_truth = quote
    quantity_of_interest::String
    temporal::Bool
    task::String
    regularized::Bool
    activation::Function
    validation_metric::Function
    min_neurons::Int64
    max_neurons::Int64
    folds::Int64
    iterations::Int64
    approximator_neurons::Int64
    num_neurons::Int64
    causal_effect::Array{Float64}
end

# Fields for the user supplied data
standard_input_expr = @macroexpand @standard_input_data
standard_input_idx = [2, 4, 6]
standard_input_ground_truth = quote
    X::Array{Float64}
    T::Array{Float64}
    Y::Array{Float64}
end

# Fields for the user supplied data
double_model_input_expr = @macroexpand @standard_input_data
double_model_input_idx = [2, 4, 6]
double_model_input_ground_truth = quote
    X::Array{Float64}
    T::Array{Float64}
    Y::Array{Float64}
    W::Array{Float64}
end

@testset "Moments" begin
    @test mean([1, 2, 3]) == 2
    @test var([1, 2, 3]) == 1
end

@testset "One Hot Encoding" begin
    @test one_hot_encode([1, 2, 3]) == [1 0 0; 0 1 0; 0 0 1]
end

@testset "Clipping" begin
    @test clip_if_binary([1.2, -0.02], Binary()) == [0.9999999, 1.0e-7]
    @test clip_if_binary([1.2, -0.02], Count()) == [1.2, -0.02]
end

@testset "Generating Fields with Macros" begin
    @test model_config_avg_ground_truth.head == model_config_avg_expr.head
    @test model_config_ind_ground_truth.head == model_config_ind_expr.head

    # We only look at even indices because the odd indices have information about what linear
    # of VSCode each variable was defined in, which will differ in both expressions
    @test (
        model_config_avg_ground_truth.args[model_config_avg_idx] ==
        model_config_avg_ground_truth.args[model_config_avg_idx]
    )

    @test (
        model_config_ind_ground_truth.args[model_config_avg_idx] ==
        model_config_ind_ground_truth.args[model_config_avg_idx]
    )

    @test_throws ArgumentError @macroexpand @model_config mean

    @test standard_input_expr.head == standard_input_ground_truth.head

    @test (
        standard_input_expr.args[standard_input_idx] ==
        standard_input_ground_truth.args[standard_input_idx]
    )

    @test double_model_input_expr.head == double_model_input_ground_truth.head

    @test (
        double_model_input_expr.args[double_model_input_idx] ==
        double_model_input_ground_truth.args[double_model_input_idx]
    )
end
