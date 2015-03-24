
# TO DO: filename as parameter? in file N, and len given?

# we want to read a file encrypted_all_tmp.txt


N=8


A=convert( Array{Int64,2},readcsv("encrypted_all_tmp.txt"))
println(typeof(A))

len=size(A)[2]
nr_c=size(A)[1]



W=zeros(nr_c,1)
#W=zeros(8^3,1)




println("len = ", len, " bb=",bb);


for v in 1:nr_c
   tmp=0;
   for r in 1:len 
     println("v=", v, ", r=", r);
     tmp=tmp + N^(r-1)*A[v,r]
   end
   println("nr_c = ", nr_c, " , tmp=",tmp);
   W[tmp+1,1]=W[tmp+1,1]+1;
end;
   


W=convert(Array{Int64,2},W)

W_nr_zeros=0;

for v in 1:nr_c
  if W[v,1]==0 W_nr_zeros=W_nr_zeros+1; end;
  end;
  

  
  
println("len = ", len, " bb=",bb);

println("sum(W)=",sum(W));
println("liczba 0 w W: = ", W_nr_zeros, " procentowo = ", W_nr_zeros/nr_c);
println("W = ", W');

x=[1:nr_c];
using PyPlot

plot(x,W);




