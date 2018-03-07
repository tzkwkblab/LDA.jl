module LDA

export Dictionary, get_word, get_word_index, update_and_get!, update!, get_num_vocab
export Corpus, get_document, get_word, get_doc_length
export OnlineHDPLDA, train

include("Utils.jl")
include("Models.jl")

end
