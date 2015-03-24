
   
include("spritz.jl")

# w pliku keys_N3_len3.txt sa wszystkie klucze dlugosci 3 z N=3
# wczytujemy jako tablice i konwertujemy do Intow
 
Klen=2
N=256

keys=zeros(N^Klen,Klen)

for v in 1:N^Klen
     tmp=v-1
    for j in 1:Klen
     #print("v = ", v, "j=",j,"  ")
     keys[v,j]= tmp % N
     tmp = convert(Int64,(tmp - (tmp % N) )  / N )
     #convert(Int64,floor(tmp / N))
    end
 #print(v," ")
end
keys=convert(Array{Int64,2},keys)

 println("keys = ",keys)
#println(keys)




  
#  A=convert( Array{Int64,2},readcsv("keys_N3_len3.txt"))

#M=[0 0 0 0 0 0]
M=[1 0]

M_len=size(M)[2]

 
### rows=size(A)[1]
### columns=size(A)[2]


rows=N^Klen
columns=Klen


C=ones(rows,M_len)
S=ones(rows,N)


#print("typeof(S)= ",typeof(S)," typeof(keys[3,1:3])=",typeof(keys[3,1:3]))


#println("asdf");

for v in 1:rows
   # C[v,:]=Spritz_Encrypt(N, A[v,1:3], M)
  # C[v,:]=       Spritz_Encrypt(N, keys[v,1:Klen], M,0)
   S[v,:]=       Spritz_Encrypt(N, keys[v,1:Klen], M,1)
   
   #println("Spritz_Encrypt(",N,", ",keys[v,1:Klen],", ",M,",0)");
end 
# println("S=",S);
 


C=convert(Array{Int64,2},C)
S=convert(Array{Int64,2},S)

### writecsv("encrypted_all_keys_N3_len3_m.txt",C)

### writecsv("permuations_all_keys_N3_len3_m.txt",S)


writecsv("encrypted_all_tmp.txt",C)
writecsv("permutations_all_tmp.txt",S)


#writecsv("permuations_all_tmp.txt",S)

# return C


# sp=Spritz(8)


# Spritz_Show(sp)

# println("Update...1")
# Spritz_Update(sp)

# Spritz_Show(sp)

# println("Update...2")
# Spritz_Update(sp)

# Spritz_Show(sp)


# println("Update...3")
# Spritz_Update(sp)

# Spritz_Show(sp)



