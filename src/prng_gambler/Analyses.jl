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
	Total = length(results)
	TotalTime = 0
	
	for (T, W) in results
		if W
			Wins += 1
		end
		TotalTime += T
	end
	Loses = Total - Wins
	
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
	for N in [16, 32, 64]
		for i in 1:(N-1)
			println("i: ", i, " N: ", N)
			runOnSources(i, N, 1//2, 1//2, runs)
			runOnSources(i, N, 0.47, 0.53, runs)
			runOnSources(i, N, 2//5, 3//7, runs)
		end
	end
	for N in [512, 1024, 4096]
		i = N/2
		println("i: ", i, " N: ", N)
		runOnSources(i, N, 1//2, 1//2, runs)
		runOnSources(i, N, 0.47, 0.53, runs)
		runOnSources(i, N, 2//5, 3//7, runs)
	end
end

function runOnSources(i, N, p, q, runs)
	fileSources = ["seq_urand_", "seq_openssl_", "seq_rc4_", "seq_aes128ctr_", "seq_aes192ctr_", "seq_aes256ctr_"]
	
	juliaBitSources = [RandSources.juliaBitSource for i in 1:runs]
	
	fileSourcesComp = [
						RandSources.bitSeqBitSource(BitSeqModule.fileToBitSeq("$file$i"))
						for i=1:runs, file=fileSources
					]
	
	sources = [juliaBitSources fileSourcesComp]
	randomSources = [
						BitTracker(sources[x,y]) for x=1:size(sources,1), y=1:size(sources,2)
					]
	
	labels = [
				"Julia Rand(0:1) # "
				"/dev/urandom    # "
				"OpenSSL-RNG     # "
				"OpenSSL-RC4     # "
				"AES-128-CTR     # "
				"AES-192-CTR     # "
				"AES-256-CTR     # "
			]
	
	(rho,) = EstimateResultsGambler1D(i, N, p, q)
	rndrho = round(Int, rho * runs) // runs
	
	println("Expected rho: $rho")
	println("($rndrho) for p: $p, q: $q")
	for rs in 1:length(labels)
		print(labels[rs])
		println(AnalyzeGambler1D(randomSources[:,rs], i, N, p, q))
	end
end

end #module
