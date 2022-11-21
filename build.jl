#! /usr/bin/env -S julia --project=.

import Literate
import Tar
import TOML

# Delete and recreate build folder
build_folder = joinpath(pwd(), "build")
@info "Creating empty build folder `$build_folder`."
rm(build_folder, force=true, recursive=true)
mkpath(build_folder)

# Read metadata
metadata_file_path = joinpath(pwd(), "metadata.toml")
@info "Reading metadata file `$metadata_file_path`."
metadata = TOML.parsefile(metadata_file_path)
slug = metadata["slug"]
title = metadata["title"]

# Build markdown document
input_jl_file_path = joinpath(pwd(), "src", slug * ".jl")
@info "Building `$input_jl_file_path`."
Literate.markdown(
    input_jl_file_path,
    build_folder;
    documenter=false,
    execute=true,
    # Fix auto-formatted hide comments
    preprocess=s -> replace(s, "# hide\n" => "#hide\n"),
    # Insert title
    postprocess=s -> "---\ntitle: $title\n---\n\n$s"
)

# Copy metadata file to build build folder
@info "Copying metadata file `$metadata_file_path` to build folder."
cp(metadata_file_path, joinpath(build_folder, "metadata.toml"); force=true)

# Create tarball
tarball_file_path = joinpath(pwd(), slug * ".tar")
@info "Creating tarball file at `$tarball_file_path`."
Tar.create(build_folder, tarball_file_path)
