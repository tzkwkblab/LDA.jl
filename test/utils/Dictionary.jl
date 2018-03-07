dictionary = Dictionary()
update!(dictionary, "1")
update!(dictionary, "2")
update!(dictionary, "3")

@testset "Basic function test" begin
    @test get_word(dictionary, 1) == "1"
    @test get_word(dictionary, 2) == "2"
    @test get_word(dictionary, 3) == "3"

    @test get_word_index(dictionary, "1") == 1
    @test get_word_index(dictionary, "nothing") == nothing

    @test update_and_get!(dictionary, "4") == 4
    @test update_and_get!(dictionary, "1") == 1
    
    @test get_num_vocab(dictionary) == 4
end
