using Test
import BuildJuliaBlogpost

@testset "BuildJuliaBlogpost" begin
    # Set up test blogpost
    workspace_folder = mktempdir()
    mkdir(joinpath(workspace_folder, "src"))
    write(
        joinpath(workspace_folder, "src", "test-blogpost.jl"),
        """
        # Test blogpost

        x = 10
        """,
    )
    write(joinpath(workspace_folder, "metadata.toml"), "id = \"test-blogpost\"")

    # Build the blogpost
    BuildJuliaBlogpost.build(workspace_folder; run_pandoc=false, create_tarball=true)

    # Check the output markdown file was built
    output_md_file_path = joinpath(workspace_folder, "build", "test-blogpost.md")
    @test isfile(output_md_file_path)

    # Check the output markdown file contains what we expect
    output_md = open(io -> read(io, String), output_md_file_path)
    expected_output = ("""
                       Test blogpost

                       ````julia
                       x = 10
                       ````

                       ````
                       10
                       ````
                       """)
    @test strip(output_md) == strip(expected_output)

    # Test that the tar file was created
    output_tar_file_path = joinpath(workspace_folder, "blogpost.tar")
    @test isfile(output_tar_file_path)
end
