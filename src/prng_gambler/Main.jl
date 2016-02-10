#!/usr/bin/env julia
push!(LOAD_PATH, ".")

using Analyses

function main()
	Analyses.runTest(4096)
end

main()
