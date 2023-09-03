using CausalELM.Models: ExtremeLearner, RegularizedExtremeLearner, fit!, predict,
    predictcounterfactual!, placebotest
using CausalELM.ActivationFunctions: σ
using Test

# Test classification functionality using a simple XOR test borrowed from 
# ExtremeLearning.jl
x = [1.0 1.0; 0.0 1.0; 0.0 0.0; 1.0 0.0]
y = [0.0, 1.0, 0.0, 1.0]
x_test = [1.0 1.0; 0.0 1.0; 0.0 0.0]

x1 = rand(20, 5)
y1 = rand(20)
x1test = rand(30, 5)

m1 = ExtremeLearner(x, y, 10, σ)
f1 = fit!(m1)
predictions1 = predict(m1, x_test)
predictcounterfactual!(m1, x_test)
placebo1 = placebotest(m1)

m2 = RegularizedExtremeLearner(x, y, 10, σ)
f2 = fit!(m2)
predictions2 = predict(m2, x_test)
predictcounterfactual!(m2, x_test)
placebo2 = placebotest(m2)

m3 = ExtremeLearner(x1, y1, 10, σ)
fit!(m3)
predictions3 = predict(m3, x1test)

m4 = RegularizedExtremeLearner(x1, y1, 10, σ)
fit!(m4)
predictions4 = predict(m4, x1test)

nofit = ExtremeLearner(x1, y1, 10, σ)

 @testset "Model Fit" begin
    @test length(m1.β) == 10
    @test size(m1.weights) == (2, 10)
 end

 @testset "Model Predictions" begin
    @test predictions1[1] < 0.1
    @test predictions1[2] > 0.9
    @test predictions1[3] < 0.1

    # Regularized case
    @test predictions1[1] < 0.1
    @test predictions1[2] > 0.9
    @test predictions1[3] < 0.1

    # Ensure the counterfactual attribute gets step
    @test m1.counterfactual == predictions1
    @test m2.counterfactual == predictions2

    # Ensure we can predict with a test set with more data points than the training set
    @test isa(predictions3, Array{Float64})
    @test isa(predictions4, Array{Float64})
 end

 @testset "Placebo Test" begin
    @test length(placebo1) == 2
    @test length(placebo2) == 2
 end

 @testset "Predict Before Fit" begin
    @test_throws ErrorException predict(nofit, x1test)
    @test_throws ErrorException placebotest(nofit)
 end


 @testset "Print Models" begin
    msg1, msg2 = "Extreme Learning Machine with ", "hidden neurons"
    msg3 = "Regularized " * msg1
    @test sprint(print, m1) === msg1 * string(m1.hidden_neurons) * " " * msg2
    @test sprint(print, m2) === msg3 * string(m2.hidden_neurons) * " " * msg2
 end