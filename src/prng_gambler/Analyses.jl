module Analyses

export AnalyzeGambler1D

using RandSources
using Gambler
using BitSeqModule

"""
Simple Gambler analyzer. Runs Gambler's ruin process with given @start, 
@limit, @p, @q, @stepFunction, @stepWin, @stepLoss and @stepNone parameters on all
given @randomSources. Then, it counts the number of wins and loses,
total time of all games, average game time.

@return a tuple of form (# of wins, # of loses, total # of games, 
	averaged win/total ratio, total time of all games and the average
	time of one game.
"""
function AnalyzeGambler1D(randomSources, start::Int64, limit::Int64, p, q, 
stepFunction, stepWin::Int64=1, stepLoss::Int64=-1, stepNone::Int64=0)
		
	join(a, b) = ([a[1]; b[1]], [a[2]; b[2]])
	
	function just_run(source)
		(t, w) = runGambler(Gambler1D(start, limit, p, q, stepWin, stepLoss, stepNone), stepFunction, source)
		if w
			return (t, [])
		else
			return ([], t)
		end
	end
	
	(ArrVic, ArrDef) = @parallel (join) for source in randomSources; just_run(source) end
	
	Wins  = length(ArrVic)
	Losses = length(ArrDef)
	TotalTimeVic = sum(ArrVic)
	TotalTimeDef = sum(ArrDef)
	
	Total = Wins + Losses
	TotalTime = TotalTimeVic + TotalTimeDef
	
	AvgTime = TotalTime / Total
	AvgTimeVic = TotalTimeVic / Wins
	AvgTimeDef = TotalTimeDef / Losses
	
	TimeVicVar = @parallel (+) for t in ArrVic; (t - AvgTimeVic)^2; end
	TimeVicVar /= Wins - 1
	TimeDefVar = @parallel (+) for t in ArrDef; (t - AvgTimeDef)^2; end
	TimeDefVar /= Losses - 1
	TimeVar = @parallel (+) for t in [ArrVic; ArrDef]; (t - AvgTime)^2; end
	TimeVar /= Total - 1
	
	return (Wins, Losses, Total, float(Wins / Total), AvgTime, TimeVar, AvgTimeVic, TimeVicVar, AvgTimeDef, TimeDefVar)
end

function EstimateResultsGambler1D(start::Int64, limit::Int64, p, q)
	# Compute the expected probability of winning with the given start, limit, p and q:
	i = start
	N = limit
	
	divident = sum([prod([big(q(r, N) / p(r, N)) for r in 1:(n-1)]) for n in 2:i])
	divisor  = sum([prod([big(q(r, N) / p(r, N)) for r in 1:(n-1)]) for n in 2:N])
	
	rho = divident / divisor
	
	return (rho,)
end

function runTest(runs)
	#for N in [16, 32, 64, 128, 256]
#	for N in [16, 32, 64]
#		for i in 1:(N-1)
#			println("i: ", i, " N: ", N)
#			runOnSources(i, N, 0.50, 0.50, runs)
#			runOnSources(i, N, 0.47, 0.53, runs)
#			runOnSources(i, N, 2//5, 3//7, runs)
#		end
#	end
	#for N in [300]
	#	i = 150
	#	println("i: ", i, " N: ", N)
	#	runOnSources(i, N, 1//2, 1//2, runs)
	#	runOnSources(i, N, 0.47, 0.53, runs)
	#	runOnSources(i, N, 2//5, 3//7, runs)
	#end
	p(i::Int64, N::Int64) = 0.48
	q(i::Int64, N::Int64) = 0.52
	
	runOnSources(290, 300, p, "0.48", q, "0.52", runs)
end

function runOnSources(i, N, p, str_p, q, str_q, runs)
	#fileSources = ["seq/R/urand/", "seq/R/openssl/", "seq/R/rc4/", "seq/R/spritz/", "seq/R/vmpc/", "seq/R/rc4p/", "seq/R/aes128ctr/", "seq/R/aes192ctr/", "seq/R/aes256ctr/", "seq/R/crand/", "seq/R/randu/", "seq/R/hc128/"]
	fileSources = ["seq/R/urand/", "seq/R/openssl/", "seq/R/rc4/", "seq/R/spritz/", "seq/R/vmpc/", "seq/R/rc4p/", "seq/R/aes128ctr/", "seq/R/crand/", "seq/R/randu/", "seq/R/hc128/"]
	#fileSources = ["seq/R/urand/", "seq/R/openssl/", "seq/R/rc4/", "seq/R/crand/"]
	#fileSources = ["seq/R/urand/", "seq/R/crand/", "seq/R/randu/"]
	#fileSources = ["seq/R/rc4/"]
	
#	brokenBitSources = [RandSources.brokenBitSource for i in 1:runs]
	juliaBitSources = [RandSources.juliaBitSource for i in 1:runs]
	
	fileSourcesComp = [
						RandSources.bitSeqBitSource(BitSeqModule.fileToBitSeq("$file$i"))
						for i=1:runs, file=fileSources
					]
	
#	sources = [	brokenBitSources juliaBitSources fileSourcesComp ]
	sources = fileSourcesComp
	
	randomSources = [
						BitTracker(sources[x,y]) for x=1:size(sources,1), y=1:size(sources,2)
#						BitSlicer(sources[x,y], 15) for x=1:size(sources,1), y=1:size(sources,2)
#						BitSlicerInv(sources[x,y], 15) for x=1:size(sources,1), y=1:size(sources,2)
					]

	simulation_type = "BitTracker"
				
	labels = [
				# "Broken 01010101 # "
				# "Julia Rand(0:1) # "
				"/dev/urandom    # "
				"OpenSSL-RNG     # "
				"OpenSSL-RC4     # "
				"SPRITZ          # "
				"VMPC-KSA        # "
				"RC4+            # "
				"AES-128-CTR     # "
				# "AES-192-CTR     # "
				# "AES-256-CTR     # "
				"C RAND          # "
				"RANDU LCG       # "
				"HC128           # "
			]
	
	(rho,) = EstimateResultsGambler1D(i, N, p, q)
	rndrho = round(Int, rho * runs) // runs
	
	@printf("Expected rho: %f ", rho)
	println("($rndrho) for p: $str_p, q: $str_q")
	#println(" for p: $p, q: $q")
	out_file = open("./results.csv", "w")
	write(out_file, "p(i), q(i), N, n, i_0, simulation type, generator, estimated rho(i), simulated rho(i), variance (est), variance (sim), error b, mean time, time variance, mean time to win, time to win variance, mean time to loose, time to loose variance\n")
	
	for rs in 1:length(labels)
		analysis = AnalyzeGambler1D(randomSources[:,rs], i, N, p, q, Gambler.stepRegular)

		lbl = labels[rs]
		(wins, loses, total, ratio, timeavg, timevar, timevicavg, timevicvar, timedefavg, timedefvar) = analysis
		rho_variance = (wins * ((1 - rho)^2) + loses * ((0 - rho)^2)) / total
		mean_variance = (wins * ((1 - ratio)^2) + loses * ((0 - ratio)^2)) / (total - 1)

		fdiff = Float32(rho - ratio)
		fvrho = Float32(rho_variance)
		fmrho = Float32(mean_variance)
		write(out_file, join((str_p, str_q, N, runs, i, simulation_type, lbl, rho, ratio, rho_variance, mean_variance, "-", timeavg, timevar, timevicavg, timevicvar, timedefavg, timedefvar), ","), "\n")
		println("$lbl $analysis diff.: $fdiff v_rho: $fvrho v_mean: $fmrho")
	end
	close(out_file)
end

end #module
