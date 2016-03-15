#!/usr/bin/env julia
push!(LOAD_PATH, ".")

using Analyses

function main()
	Analyses.runTest(256)
end

main()
