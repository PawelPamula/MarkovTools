#!/usr/bin/env julia
push!(LOAD_PATH, ".")

using Analyses

function main()
	Analyses.runTest(1024)
end

main()
