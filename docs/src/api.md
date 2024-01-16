# causalELM
Most of the methods and structs here are private, not exported, should not be called by the 
user, and are documented for the purpose of developing CausalELM or to facilitate 
understanding of the implementation.

## Types
```@docs
InterruptedTimeSeries
GComputation
DoubleMachineLearning
SLearner
TLearner
RLearner
CausalELM.CausalEstimator
CausalELM.Metalearner
CausalELM.ExtremeLearningMachine
CausalELM.ExtremeLearner
CausalELM.RegularizedExtremeLearner
CausalELM.Nonbinary
CausalELM.Binary
CausalELM.Count
CausalELM.Continuous
```

## Activation Functions
```@docs
binary_step
σ
tanh
relu
leaky_relu
swish
softmax
softplus
gelu
gaussian
hard_tanh
elish
fourier
```

## Cross Validation
```@docs
CausalELM.generate_folds
CausalELM.generate_temporal_folds
CausalELM.validation_loss
CausalELM.cross_validate
CausalELM.best_size
CausalELM.shuffle_data
```

## Average Causal Effect Estimators
```@docs
XLearner
CausalELM.estimate_effect!
CausalELM.predict_residuals
CausalELM.moving_average
```

## Metalearners
```@docs
CausalELM.stage1!
CausalELM.stage2!
```

## Common Methods
```@docs
estimate_causal_effect!
```

## Inference
```@docs
summarize
CausalELM.generate_null_distribution
CausalELM.quantities_of_interest
```

## Model Validation
```@docs
validate
CausalELM.covariate_independence
CausalELM.omitted_predictor
CausalELM.sup_wald
CausalELM.p_val
CausalELM.counterfactual_consistency
CausalELM.exchangeability
CausalELM.e_value
CausalELM.binarize
CausalELM.risk_ratio
CausalELM.positivity
CausalELM.sums_of_squares
CausalELM.class_pointers
CausalELM.backtrack_to_find_breaks
CausalELM.variance
CausalELM.best_splits
CausalELM.group_by_class
CausalELM.jenks_breaks
CausalELM.fake_treatments
CausalELM.sdam
CausalELM.scdm
CausalELM.gvf
CausalELM.var_type
```

## Validation Metrics
```@docs
mse
mae
accuracy
precision
recall
F1
CausalELM.confusion_matrix
```

## Extreme Learning Machines
```@docs
CausalELM.fit!
CausalELM.predict
CausalELM.predict_counterfactual!
CausalELM.placebo_test
CausalELM.ridge_constant
CausalELM.set_weights_biases
```

## Utility Functions
```@docs
CausalELM.mean
CausalELM.var
CausalELM.consecutive
CausalELM.one_hot_encode
```