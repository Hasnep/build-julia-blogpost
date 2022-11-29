using Test
import BuildJuliaBlogpost

@testset "BuildJuliaBlogpost" begin
    BuildJuliaBlogpost.build(; run_pandoc=true, create_tarball=true)
    output_html_file_path = joinpath(pwd(), "build", "test-blogpost.html")
    @test isfile(output_html_file_path)
    output_html = open(io -> read(io, String), output_html_file_path)
    @test occursin("<p>Test blogpost</p>", output_html)
    output_tar_file_path = joinpath(pwd(), "test-blogpost.tar")
    @test isfile(output_tar_file_path)
end
