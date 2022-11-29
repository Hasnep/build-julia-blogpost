module BuildJuliaBlogpost

import FileWatching
import Literate
import Tar
import TOML

get_build_folder() = joinpath(pwd(), "build")
get_metadata_file_path() = joinpath(pwd(), "metadata.toml")
get_src_folder() = joinpath(pwd(), "src")
get_blogpost_file_path(blogpost_id) = joinpath(get_src_folder(), "$blogpost_id.jl")
get_tarball_file_path(blogpost_id) = joinpath(pwd(), "$blogpost_id.tar")

function delete_and_recreate_build_folder(build_folder)
    @info "Creating empty build folder `$build_folder`."
    rm(build_folder, force=true, recursive=true)
    mkpath(build_folder)
end

function get_blogpost_id(metadata_file_path)
    @info "Reading metadata file `$metadata_file_path`."
    metadata = TOML.parsefile(metadata_file_path)
    return metadata["id"]
end

function build_blogpost_to_markdown(blogpost_file_path, build_folder)
    @info "Building `$blogpost_file_path`."
    return Literate.markdown(
        blogpost_file_path,
        build_folder;
        execute=true,
        flavor=Literate.CommonMarkFlavor(),
        # Fix auto-formatted hide comments
        preprocess=s -> replace(s, "# hide\n" => "#hide\n")
    )
end

function copy_metadata_file_to_build_folder(metadata_file_path, build_folder)
    @info "Copying metadata file `$metadata_file_path` to build folder `$build_folder`."
    return cp(metadata_file_path, joinpath(build_folder, "metadata.toml"); force=true)
end

function build_markdown_to_html(from_md_file_path, to_html_file_path)
    @info "Building markdown file `$from_md_file_path` to HTML file at `$to_html_file_path`."
    pandoc_command = Cmd([
        "pandoc",
        from_md_file_path,
        "--from=commonmark",
        "--to=html",
        "--standalone",
        "--output=" * to_html_file_path,
    ])
    run(pandoc_command)
    return nothing
end

function create_tarball_file(build_folder, tarball_file_path)
    @info "Creating tarball file at `$tarball_file_path`."
    Tar.create(build_folder, tarball_file_path)
end

function build(; run_pandoc, create_tarball)
    build_folder = get_build_folder()
    delete_and_recreate_build_folder(build_folder)

    metadata_file_path = get_metadata_file_path()
    blogpost_id = get_blogpost_id(metadata_file_path)

    blogpost_file_path = get_blogpost_file_path(blogpost_id)
    built_md_file_path = build_blogpost_to_markdown(blogpost_file_path, build_folder)
    copy_metadata_file_to_build_folder(metadata_file_path, build_folder)

    if run_pandoc
        built_html_file_path = joinpath(build_folder, "$blogpost_id.html")
        build_markdown_to_html(built_md_file_path, built_html_file_path)
    end

    if create_tarball
        tarball_file_path = get_tarball_file_path(blogpost_id)
        create_tarball_file(build_folder, tarball_file_path)
    end
end

function watch(; run_pandoc, create_tarball)
    src_folder = get_src_folder()
    while true
        @info "Watching `$src_folder`."
        file_path, output = FileWatching.watch_folder(src_folder)
        if output.changed
            @info "Updated `$file_path`, rebuilding."
            try
                build(; run_pandoc, create_tarball)
            catch err
                @error err
            end
        end
    end
end

end # module
