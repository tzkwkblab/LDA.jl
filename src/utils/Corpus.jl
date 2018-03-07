struct Corpus
    docs::SparseMatrixCSC{Int,Int}
    doc_lengths::Array{Int, 1}
    D::Int
    V::Int
    dictionary::Dictionary
    is_row_document::Bool

    function Corpus(path::String, is_row_document::Bool=false)
        dictionary = Dictionary()
        doc_lengths = Int[]

        # arguments for initialize csc matrix
        doc_ids = Int[]
        word_ids = Int[]
        data = Int[]

        open(path) do f
            for (doc_id, doc) in enumerate(readlines(f))
                doc_len = 0
                # key: wordid, value: frequency
                word_freq_in_doc = Dict{Int, Int}()
                for word in split(doc)
                    word_id = update_and_get!(dictionary, word)
                    word_freq_in_doc[word_id] = get(word_freq_in_doc, word_id, 0) + 1
                    doc_len += 1
                end
                push!(doc_lengths, doc_len)

                for (word_id, freq) in word_freq_in_doc
                    push!(doc_ids, doc_id)
                    push!(word_ids, word_id)
                    push!(data, freq)
                end
            end
        end

        if is_row_document
            docs = sparse(doc_ids, word_ids, data)
            D, V = size(docs)
        else
            docs = sparse(word_ids, doc_ids, data)
            V, D = size(docs)
        end
        new(docs, doc_lengths, D, V, dictionary, is_row_document)
    end
end

function get_document(corpus::Corpus, doc_id::Int)
    @assert 1 <= doc_id <= corpus.D

    result = Int[]

    if !corpus.is_row_document
        for j in nzrange(corpus.docs, doc_id)
            word_id = rowvals(corpus.docs)[j]
            for _ in 1:nonzeros(corpus.docs)[j]
                push!(result, word_id)
            end
        end
    else
        word_ids, freq = findnz(corpus.docs[doc_id, :])
        for (index, word_id) in enumerate(word_ids)
            for _ in 1:freq[index]
                push!(result, word_id)
            end
        end
    end
    result
end

function get_word(corpus::Corpus, word_id::Int)
    @assert 1 <= word_id <= corpus.V
    get_word(corpus.dictionary, word_id)
end

function get_doc_length(corpus::Corpus, doc_id::Int)
    @assert 1 <= doc_id <= corpus.D
    corpus.doc_lengths[doc_id]
end
