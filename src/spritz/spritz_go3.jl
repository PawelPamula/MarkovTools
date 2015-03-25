
# TO DO: filename as parameter? in file N, and len given?

# we want to read a file encrypted_all_tmp.txt


N=256

# w tym pliku permutacje 1...256, 
println("Reading file...");
A=convert( Array{Int64,2},readcsv("permutations_all_tmp.txt"))
print(" done. ");
println(" . ");

#println(typeof(A))

len=size(A)[2]
nr_c=size(A)[1]




#na razie:
#nr_c=100;


W=zeros(nr_c,1)
#W=zeros(8^3,1)


 


for v in 1:nr_c
   tmp=0;
   for r in 1:len/2 
     if A[v,r]<=127 tmp=tmp+1; end;
   end
   W[v,1]=tmp; 
end;
   


W=convert(Array{Int64,2},W)

W_nr_zeros=0;
 

  
println("mean(W)=",mean(W),", variance = ", var(W));
#println("liczba 0 w W: = ", W_nr_zeros, " procentowo = ", W_nr_zeros/nr_c);
#println("W = ", W');

x=[1:nr_c];
using PyPlot

plot(x,W);




