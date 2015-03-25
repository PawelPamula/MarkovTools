#create a random transition matrix of n size with rational probabilities with denominator k
function RandomTransitionMatrix(n::Int64,k::Int64)
  RandM=rand(DiscreteUniform(1,n),(n,k))
  RandK=sortcols(RandM[1,1:k])
  for i in 2:n
    RandK=vcat(RandK,sortcols(RandM[i,1:k]))
  end

  Rnd=Array(Float64,n,n)
  for i in 1:n
    for j in 1:n
      Rnd[i,j]=count(y->y==j,[x::Int64 for x in sortrows(RandK)[i,1:k]])
    end
  end
  return Rnd/k
end

function RandomGraphMatrix(n::Int64)
  Mat=eye(Int64,n)
  Mat[1,1:n]=ones(Int64,n)
  Mat[1:n,n]=ones(Int64,n)
  for i in 2:(n-2)
    for j in (i+1):n-1
      Mat[i,j]=rand(Binomial())
    end
  end

  for i in 2:n-2
    for j in 1:(i-1)
      if Mat[n-i,n-j]==1
        for k in (n-j+1):(n-1)
          Mat[n-i,k]=max(Mat[n-i,k],Mat[n-j,k])
        end
      end
    end
  end
  return Mat
end

#for some matrices C and P check if Markov Process is Mobius down monotone

function is_mobius_down(C::Array{Int64,2},P::Array{Float64,2})
  R=convert_to_min_Int(P)
  return minimum(inv(C)*R*C .>= 0)
end

