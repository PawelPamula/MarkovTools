#!/usr/bin/env julia
push!(LOAD_PATH, ".")

using Analyses
using Gambler
using RandSources

# Global/ENV tweak
ADD_BASE = "GAMBLER_0001"
if !haskey(ENV, "ADD_BASE")
	@everywhere ENV["ADD_BASE"] = "GAMBLER_0001"
else
	@everywhere ADD_BASE = ENV["ADD_BASE"]
end

#macro out_est(x) :(begin __x = $x; run(`bash -c 'echo "$__x" >> estimated.csv'`) end) end
#macro out_gam(x) :(begin __x = $x; run(`bash -c 'echo "$__x" >> fullreport.csv'`) end) end

#macro out_est(x) :(open("estimated.csv",  "a") do f __x = $x; write(f, __x) end) end
#macro out_gam(x) :(open("fullreport.csv", "a") do f __x = $x; write(f, __x) end) end

macro out_est(x) :(write(__out_est, $x)) end
macro out_gam(x) :(write(__out_gam, $x)) end

# first entry point, tweak tested p/q pairs here
function step_one()
	#delta - deviation from 0.5 for the upcoming tests:
	delta = 1//128

	# test: (atan(N/2 - i) / 32pi) + 0.5 (values range between 31/64 and 33/64)
	p(i::Int64, N::Int64) = (atan(N/2 - i) / pi)*delta + 0.5
	q(i::Int64, N::Int64) = 0.5 - (atan(N/2 - i) / pi)*delta

	pd = "atan(..)"
	qd = "atan(..)"
	step_two(p, pd, q, qd)

	# new test: (sin((i / N) * 2pi) / delta + 0.5)
	p(i::Int64, N::Int64) = 0.5 + (sin((i / N) * 2pi) * delta)
	q(i::Int64, N::Int64) = 0.5 - (sin((i / N) * 2pi) * delta)

	pd = "sin(..)"
	qd = "sin(..)"
	step_two(p, pd, q, qd)
end

# second entry point, tweak start/end points here.
function step_two(p, pd, q, qd)
	N = 512
	i = round(Int,1N//2)

	step_three(i, N, p, pd, q, qd)
end

# third entry point, tweak simulation modes (BitTracker, BitSlicer, etc) here
function step_three(i, N, p, pd, q, qd)
	est = Analyses.EstimateResultsGambler1D(i, N, p, q)

	@out_est("$i;$N;$pd;$qd;$est\n");

	step_four(i, N, p, pd, q, qd, BitTracker, "BitTracker    ")
end

# fourth entry point, tweak randomness sources here (e.g. RNGs under tests)
function step_four(i, N, p, pd, q, qd, sim, simd)
	step_five(i, N, p, pd, q, qd, sim, simd, "RANDU CMD       ", "randu",       Analyses.bsFromCmd)
	step_five(i, N, p, pd, q, qd, sim, simd, "RANDU LCG       ", "",            RandSources.bsFromRandU)
end

# fifth entry point, tweak number of runs per starting point here
function step_five(i, N, p, pd, q, qd, sim, simd, bsd, bs_arg, bs_func)
	runs = 64

	step_six(i, N, p, pd, q, qd, sim, simd, bsd, bs_arg, bs_func, runs)
end

#sixth entry point, nothing to change here, unless you want to meddle with step functions
function step_six(i, N, p, pd, q, qd, sim, simd, bsd, bs_arg, bs_func, runs, s_win=1, s_loss=-1, s_none=0)
	@parallel for r in 1:runs
		source = bs_func(bs_arg, r, runs, i)
		init(source)
		rand_source = sim(source)
		state = Gambler1D(i, N, p, q, s_win, s_loss, s_none)
		try
			(t, w) = runGambler(state, Gambler.stepRegular, rand_source)
			fini(source)
			#@printf("%s;%s;%d;%d;%s;%s;%d;%d;\n", simd,bsd,i,N,pd,qd,w,t)
			#write(out_gam, "$simd;$bsd;$i;$N;$pd;$qd;$w;$t;\n")
			@out_gam("$simd;$bsd;$i;$N;$pd;$qd;$w;$t;\n")
		catch E
			if isa(E,EOFError)
				srcrep = repr(source)
				time = state.time
				print("Encountered EOF after $time steps, when processing $srcrep\n")
				fini(source)
				return (Int64[], Int64[])
			else
				throw(E)
			end
		end
	end
end

open("estimated.csv", "w")  do f write(f, "i;N;p;q;rho;\n") end
open("fullreport.csv", "w") do f write(f, "sim;bs;i;N;p;q;won;len;\n") end

@everywhere __out_est = open("estimated.csv",  "a")
@everywhere __out_gam = open("fullreport.csv", "a")

@sync step_one()


