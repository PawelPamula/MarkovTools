#!/usr/bin/env julia
push!(LOAD_PATH, ".")

using Analyses

function main()
	Analyses.runTest(2^16)
end

main()
