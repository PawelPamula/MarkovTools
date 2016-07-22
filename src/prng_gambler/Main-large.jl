#!/usr/bin/env julia
push!(LOAD_PATH, ".")

using Analyses
using RandSources

function main(output_filename)
	tests_params = []
	
	# First choose tests to perform
	#
	#  Constant p and q:
	#
	p1(i::Int64, N::Int64) = 0.48
	q1(i::Int64, N::Int64) = 0.52
	#
	#  Variable p and q:
	#
	p2(i::Int64, N::Int64) = (i)//(2*i + 1)
	q2(i::Int64, N::Int64) = (i+1)//(2*i + 1)

	p3(i::Int64, N::Int64) =   (i)^3//(2*i^3 + 3*i^2 + 3*i + 1)
	q3(i::Int64, N::Int64) = (i+1)^3//(2*i^3 + 3*i^2 + 3*i + 1)

	p4(i::Int64, N::Int64) = i//N
	q4(i::Int64, N::Int64) = (N-i)//N

	#delta - deviation from 0.5 for the upcoming tests:
	delta = 1//128

	# new test: (atan(N/2 - i) / 32pi) + 0.5 (values range between 31/64 and 33/64)
	p5(i::Int64, N::Int64) = (atan(N/2 - i) / pi)*delta + 0.5
	q5(i::Int64, N::Int64) = 0.5 - (atan(N/2 - i) / pi)*delta
	# new test: (sin((i / N) * 2pi) / delta + 0.5)
	p6(i::Int64, N::Int64) = 0.5 + (sin((i / N) * 2pi) * delta)
	q6(i::Int64, N::Int64) = 0.5 - (sin((i / N) * 2pi) * delta)
	
	# single N, a few i:
	N = 512
	# start at 1/4, at half, at 3/4	
	for i in [round(Int,1N//4), round(Int,1N//2), round(Int,3N//4)]
		push!(tests_params, (i, N, p5, "atan(..)", q5, "atan(..)"))
		push!(tests_params, (i, N, p6, "sin(..)", q6, "sin(..)"))
	end

	simulations = [
					"BitTracker    " BitTracker;
			]
				
	sources = [
			#	"Broken 01010101 " ""            Analyses.bsFromBroken;
			#	"Julia Rand(0:1) " ""            Analyses.bsFromJulia;
			#	"/dev/urandom    " "urandom"     Analyses.bsFromCmd;
			#	"OpenSSL-RNG     " "openssl-rng" Analyses.bsFromCmd;
			#	"OpenSSL-RC4     " "rc4"         Analyses.bsFromCmd;
			#	"SPRITZ          " "spritz"      Analyses.bsFromCmd;
			#	"VMPC-KSA        " "vmpc"        Analyses.bsFromCmd;
			#	"RC4+            " "rc4p  "      Analyses.bsFromCmd;
			#	"AES-128-CTR     " "aes128ctr"   Analyses.bsFromCmd;
			#	"AES-192-CTR     " "aes192ctr"   Analyses.bsFromCmd;
			#	"AES-256-CTR     " "aes256ctr"   Analyses.bsFromCmd;
			#	"HC128           " "hc128"       Analyses.bsFromCmd;
			#	"RABBIT          " "rabbit"      Analyses.bsFromCmd;
			#	"SALSA20/12      " "salsa20"     Analyses.bsFromCmd;
			#	"SOSEMANUK       " "sosemanuk"   Analyses.bsFromCmd;
			#	"GRAIN           " "grain"       Analyses.bsFromCmd;
			#	"MICKEY          " "mickey"      Analyses.bsFromCmd;
			#	"TRIVIUM         " "trivium"     Analyses.bsFromCmd;
			#	"F-FCSR          " "ffcsr"       Analyses.bsFromCmd;
			#	"C RAND          " "c_rand"      Analyses.bsFromCmd;
			#	"RANDU LCG       " "randu"       Analyses.bsFromCmd;
			#	"BSD RAND        " "oldbsd"      Analyses.bsFromCmd;
			#	"Minstd          " "minstd"      Analyses.bsFromCmd;
			#	"Mersenne Twister" "mersenne"    Analyses.bsFromCmd;
			#	"Mersenne AR     " "mersenne_ar" Analyses.bsFromCmd;
			#	"Borland C       " "borland"     Analyses.bsFromCmd;
			#	"Visual Studio   " "vs"          Analyses.bsFromCmd;
			#	"CMRG            " "cmrg"        Analyses.bsFromCmd;
				"Knuth           " ""            RandSources.bsFromKnuth;
				"Ran1            " ""            RandSources.bsFromRan1;
				"Ran2            " ""            RandSources.bsFromRan2;
				"Ran3            " ""            RandSources.bsFromRan3;
				"MRG             " ""            RandSources.bsFromMRG;
				"ICG1            " ""            RandSources.bsFromICG1;
				"ICG2            " ""            RandSources.bsFromICG2;
				"EICG1           " ""            RandSources.bsFromEICG1;
				"EICG7           " ""            RandSources.bsFromEICG7;
				"CCCG            " ""            RandSources.bsFromCCCG;
			]

	Analyses.runTest(16, output_filename, tests_params, simulations, sources)
end

ADD_BASE = "GAMBLER_0001"
if !haskey(ENV, "ADD_BASE")
	ENV["ADD_BASE"] = "GAMBLER_0001"
else
	ADD_BASE = ENV["ADD_BASE"]
end

output_filename = "results.csv"
if length(ARGS) > 0
	output_filename = ARGS[1]
end

main(output_filename)
