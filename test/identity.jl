# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

# Package identity checks — the Julia-side twin of tests/check-identity.sh.
#
# Two independent implementations of one rule, reading the same files: the shell
# checker runs in the proof gate, this one runs inside the Julia CI matrix, where
# the package is actually loaded. They agree, or one of them is wrong, and a
# disagreement is a failure in whichever job runs it.
#
# What is checked here:
#
#   * the name in Project.toml equals the name of the module that got loaded,
#     which equals the filename it lives in, which equals what the tests import;
#   * that name is a legal Julia identifier;
#   * the repository name is the package name with ".jl" appended, when the
#     repository name is observable at all;
#   * the README's julia snippet is byte-identical to examples/quickstart.jl,
#     and that file actually runs and returns the generator's completion message.
#
# The last one is the point of the exercise: a documented snippet that is never
# executed is a claim, and claims rot. This makes the documentation a test
# fixture. See issue #68.

const IDENTITY_ROOT = normpath(joinpath(@__DIR__, ".."))

"""
    identity_declared_name(root) -> String

The `name` declared at the top level of `root/Project.toml`, i.e. before the
first table header. Errors rather than guessing when it is absent.
"""
function identity_declared_name(root::AbstractString)::String
    toml = joinpath(root, "Project.toml")
    isfile(toml) || error("identity: $toml is missing")
    for line in eachline(toml)
        if startswith(lstrip(line), "[")
            break
        end
        m = match(r"^\s*name\s*=\s*\"([^\"]+)\"", line)
        m === nothing && continue
        cap = m.captures[1]
        cap === nothing && continue
        return String(cap)
    end
    return error("identity: no top-level name = \"...\" in $toml")
end

"""
    identity_readme_julia_block(path) -> String

The body of the first `[source,julia]` block in an AsciiDoc file, without the
`----` fences. Empty when there is no such block.
"""
function identity_readme_julia_block(path::AbstractString)::String
    out = String[]
    pending = false
    infence = false
    for line in eachline(path)
        if infence
            if occursin(r"^----+\s*$", line)
                break
            end
            push!(out, line)
        elseif pending
            if occursin(r"^----+\s*$", line)
                pending = false
                infence = true
            end
        elseif occursin(r"^\[source,julia\]\s*$", line)
            pending = true
        end
    end
    return join(out, "\n")
end

"""
    identity_example_body(path) -> String

The example file with its leading comment and blank lines removed — exactly what
the README is required to reproduce.
"""
function identity_example_body(path::AbstractString)::String
    lines = readlines(path)
    i = 1
    while i <= length(lines) && (startswith(lines[i], "#") || isempty(strip(lines[i])))
        i += 1
    end
    return join(lines[i:end], "\n")
end

@testset "Package identity" begin
    root = IDENTITY_ROOT
    declared = identity_declared_name(root)
    loaded = string(nameof(JuliaPackageSpitter))

    @testset "one package, one name" begin
        @test declared == loaded
        @test occursin(r"^[A-Za-z_][A-Za-z0-9_!]*$", loaded)

        src_path = joinpath(root, "src", "$loaded.jl")
        @test isfile(src_path)
        if isfile(src_path)
            src_text = read(src_path, String)
            @test occursin(Regex("^module\\s+$loaded\\s*\$", "m"), src_text)
        end

        runtests_path = joinpath(root, "test", "runtests.jl")
        @test isfile(runtests_path)
        if isfile(runtests_path)
            @test occursin(
                Regex("^using\\s+$loaded\\s*\$", "m"),
                read(runtests_path, String),
            )
        end
    end

    @testset "repository name is the package name plus .jl" begin
        nwo = split(strip(get(ENV, "GITHUB_REPOSITORY", "")), '/'; keepempty = false)
        if isempty(nwo)
            @test_skip "GITHUB_REPOSITORY is not set, so the repository name is not observable from here; the Agda gate checks it in CI (proofs/agda, tests/check-identity.sh)"
        elseif length(nwo) != 2
            @test_skip "GITHUB_REPOSITORY=$(join(nwo, "/")) is not owner/name; cannot check the repository name"
        elseif nwo[1] != "hyperpolymath"
            @test_skip "this is a fork ($(nwo[1])); the naming rule is enforced upstream, where the repository name is the canonical one"
        else
            @test String(nwo[2]) == "$loaded.jl"
        end
    end

    @testset "documented quick start is the example that runs" begin
        readme_path = joinpath(root, "README.adoc")
        example_path = joinpath(root, "examples", "quickstart.jl")
        @test isfile(readme_path)
        @test isfile(example_path)

        if isfile(readme_path) && isfile(example_path)
            block = identity_readme_julia_block(readme_path)
            body = identity_example_body(example_path)
            @test !isempty(block)
            @test !isempty(body)
            if block != body
                # Show the drift rather than only reporting it: the whole point
                # is that a reviewer can see which side moved.
                @info "README.adoc [source,julia] block:\n$block"
                @info "examples/quickstart.jl body:\n$body"
            end
            @test block == body

            message = Base.include(Module(:QuickstartSandbox), example_path)
            @test message isa String
            if message isa String
                @test occursin("scaffolded successfully", message)
            end
        end
    end
end
