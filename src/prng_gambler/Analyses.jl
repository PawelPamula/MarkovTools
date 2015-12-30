module Analyses

export AnalyzeGambler1D

using RandSources
using Gambler
using BitSeqModule

function AnalyzeGambler1D(randomSources, start::Int64, limit::Int64, p::Real, q::Real, stepWin::Int64=1, stepLoss::Int64=-1, stepNone::Int64=0)
	results = [
				runGambler(Gambler1D(start, limit, p, q, stepWin, stepLoss, stepNone), Gambler.stepRegular, source)
				for source in randomSources
			]
	Wins  = 0
	Loses = 0
	Total = 0
	TotalTime = 0
	
	for (T, W) in results
		if W
			Wins += 1
		else
			Loses += 1
		end
		Total += 1
		TotalTime += T
	end
	
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
	for N in [16, 32, 64, 128, 256]
		for i in 1:(N-1)
			println("i: ", i, " N: ", N)
			runOnSources(i, N, 1//2, 1//2, runs)
			runOnSources(i, N, 0.47, 0.53, runs)
			runOnSources(i, N, 2//5, 3//7, runs)
		end
	end
end

function runOnSources(i, N, p, q, runs)
	sources0 = [RandSources.juliaBitSource for i in 1:runs]
	sources1 = [RandSources.bitSeqBitSource(
			fileToBitSeq("seq_urand_$i")
		) for i in 1:runs]
	sources2 = [RandSources.bitSeqBitSource(
			fileToBitSeq("seq_openssl_$i")
		) for i in 1:runs]
	randomSources0 = [BitTracker(src) for src in sources0]
	randomSources1 = [BitTracker(src) for src in sources1]
	randomSources2 = [BitTracker(src) for src in sources2]
	
	(rho,) = EstimateResultsGambler1D(i, N, p, q)
	rndrho = round(Int, rho * runs) // runs
	
	println("Expected rho: $rho")
	println("($rndrho)")
	println(AnalyzeGambler1D(randomSources0, i, N, p, q))
	println(AnalyzeGambler1D(randomSources1, i, N, p, q))
	println(AnalyzeGambler1D(randomSources2, i, N, p, q))
end

end #module
