#!/usr/bin/env julia
push!(LOAD_PATH, ".")

uniform(a,b) = a + rand() * (b-a)
function gaussian(s,m,g)
	x = randn()
	r = (x * s) + m
	return r < g ? g : r > 1-g ? 1-g : r
end

limit = 300

range = 1:(limit-1)

import Analyses

#ps = [uniform(0.1, 0.9) for _ in range]
ps = [gaussian(0.05, 0.5, 0.1) for _ in range]

for r in range
	p = ps[r]
	q = 1 - p
	
	pf(i, N) = ps[i]
	qf(i, N) = 1 - ps[i]
	
	s = q/p
	
	rho = float(Analyses.EstimateResultsGambler1D(r, limit, pf, qf))
	print("$r, $p, $q, $s, $rho\n")
end
