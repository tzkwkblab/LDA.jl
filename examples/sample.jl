using LDA


filename = "sample.txt"

max_topic_size = 20
num_iter = 400
num_inner_gibbs = 5


corpus = Corpus(filename)
model = OnlineHDPLDA(corpus, max_topic_size)
λ, u, v  = train(model, num_iter, num_inner_gibbs)

println()
sum_bar = 0.
for topic in 1:size(λ)[1]
    println()
    π = u[topic] /(u[topic] + v[topic])
    for k in 1:topic-1
        π *= (1. - (u[k] /(u[k] + v[k])))
    end

    sum_bar += π

    println(topic, " π=", π, " u[k]= ", u[topic], " v[k]= ", v[topic])
    phi = λ[topic, :]
    for word_id in sortperm(phi, rev=true)
       p = phi[word_id] / sum(phi)
       if p < 0.01
            break
        else
           print(get_word(corpus, word_id))
           @printf " %0.3f\n" p
        end
    end
end
