
# Na razie tutaj krotki "doc"

# Albo wywolujemy z tablicami liczb, wtedy trzeba podac N
# Np.
# K=[3 4 5]
# M=[4 3 2 4 5]
# C = Spritz_Encrypt(8,K,M);
# Spritz_Decrypt(8,K,C)
# Spritz_Hash(8,[3 4 5 4 2],32)
#
# Albo z "napisami", wtedy przyjmowane jest N=8, kazdy znak 'x' zamieniany jest na int('x'), np.
# Spritz_Hash("arcfour",32)
# 
# 
 

type Spritz  
    i::Int64
    j::Int64
    k::Int64
    z::Int64
    a::Int64
    w::Int64
    N::Int64
    S 
    
   #Spritz(n::Int64)=new(0,0,0,0,0,0,n,0) 
   function Spritz(n::Int64)
   
    S=[]
     for v=1:n 
	  S=[S,v-1] 
      end
     
    
    return new(0,0,0,0,0,1,n,S) 
   end
    
end

function Spritz_Show(sp::Spritz)
  println("i=",sp.i," j=",sp.j, " k=",sp.k, " z=",sp.z, " a=",sp.a, " w=",sp.w, " N=",sp.N)
  println("S=",sp.S )
end 

function Spritz_Swap(sp::Spritz, i::Int64, j::Int64)
# println("Spritz_Swap(sp,",i,",",j,")")
  tmp = sp.S[i+1]
  sp.S[i+1]=sp.S[j+1]
  sp.S[j+1]=tmp
end
  

function Spritz_Update(sp::Spritz)
  sp.i=(sp.i+sp.w) % sp.N 
  #sp.j=(sp.k+sp.S[sp.j+1 + sp.S[sp.i+1 % sp.N +1 ] % sp.N +1 ] ) % sp.N 
 # println("i=",sp.i)
 # println("sp.j+ sp.S[sp.i] +1= ", sp.S[(sp.j+ sp.S[(sp.i%sp.N)+1])%sp.N+1]  )
                        
 # sp.j= (sp.k+sp.S[(sp.j+ sp.S[((sp.i+1)%sp.N)+1])%sp.N+1])%sp.N
   sp.j= (sp.k+sp.S[ (sp.j+ sp.S[sp.i+1]) %sp.N+1])%sp.N
  
  sp.k=(sp.i+sp.k+sp.S[sp.j+1])%sp.N
  #sp.k=(sp.i + sp.k + sp.S[sp.j+1 % sp.N + 1] ) % sp.N 
  
  Spritz_Swap(sp,sp.i,sp.j)
end
  
function Spritz_Whip(sp::Spritz, r::Int64)
  for v in 0:(r-1) 
    Spritz_Update(sp)
  end
  #tutaj powinno byc: do w=w+1 until GCD(w,N)=1
  sp.w=sp.w+1
  while gcd(sp.w,sp.N)>1
     sp.w=sp.w+1
  end
end

function Spritz_Crush(sp::Spritz)
#println("convert(Int64,(floor(sp.N/2)-1)) = ", convert(Int64,(floor(sp.N/2)-1)))


for v in 0:convert(Int64,(floor(sp.N/2)-1))
    #println("v=",v)
    if sp.S[v+1]>sp.S[sp.N-1-v+1]
      #println("zamiana ",v+1, " z " , sp.N-1-v+1, ", czyli  Spritz_Swap(sp,",v,",",sp.N-1-v," <--)" ) 
      #Spritz_Show(sp) 
    Spritz_Swap(sp,v,sp.N-1-v) end
end
end


function Spritz_Shuffle(sp::Spritz)
  Spritz_Whip(sp,2*sp.N)
  Spritz_Crush(sp)
  Spritz_Whip(sp,2*sp.N)
  Spritz_Crush(sp)
  Spritz_Whip(sp,2*sp.N)
  sp.a=0
end

function Spritz_AbsorbStop(sp::Spritz)
  if sp.a==convert(Int64,floor(sp.N/2)) Spritz_Shuffle(sp) end
  sp.a = sp.a+1 
end


function Spritz_AbsorbNibble(sp::Spritz,x::Int64)
  if sp.a==convert(Int64,floor(sp.N/2)) Spritz_Shuffle(sp) end
  Spritz_Swap(sp,sp.a, (convert(Int64,floor(sp.N/2))+x )%sp.N)
  
  sp.a = sp.a + 1
end

function Spritz_AbsorbByte(sp::Spritz, b::Int64)
  D=convert(Int64,ceil(sqrt(sp.N)))
  low= b% D
  high  = convert(Int64, floor(b/D))
  # println("!!!!!!!!!! low=", low, ", high=",high, ", D=",D)
  Spritz_AbsorbNibble(sp,low)
  Spritz_AbsorbNibble(sp,high)