#for some matrices C and P check if Markov Process is Mobius up monotone
function is_mobius_up(C::Array{Int64,2},P::Array{Float64,2})
  R=convert_to_min_Int(P)
  return minimum(inv(C')*R*C' .>= 0)
end



#for some matrix C which represent poset give predecessors matrix
function predecessors_matrix(C::Array{Int64,2})
  C1=deepcopy(C)
  d=spzeros(1, size(C1)[1])
  for i=1:size(C1)[1]
    for k=i+1:size(C1)[1]
      if C1[i,k]==1
        C1[i,1:size(C1)[1]]-=C1[k,1:size(C1)[1]]
        d=vcat(d,sparse([1,1,1],[i,k,size(C1)[1]],[1,-1,0]))
      end
    end
  end
  return dense(d)[2:size(d)[1],[1:size(d)[2]]]
end

#for some matrices C and P check if Markov Process is weak down monotone
function is_weak_down(C::Array{Int64,2},P::Array{Float64,2})
  R=convert_to_min_Int(P)
  return minimum(predecessors_matrix(C)*R*C .>= 0)
end

#for some matrices C and P check if Markov Process is weak up monotone
function is_weak_up(C::Array{Int64,2},P::Array{Float64,2})
  R=convert_to_min_Int(P)
  return minimum(predecessors_matrix(C)*R*C' .<= 0)
end



#extended matrix C of up sets with minimal element to matrix of all up sets
function up_sets(C::Array{Int64,2})
  d=zeros(1, size(C)[1])
  for i=1:size(C)[1]
    D=deepcopy(C[i,1:size(C)[1]])
    for k=(i+1):size(C)[1]
      if D[1,k]==0
        for j=1:size(D)[1]
          if D[j,k]==0
            D=vcat(D,D[j,1:size(C)[1]]+C[k,1:size(C)[1]])
          end
        end
      end
    end
    d=vcat(d,D)
  end
  return sign(d[2:size(d)[1],[1:size(d)[2]]])'
end

#for some matrices C and P check if Markov Process is stochastically monotone
function is_stochastic(C::Array{Int64,2},P::Array{Float64,2})
  C1=deepcopy(C)
  R=convert_to_min_Int(P)
  return minimum(predecessors_matrix(C1)*R*up_sets(C) .<= 0)
end





#multiplying elements of matrix by lcm of their denominators geting matrix with (small) integral elements
function convert_to_min_Int(P::Array{Float64,2})
  return convert(Array{Int64,2},lcm(map(den,convert(Array{Rational,2},P)))*P)
end

#from transition matrix P give any realization (in rows we have transitions on some range to some state)
function convert_to_min_Realization(P::Array{Float64,2})
  R=convert_to_min_Int(P)
  F=convert(Array{Int64,2},zeros(1, 1+sum(R[1,1:size(R)[2]])))
  for i=1:size(R)[1]
    f=[0]
    for j=1:size(R)[2]
      for k=1:R[i,j]
        f=hcat(f,j)
      end
    end
    F=vcat(F,f)
  end
  return F[2:size(F)[1],2:size(F)[2]]
end

#all posible realizations from transition matrix P (=all permutations on each state of any realization)
function all_Functions(P::Array{Float64,2})
  F=convert_to_min_Realization(P)


  # Perm=unique(permutations([x::Int64 for x in F[1,1:size(F)[2]]]))
# for i=2:size(F)[1]
#   Perm=vcat(Perm,unique(permutations([x::Int64 for x in F[i,1:size(F)[2]]])),(1,4))
  #end

  Perm = [unique(permutations([x::Int64 for x in F[1,i:size(F)[2]]])) for i = 1:size(F)[1]]
  return Perm
end

#checking if vector is not less that other considering ordering of matrix C
function stoch_not_less(vec1::Array{Int64,2},vec2::Array{Int64,2},C::Array{Int64,2})
  for i=1:length(vec1)
    if C[vec1[i],vec2[i]]!=1
      return true
    end
  end
  return false
end

#checking if Realization_function[j] is posible function on state 'j' (=is bigger then other, i<j, functions)
function check_vector_j(Realization_function::Array{Int64,2},j::Int64,C::Array{Int64,2})
  for i=1:j-1
    if stoch_not_less(Realization_function[i,1:size(Realization_function)[2]],Realization_function[j,1:size(Realization_function)[2]],C)
      return false
    end
  end
  return true
end

#searching for posible function on state 'j' when we know previous, i<j, functions
function Realization_j(j::Int64,Realization_function::Array{Int64,2},C::Array{Int64,2},aF)
  if j>size(aF)[1]
    return true
  end
  state=start(aF[j])
  while !done(aF[j], state)
    (i, state) = next(aF[j], state)
    Realization_function[j,1:length(i)]=i'
    if check_vector_j(Realization_function,j,C)
      if Realization_j(j+1,Realization_function,C,aF)==true
        return true
      end
    end
  end
  return false
end

#for some matrices C and P check if there exist (some kind of) realization of Markov Process
function is_realizable(C::Array{Int64,2},P::Array{Float64,2})
  aF=all_Functions(P)
  Realization_function=convert_to_min_Realization(P)
  if Realization_j(2,Realization_function,C,aF)==true
    return true
  end
  return false
end

#for some matrices C and P check all definitions of monotonicity
function which_is(C::Array{Int64,2},P::Array{Float64,2})
  return ["mobius_down" "mobius_up" "weak_down" "weak_up" "stochastic" "realizable"; is_mobius_down(C,P) is_mobius_up(C,P) is_weak_down(C,P) is_weak_up(C,P) is_stochastic(C,P) is_realizable(C,P)]'
end

#for some matrices C and P check all definitions of monotonicity except realizable monotonicity
function which_is_not_real(C::Array{Int64,2},P::Array{Float64,2})
  return ["mobius_down" "mobius_up" "weak_down" "weak_up" "stochastic"; is_mobius_down(C,P) is_mobius_up(C,P) is_weak_down(C,P) is_weak_up(C,P) is_stochastic(C,P)]'
end

function check_stoch_mob_not_real(C,P)
  if is_mobius_up(C,P) if is_mobius_down(C,P) if is_stochastic(C,P) return !(is_realizable(C,P))
      end end end
  return false
end

function searching_for_stoch_mob_not_real(N::Int64)
  for i in 1:N
    n=rand(7:12)
    m=rand(7:12)
    C=RandomGraphMatrix(n)
    for j in 1:1000
      P=RandomTransitionMatrix(n,m)
      if check_stoch_mob_not_real(C,P)
        return (C,P)
      end
    end
  end
  return false
end

