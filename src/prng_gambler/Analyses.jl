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
function AnalyzeGambler1D(randomSources, start::Int64, limit::Int64, p::Real, q::Real, stepFunction, stepWin::Int64=1, stepLoss::Int64=-1, stepNone::Int64=0)
	results = [
				runGambler(Gambler1D(start, limit, p, q, stepWin, stepLoss, stepNone), stepFunction, source)
				for source in randomSources
			]
	Wins  = 0
	Loses = 0
	Total = length(results)
	TotalTime = 0
	
	for (T, W) in results
		if W
			Wins += 1
		end
		TotalTime += T
	end
	Loses = Total - Wins
	
	# TODO: variance

	return (Wins, Loses, Total, float(Wins / Total), TotalTime, TotalTime / Total)
end

function EstimateResultsGambler1D(start::Int64, limit::Int64, p::Real, q::Real)
	# Compute the expected probability of winning with the given start, limit, p and q:
	i = start
	N = limit
	if p == q
		rho = i / N
	else
		qpr = big(q / p)
		rho = (1 - qpr^i) / (1 - qpr^N)
	end
	
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
	runOnSources(290, 300, 0.48, 0.52, runs)
end

function runOnSources(i, N, p, q, runs)
	#fileSources = ["seq/urand/", "seq/openssl/", "seq/rc4/", "seq/aes128ctr/", "seq/aes192ctr/", "seq/aes256ctr/", "seq/crand/", "seq/randu/"]
	fileSources = ["seq/urand/", "seq/openssl/", "seq/rc4/", "seq/aes128ctr/", "seq/crand/", "seq/randu/"]
	#fileSources = ["seq/urand/", "seq/openssl/", "seq/rc4/", "seq/crand/"]
	#fileSources = ["seq/urand/", "seq/crand/", "seq/randu/"]
	#fileSources = ["seq/rc4/"]
	
#	brokenBitSources = [RandSources.brokenBitSource for i in 1:runs]
	juliaBitSources = [RandSources.juliaBitSource for i in 1:runs]
	
	fileSourcesComp = [
						RandSources.bitSeqBitSource(BitSeqModule.fileToBitSeq("$file$i"))
						for i=1:runs, file=fileSources
					]
	
#	sources = [	brokenBitSources juliaBitSources fileSourcesComp ]
	sources = fileSourcesComp
	
	randomSources = [
#						BitTracker(sources[x,y]) for x=1:size(sources,1), y=1:size(sources,2)
#						BitSlicer(sources[x,y], 15) for x=1:size(sources,1), y=1:size(sources,2)
						BitSlicerInv(sources[x,y], 15) for x=1:size(sources,1), y=1:size(sources,2)
					]

				
	labels = [
				# "Broken 01010101 # "
				# "Julia Rand(0:1) # "
				"/dev/urandom    # "
				"OpenSSL-RNG     # "
				"OpenSSL-RC4     # "
				"AES-128-CTR     # "
				# "AES-192-CTR     # "
				# "AES-256-CTR     # "
				"C RAND          # "
				"RANDU LCG       # "
			]
	
	(rho,) = EstimateResultsGambler1D(i, N, p, q)
	rndrho = round(Int, rho * runs) // runs
	
	@printf("Expected rho: %f ", rho)
	println("($rndrho) for p: $p, q: $q")
	#println(" for p: $p, q: $q")
	for rs in 1:length(labels)
		analysis = AnalyzeGambler1D(randomSources[:,rs], i, N, p, q, Gambler.stepRegular)

		lbl = labels[rs]
		(wins, loses, total, ratio, timetotal, timeavg) = analysis
		rho_variance = (wins * ((1 - rho)^2) + loses * ((0 - rho)^2)) / total
		mean_variance = (wins * ((1 - ratio)^2) + loses * ((0 - ratio)^2)) / (total - 1)

		fdiff = Float32(rho - ratio)
		fvrho = Float32(rho_variance)
		fmrho = Float32(mean_variance)
		println("$lbl $analysis diff.: $fdiff v_rho: $fvrho v_mean: $fmrho")
	end
end

end #module
