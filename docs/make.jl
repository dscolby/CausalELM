using CausalELM
using Documenter

DocMeta.setdocmeta!(CausalELM, :DocTestSetup, :(using CausalELM); recursive=true)

makedocs(;
    modules=[CausalELM],
    authors="Darren Colby <dscolby17@gmail.com> and contributors",
    repo="https://github.com/dscolby/CausalELM.jl/blob/{commit}{path}#{line}",
    sitename="CausalELM.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://dscolby.github.io/CausalELM.jl",
        edit_link="main",
        assets=String["docs/build/assets/themes/indigo.css"],
    ),
    pages=[
        "CausalELM" => "index.md",
        "Examples" => "examples.md",
        "API" => Any[
            "CausalELM" => "API/api.md",
            "Activation Functions" => "API/activations.md",
            "Cross Validation" => "API/crossval.md",
            "ATE/ATT/ITT Estimation" => "API/average.md",
            "CATE Estimation" => "API/cate.md",
            "Inference and Summarization" => "API/inference.md",
            "Validation Metrics" => "API/metrics.md",
            "Base Models" => "API/base.md"
        ],
        "Contributing" => Any[
            "contributing/contributing.md",
            "contributing/bug.md",
            "contributing/features.md", 
            "contributing/code.md"
        ]
    ],
)

deploydocs(;
    repo="github.com/dscolby/CausalELM.jl",
    devbranch="main",
)
