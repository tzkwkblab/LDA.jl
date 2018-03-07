struct Dictionary
    word2index::Dict{String, Int}
    index2word::Array{String, 1}

    function Dictionary()
        new(Dict{String, Int}(), String[])
    end    
end

function get_word(dic::Dictionary, word_id::Int)
    @assert 0 < word_id <= length(dic.index2word)
    dic.index2word[word_id]
end

function get_word_index(dic::Dictionary, word)
    get(dic.word2index, word, nothing)
end

function update!(dic::Dictionary, word)
    word_id = get(dic.word2index, word, length(dic.word2index) + 1)
    if length(dic.word2index) < word_id
        dic.word2index[word] = word_id
        push!(dic.index2word, word)
    end
end

function update_and_get!(dic::Dictionary, word)
    word_id = get(dic.word2index, word, length(dic.word2index) + 1)
    if length(dic.word2index) < word_id
        dic.word2index[word] = word_id
        push!(dic.index2word, word)
    end
    word_id
end

function get_num_vocab(dic::Dictionary)
    length(dic.index2word)
end
