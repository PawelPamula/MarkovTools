#!/usr/bin/env julia
push!(LOAD_PATH, ".")

#   s = q / p
# rho = (1 - s^i) / (1 - s^N)
# 1/2 = (1 - s^i) / (1 - s^N)
# 1 - s^N = 2 - 2s^i
# - s^N = 1 - 2s^i
# 2s^i - s^N = 1
# s^i(2 - s^(N-1)) = 1

# 2x^i - x^N - 1 = p(x)

# Pkg.add("Polynomials")
# Pkg.add("Roots")
using Polynomials
using Roots

N = 300
x = poly([0])
t = 1/2^16

for i in 1:(N-1)
	P = 2x^i - x^N - 1
	
# more exact
	#for s in fzeros(P)
	#	if s > 0 && s != 1
	#		p = 1 / (s+1)
	#		print("$i : $p ($s)\n")
	#	end
	#end

#faster
	for r in roots(P)
		if imag(r) == 0
			s = real(r)
			if s > 0 && abs(s - 1) > t
				p = 1 / (s+1)
				q = 1 - p
				print("$i, $p, $q, $s\n")
			end
		end
	end
end
