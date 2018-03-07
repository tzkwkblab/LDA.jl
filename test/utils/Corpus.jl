# create dummy data
content = """
7 7 7 7 7 7 7
6 6 6 6 6 6 7
5 5 5 5 5 7
4 4 4 4 7
3 3 3 7
2 2 7
1 7
7

"""

fname = "tmp.txt"
open(fname, "w") do f
   write(f, content)
end

function test_set(corpus::Corpus)
    @test corpus.D == 8
    @test corpus.V == 7
    @test get_word(corpus, 1) == "7"
    @test get_word(corpus, 7) == "1"
    @test get_doc_length(corpus, 1) == 7
    @test get_document(corpus, 1) == ones(Int, 7)
    document = ones(Int, 7) * 2
    document[1] = 1
    @test get_document(corpus, 2) == document
    @test get_document(corpus, 8) == ones(Int, 1)
end

@testset "Row document test" begin
    corpus = Corpus(fname, false)
    test_set(corpus)
end

@testset "Column document test" begin
    corpus = Corpus(fname, true)
    test_set(corpus)
end

rm("tmp.txt")
