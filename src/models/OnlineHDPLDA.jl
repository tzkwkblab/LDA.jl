using Distributions

struct OnlineHDPLDA
    corpus::Corpus
    max_num_topic::Int # Max topic size
    V::Int # Num vocab
    D::Int # Num docs
    a::Float64 # DP param
    b::Float64 # DP param
    η::Float64 # Dirichle param
    start_τ::Float64 # Initialize value of learning rate 
    κ::Float64 # Power of learing rate formulation
    λ::Array{Float64, 2} # Params for HDP-LDA T x V

    function OnlineHDPLDA(corpus::Corpus, max_num_topic=300)
        @assert !corpus.is_row_document
        @assert max_num_topic >= 1
        V = corpus.V
        D = corpus.D
        a = b = 1.
        η = 0.01
        start_τ = 1.
        κ = 0.6
        
        # This initialization from Hoffmann's SVI paper
        _dist = Exponential(D*100/(max_num_topic*V))
        λ = rand(_dist, max_num_topic, V) + η

        new(corpus, max_num_topic, V, D, a, b, η, start_τ, κ, λ)
    end
end

function train(model::OnlineHDPLDA, iteration::Int=777, num_local_gibbs_samples::Int=1)
    S = 1
    @assert iteration >= 1
    @assert num_local_gibbs_samples >= 1
    println("#Iteration ", iteration)
    println("#Inner Gibbs loop ", num_local_gibbs_samples)

    function init_stirling(N::Int)
        stirling_cache = Dict{Tuple{Int, Int}, Int}()
        stirling_cache[0, 0] = 1
        for k in 1:N
            stirling_cache[k, k] = 1
            for n in k+1:N
                stirling_cache[n, k] = get(stirling_cache, (n-1, k-1), 0) + (n-1)*get(stirling_cache, (n-1, k), 0)
            end
        end

        return stirling_cache
    end

    function get_stirling!(stirling_cache, N::Int, K::Int)
        """
        if `stirling_cache` does not contain the pre-computed (N, K) term
            this function computes all until stirling(N, N)
        """

        if N == 0 & K == 0
            return 1
        end

        if K == 0
            return 0
        end

        if !haskey(stirling_cache, (N, K))
            begin_N = maximum(keys(stirling_cache))[1] + 1
            for k in 1:N
                stirling_cache[k, k] = 1
                for n in begin_N:N
                    stirling_cache[n, k] = get(stirling_cache, (n-1, k-1), 0 ) + (n-1)*get(stirling_cache, (n-1, k), 0)
                end
            end
        end
        
        return stirling_cache[N, K]
    end

    function update_rho(start_τ, t, κ)
        """
        TODO: define lower bound of rho_t like other algorithms
        """
        return (start_τ + t)^(-κ)
    end

    # Store model params into local variables
    max_num_topic = model.max_num_topic
    W = model.V
    D = model.D
    a = model.a
    b = model.b
    η = model.η
    λ = model.λ
    start_τ = model.start_τ
    κ = model.κ

    # init params
    stirling = init_stirling(10)
    u = ones(max_num_topic)
    v = ones(max_num_topic) 
    T = 2 # The current number of topics

    for iter in 1:iteration
        batches = []
        lengths = zeros(Int, S)
        ntk = zeros(Int, S, max_num_topic)
        nk = zeros(Int, max_num_topic)
        nkw = zeros(Int, max_num_topic, W)
        Z = []
        
        # Initialize random variable for MCMC
        ## Init topics in mini-batches
        for s in 1:S
            d = rand(1:D)
            document = get_document(model.corpus, d)
            push!(batches, document)
            lengths[s] = l = get_doc_length(model.corpus, d)
            zs = rand(1:T, l)
            push!(Z, zs)
            for (w, z) in zip(document, zs)
                ntk[s, z] += 1
                nk[z] += 1
                nkw[z, w] += 1
            end
        end

        π_ = zeros(max_num_topic) # parameter of stick breaking process
        π = zeros(max_num_topic) # array of stick lengths
        stk = zeros(Int, max_num_topic) # Init param for CRP

        # Gibbs sampling
        for _ in 1:num_local_gibbs_samples

            # Sampling π
            for k in 1:T
                π_[k] = rand(Beta(u[k] + stk[k], v[k] - a + 1 + sum(stk[k+1:T])))
                π[k] = π_[k]*prod(1.-π_[1:k-1])
            end

            # Sampling z
            for s in 1:S
                for (i, (w, z)) in enumerate(zip(batches[s], Z[s]))
                    ntk[s, z] -= 1
                    nk[z] -= 1
                    nkw[z, w] -= 1

                    cum_sum = zeros(T+1)
                    pre_cumsum_term = 0.
                    for k in 1:T
                        cum_sum[k] = pre_cumsum_term = pre_cumsum_term + (ntk[s, k] + b*π[k])*(nkw[k, w] + λ[k, w])/(nk[k] + sum(λ[k, :]))
                    end

                    # k = T + 1
                    cum_sum[T+1] = pre_cumsum_term = pre_cumsum_term + b*(1.-sum(π[1:T]))/W

                    z = searchsortedfirst(cum_sum, rand()*pre_cumsum_term)
                    Z[s][i] = z
                    
                    if z == T + 1
                        T += 1
                    end
                    ntk[s, z] += 1
                    nk[z] += 1
                    nkw[z, w] += 1
                end
            end
            
            # Sampling S
            t = 1
            bπ = b*π
            Γ_bπ = gamma.(bπ)
            first_term = bπ ./ gamma.(bπ + ntk[t, :]) # TODO mini-batches

            for k in 1:T
                _ntk = ntk[t, k]

                if _ntk == 0
                    stk[k] = 0
                    continue
                end

                cumsum_stk_dist = zeros(_ntk)
                pre_cumsum_term = 0.
                for s in 1:_ntk
                    # how to sample from it?
                    cumsum_stk_dist[s] = pre_cumsum_term = pre_cumsum_term + first_term[k] * get_stirling!(stirling, _ntk, s) * (bπ[k]^s)
                end
                stk[k] = searchsortedfirst(cumsum_stk_dist, rand()*pre_cumsum_term)
            end
        end

        # Update global params
        lr = update_rho(start_τ, iter, κ)
        print("\rprocess ", iter/iteration, " ρ: ", lr)

        λ[1:T, :] += lr * (-λ[1:T, :] + η + D/S*nkw[1:T, :])
        u[1:T] += lr * (-u[1:T] + 1. + D/S*stk[1:T])
        for k in 1:T
            v[k] += lr * (-v[k] + a + D/S * sum(stk[k+1:end]))
        end
    end

    println("\nT is ", T)
    return λ[1:T, :], u[1:T], v[1:T]
end
