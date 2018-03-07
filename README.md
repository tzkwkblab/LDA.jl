# LDA.jl

## Implementation

- `onlineHDPLDA` : HDPLDA with  truncation-free online variational inference. [Chong Wang and David M. Blei. Truncation-free Online Variational Inference for Bayesian Nonparametric Models, In NIPS, 2014.](https://papers.nips.cc/paper/4534-truncation-free-online-variational-inference-for-bayesian-nonparametric-models.pdf)

## Environment

- Julia: >= 0.6
- `Distributions` (Please type `Pkg.add("Distributions")` in julia console)

## Usage

### Install

```
julia> Pkg.clone("git@github.com:wkblab/OnlineHDPLDA.jl.git")
```

```julia
cd example
julia sample.jl
```