end

function Spritz_Absorb(sp::Spritz,I::Array{Int64,2})
#println("size(I)=",size(I))
len=size(I)[2]
#println("len=",len)
for v in 0:(len-1) Spritz_AbsorbByte(sp,I[v+1]) end
end


function Spritz_Output(sp::Spritz)
szk= sp.S[(sp.z+sp.k)%sp.N+1]
si=sp.S[(sp.i+szk)%sp.N+1]
sp.z=sp.S[(sp.j+si)%sp.N+1]
return sp.z
end

function Spritz_Drip(sp::Spritz)
  if sp.a>0 Spritz_Shuffle(sp) end 
  Spritz_Update(sp)
  return Spritz_Output(sp)
end


function Spritz_Squeeze(sp::Spritz, r::Int64)
  if sp.a>0 Spritz_Shuffle(sp) end 
  P=Int64[]
  for v in 0:(r-1)
     P=[P,Spritz_Drip(sp)]
  end
  return P
end


function Spritz_Initialize(sp,n::Int64)
    sp.i=0
    sp.j=0
    sp.k=0
    sp.z=0
    sp.a=0
    sp.w=1
    sp.N=n
    sp.S=[]
     for v=1:n s
	  sp.S=[sp.S,v-1] 
      end
end

function Spritz_KeySetup(sp::Spritz,K::Array{Int64,2})
  Spritz_Absorb(sp,K)
end
     
     
     
function Spritz_Encrypt(n::Int64, K::Array{Int64,2}, M::Array{Int64,2}, debug=0)
#debug = 0, return C
#debug = 1, return permutation S
  sp=Spritz(n)
  Spritz_KeySetup(sp,K)
  #Spritz_Show(sp)
  SQUEEZE=Spritz_Squeeze(sp,size(M)[2])
  C=[]
  for v in 1:size(M)[2] 
    C=[C, (M[v]+ SQUEEZE[v])%n] 
  end
 # println("C = ", C);
 # print("debug = ", debug,"\t")
  if(debug==0)
    return C'
  else
    return sp.S'
    end
    
end


     
function Spritz_Encrypt(K_str::ASCIIString, M_str::ASCIIString)
  n=256
  sp=Spritz(n)
  
  K=[]
  
  for v in 1:length(K_str)
        K=[K,int(K_str[v])]
  end
  
 
 M=[]
  for v in 1:length(M_str)
        M=[M,int(M_str[v])]
  end
 
 K=K'
 M=M'
 #println("K=",K," , M=",M, " , size(M)=")
 #println(size(M))
  
  
  Spritz_KeySetup(sp,K')
  Spritz_Show(sp)
  SQUEEZE=Spritz_Squeeze(sp,size(M)[2])
  C=[]
  for v in 1:size(M)[2] 
    C=[C, char((M[v]+ SQUEEZE[v])%n)] 
  end
  #println("C = ", C);
  return C'
end


function Spritz_Decrypt(n::Int64, K::Array{Int64,2}, C::Array{Int64,2})
  println("Hello")
  sp=Spritz(n) 
  Spritz_KeySetup(sp,K)
  SQUEEZE=Spritz_Squeeze(sp,size(C)[2])
  
  M=[]
  for v in 1:size(C)[2]
    
    if (C[v]-SQUEEZE[v]>=0) 
      tmp = (C[v]-SQUEEZE[v])%n
    else 
      tmp = (C[v]-SQUEEZE[v]+n)%n 
    end  
    M = [M, tmp]
  end
  println("M = ",M);
  return M'
end



function Spritz_Hash(n::Int64, M::Array{Int64,2}, r::Int64)
 sp=Spritz(n)
 Spritz_Absorb(sp,M)
 Spritz_AbsorbStop(sp)
 Spritz_AbsorbByte(sp,r)
 R = Spritz_Squeeze(sp,r)
 R = R'
 return R
end


function Spritz_Hash(M_str::ASCIIString, r::Int64)
 n=256
 sp=Spritz(n)
 
 M=[]
  for v in 1:length(M_str)
        M=[M,int(M_str[v])]
  end
 
 M=M'
 
 Spritz_Absorb(sp,M)
 Spritz_AbsorbStop(sp)
 Spritz_AbsorbByte(sp,r)
 SQUEEZED=Spritz_Squeeze(sp,r)
 SQUEEZED=SQUEEZED'
 
 R=[]
 for v in 1:size(SQUEEZED)[2]
     R = [R, hex(SQUEEZED[v])]
    # print(char(SQUEEZED[v])," ")
  end
     
     R=R'
 
 return R
end
