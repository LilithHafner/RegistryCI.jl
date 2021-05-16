function is_jll_name(name::AbstractString)::Bool
    return endswith(name, "_jll")
end

function _get_all_dependencies_nonrecursive(working_directory::AbstractString,
                                            pkg,
                                            version)
    all_dependencies = String[]
    deps = Pkg.TOML.parsefile(joinpath(working_directory, uppercase(pkg[1:1]), pkg, "Deps.toml"))
    for version_range in keys(deps)
        if version in Pkg.Types.VersionRange(version_range)
            for name in keys(deps[version_range])
                push!(all_dependencies, name)
            end
        end
    end
    unique!(all_dependencies)
    return all_dependencies
end

const guideline_allowed_jll_nonrecursive_dependencies = Guideline(;
    info = "If this is a JLL package, only deps are Pkg, Libdl, and other JLL packages",
    docs = """
    If this is a JLL package, only deps are Pkg, Libdl, and other JLL packages
    """,
    include_in_docs = false,
    check = data -> meets_allowed_jll_nonrecursive_dependencies(
        data.registry_head,
        data.pkg,
        data.version,
    ),
)


function meets_allowed_jll_nonrecursive_dependencies(working_directory::AbstractString,
                                                     pkg,
                                                     version)
    # If you are a JLL package, you are only allowed to have five kinds of dependencies:
    # 1. Pkg
    # 2. Libdl
    # 3. Artifacts
    # 4. JLLWrappers
    # 5. LazyArtifacts
    # 6. other JLL packages
    all_dependencies = _get_all_dependencies_nonrecursive(working_directory,
                                                          pkg,
                                                          version)
    allowed_dependencies = ("Pkg", "Libdl", "Artifacts", "JLLWrappers", "LazyArtifacts")
    for dep in all_dependencies
        if dep ∉ allowed_dependencies && !is_jll_name(dep)
            return false, "JLL packages are only allowed to depend on $(join(allowed_dependencies, ", ")) and other JLL packages"
        end
    end
    return true, ""
end
