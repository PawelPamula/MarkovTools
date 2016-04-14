module Analyses

export AnalyzeGambler1D, EstimateResultsGambler1D

using RandSources
using Gambler
using BitSeqModule
using FileSources

"""
Simple Gambler analyzer. Runs Gambler's ruin process with given @start, 
@limit, @p, @q, @stepFunction, @stepWin, @stepLoss and @stepNone parameters on all
given @randomSources. Then, it counts the number of wins and loses,
total time of all games, average game time.

@return a tuple of form (# of wins, # of loses, total # of games, 
	averaged win/total ratio, total time of all games and the average
	time of one game.
"""
function AnalyzeGambler1D(bitSourcesFun, file, simulation, start::Int64, limit::Int64, p, q, 
stepFunction, stepWin::Int64=1, stepLoss::Int64=-1, stepNone::Int64=0)
		
	join(a, b) = ([a[1]; b[1]], [a[2]; b[2]])
	
	function just_run(source)
		try
			init(source)
			rand_source = simulation(source)
			(t, w) = runGambler(Gambler1D(start, limit, p, q, stepWin, stepLoss, stepNone), stepFunction, rand_source)
			fini(source)
			if w
				return (t, Int64[])
			else
				return (Int64[], t)
			end
		catch EOFError
			srcrep = repr(source)
			print("Encountered EOF when processing $srcrep\n")
			fini(source)
			return (Int64[], Int64[])
		end
	end
	
	function map_run(source)
		try
			init(source)
			rand_source = simulation(source)
			(t, w) = runGambler(Gambler1D(start, limit, p, q, stepWin, stepLoss, stepNone), stepFunction, rand_source)
			fini(source)
			return (t, w)
		catch EOFError
			srcrep = repr(source)
			print("Encountered EOF when processing $srcrep\n")
			fini(source)
			return (0, -1)
		end
	end
	
	bitSources = bitSourcesFun(file)
	
	ArrVic = Int64[]
	ArrDef = Int64[]
	# should be pmap for parallel, but makes no difference
	for (val, win) in map(map_run, bitSources)
		if win == 1
			push!(ArrVic, val)
		elseif win == 0
			push!(ArrDef, val)
		end
	end
	#(ArrVic, ArrDef) = @parallel (join) for source in bitSources; just_run(source) end
	
	Wins  = length(ArrVic)
	Losses = length(ArrDef)
	TotalTimeVic = sum(ArrVic)
	TotalTimeDef = sum(ArrDef)
	
	Total = Wins + Losses
	TotalTime = TotalTimeVic + TotalTimeDef
	
	AvgTime = TotalTime / Total
	AvgTimeVic = TotalTimeVic / Wins
	AvgTimeDef = TotalTimeDef / Losses
	
	TimeVar = var([ArrVic;ArrDef])
	TimeVicVar = var(ArrVic)
	TimeDefVar = var(ArrDef)
	
	return (Wins, Losses, Total, float(Wins / Total), AvgTime, TimeVar, AvgTimeVic, TimeVicVar, AvgTimeDef, TimeDefVar)
end

function EstimateResultsGambler1D(start::Int64, limit::Int64, p, q)
	# Compute the expected probability of winning with the given start, limit, p and q:
	i = start
	N = limit
	
	divident = sum(BigFloat[prod(BigFloat[big(q(r, N) / p(r, N)) for r in 1:(n-1)]) for n in 2:i]) + 1
	divisor  = sum(BigFloat[prod(BigFloat[big(q(r, N) / p(r, N)) for r in 1:(n-1)]) for n in i+1:N]) + divident
	
	rho = divident / divisor
	
	return rho
end

# Functions for creating bit source
function bsFromFile(file, runs, i)
	[
		#RandSources.BitSeqBitSource(BitSeqModule.fileToBitSeq("seq/R$file$r"))
		RandSources.FileBitSource(FileSources.FileSource("seq/R$file$r"))
		for r=1:runs
	]
end

function bsFromCmd(cmd, runs, i)
	function generator(cmd, r)
		# byte limit for dynamically generated sources
		limit = 512*1024 #16*1024*1024
		# key derivation function
		kdf = "sha"
		km = r + (i * runs)
		return `bash generator.sh $kdf $cmd $limit $km`
	end
	[
		RandSources.FileBitSource(FileSources.CmdSource(generator(cmd, r)))
		for r=1:runs
	]
end

function bsFromBroken(arg, runs, i)
	[RandSources.BrokenBitSource() for r in 1:runs]
end

function bsFromJulia(arg, runs, i)
	[RandSources.JuliaBitSource() for r in 1:runs]
end

function runTest(runs, out_filename, tests_params, simulations, sources)
	# @runs: number of simulation runs for each tests
	# @tests_params: list of (i, N, p, str_p, q, str_q)
	# @simulations: list of (simulation_type_name, simulation_type_function)
	# @sources: list of (name, arg, function) arg is an argument for function,
	#           function should be one of bsFrom* functions defined above
	
	function append_rho(params)
		i, N, p, str_p, q, str_q = params
		rho = EstimateResultsGambler1D(i, N, p, q)
		rndrho = round(Int, rho * runs) // runs
		return i, N, p, str_p, q, str_q, rho
	end
	
	tests_params = map(append_rho, tests_params)
	
	out_file = open(out_filename, "w")
	write(out_file, "p(i), q(i), N, n, i_0, simulation type, generator, estimated rho(i), simulated rho(i), variance (est), variance (sim), error b, mean time, time variance, mean time to win, time to win variance, mean time to lose, time to lose variance\n")
	
	tasks = [(bs, rs, params) for
			bs in 1:size(sources,1),
			rs in 1:size(simulations,1),
			params in tests_params]
	np = nprocs()
	n = length(tasks)
	i = 1
	nextidx() = (idx=i; i+=1; idx)
	@sync begin
		for proc = np == 1 ? 1 : 2 : np
			@async begin
				while true
					idx = nextidx()
					if idx > n
						break
					end
					bs, rs, params = tasks[idx]
					lbl, file, to_bs_r = sources[bs,:]
					to_bs = x -> to_bs_r(x, runs, idx)
					simulation_type, simulation = simulations[rs,:]
					i, N, p, str_p, q, str_q, rho = params
					
					analysis = remotecall_fetch(proc, AnalyzeGambler1D, to_bs, file, simulation, i, N, p, q, Gambler.stepRegular)

					wins, loses, total, ratio, timeavg, timevar, timevicavg, timevicvar, timedefavg, timedefvar = analysis
					rho_variance = (wins * ((1 - rho)^2) + loses * ((0 - rho)^2)) / total
					mean_variance = (wins * ((1 - ratio)^2) + loses * ((0 - ratio)^2)) / (total - 1)

					fdiff = Float32(rho - ratio)
					fvrho = Float32(rho_variance)
					fmrho = Float32(mean_variance)
					write(out_file, join((str_p, str_q, N, runs, i, simulation_type, lbl, float(rho), float(ratio), float(rho_variance), float(mean_variance), "-", timeavg, timevar, timevicavg, timevicvar, timedefavg, timedefvar), ","), "\n")
					flush(out_file)
					println("[$i -> $N] Expected rho:$(float(rho)) $lbl $simulation_type $analysis diff.: $fdiff v_rho: $fvrho v_mean: $fmrho")
				end
			end
		end
	end
	close(out_file)
end

end #module

