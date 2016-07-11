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

	(p5, q5) = filedPQ("random_p_q_1.csv")
	(p6, q6) = filedPQ("random_p_q_7.csv")

	#
	#  All i in range:
	#
	ps, qs = filedPQ_const("balanced_p_q_64.csv")
	N = 64
	for i in 1:63
		# p7(r,N) syntax doesn't capture the current i!
		p7 = (r, N) -> ps[i]
		q7 = (r, N) -> qs[i]
	#	push!(tests_params, (i, N, p1, "0.48", q1, "0.52"))
	#	push!(tests_params, (i, N, p2, "(i)/(2i+1)", q2, "(i+1)/(2i+1)"))
	#	push!(tests_params, (i, N, p3, "(i)^3/(2*i^3+3*i^2+3*i+1)", q3, "(i+1)^3/(2*i^3+3*i^2+3*i+1)"))
	#	push!(tests_params, (i, N, p4, "i/N", q4, "(N-i)/N"))
	#	push!(tests_params, (i, N, p6, "random(2)", q6, "random(2)"))
		push!(tests_params, (i, N, p7, "balanced(1/2)", q7, "balanced(1/2)"))
	end
	
	simulations = [
					"BitTracker    " BitTracker;
				#	"BitSlicer8    " x -> BitSlicer(x, 8);
				#	"BitSlicerInv8 " x -> BitSlicerInv(x, 8);
				#	"BitSlicer12   " x -> BitSlicer(x, 12);
				#	"BitSlicerInv12" x -> BitSlicerInv(x, 12);
				#	"BitSlicer15   " x -> BitSlicer(x, 15);
				#	"BitSlicerInv15" x -> BitSlicerInv(x, 15);
				#	"BitSlicer16   " x -> BitSlicer(x, 16);
				#	"BitSlicerInv16" x -> BitSlicerInv(x, 16);
				#	"BitSlicer17   " x -> BitSlicer(x, 17);
				#	"BitSlicerInv17" x -> BitSlicerInv(x, 17);
				#	"BitSlicer31   " x -> BitSlicer(x, 31);
				#	"BitSlicerInv31" x -> BitSlicerInv(x, 31);
				]
				
	sources = [
			#	"Broken 01010101 " ""            Analyses.bsFromBroken;
			#	"Julia Rand(0:1) " ""            Analyses.bsFromJulia;
			#	"/dev/urandom    " "urandom"     Analyses.bsFromCmd;
			#	"OpenSSL-RNG     " "openssl-rng" Analyses.bsFromCmd;
				"OpenSSL-RC4     " "rc4"         Analyses.bsFromCmd;
			#	"SPRITZ          " "spritz"      Analyses.bsFromCmd;
			#	"VMPC-KSA        " "vmpc"        Analyses.bsFromCmd;
			#	"RC4+            " "rc4p  "      Analyses.bsFromCmd;
			#	"AES-128-CTR     " "aes128ctr"   Analyses.bsFromCmd;
			#	"AES-192-CTR     " "aes192ctr"   Analyses.bsFromCmd;
			#	"AES-256-CTR     " "aes256ctr"   Analyses.bsFromCmd;
			#	"C RAND          " "c_rand"      Analyses.bsFromCmd;
			#	"RANDU LCG       " "randu"       Analyses.bsFromCmd;
			#	"HC128           " "hc128"       Analyses.bsFromCmd;
			#	"RABBIT          " "rabbit"      Analyses.bsFromCmd;
			#	"SALSA20/12      " "salsa20"     Analyses.bsFromCmd;
			#	"SOSEMANUK       " "sosemanuk"   Analyses.bsFromCmd;
			#	"GRAIN           " "grain"       Analyses.bsFromCmd;
			#	"MICKEY          " "mickey"      Analyses.bsFromCmd;
			#	"TRIVIUM         " "trivium"     Analyses.bsFromCmd;
			#	"F-FCSR          " "ffcsr"       Analyses.bsFromCmd;
			#	"Mersenne Twister" "mersenne"    Analyses.bsFromCmd;
			#	"Borland C       " "borland"     Analyses.bsFromCmd;
			#	"Visual Studio   " "vs"          Analyses.bsFromCmd;
			#	"CMRG            " "cmrg"        Analyses.bsFromCmd;
			]

	Analyses.runTest(2^8, output_filename, tests_params, simulations, sources)
end

function filedPQ(filename)
	ps = []
	qs = []
	open(filename) do file
		for line in eachline(file)
			tp = split(line, ", ")
			append!(ps, [float(tp[2])])
			append!(qs, [float(tp[3])])
		end
	end
	pf(r, N) = ps[r]
	qf(r, N) = qs[r]

	return (pf, qf)
end

function filedPQ_const(filename)
	ps = []
	qs = []
	open(filename) do file
		for line in eachline(file)
			tp = split(line, ", ")
			append!(ps, [float(tp[2])])
			append!(qs, [float(tp[3])])
		end
	end

	return (ps, qs)
end

output_filename = "results.csv"
if length(ARGS) > 0
	output_filename = ARGS[1]
end

main(output_filename)
