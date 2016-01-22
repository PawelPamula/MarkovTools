#!/usr/bin/env julia
push!(LOAD_PATH, ".")

using Analyses

function main()
	Analyses.runTest(16384)
end

main()
