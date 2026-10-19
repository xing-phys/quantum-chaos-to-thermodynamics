#!/usr/bin/env julia
# Original numerical illustrations. Run from any directory with --project=.
using LinearAlgebra, Random, Statistics, CairoMakie
BLAS.set_num_threads(1)
Random.seed!(20261019)
const ROOT = dirname(@__DIR__)
mkpath(joinpath(ROOT, "figs")); mkpath(joinpath(ROOT, "data"))
set_theme!(Theme(fontsize=17, linewidth=2.5, backgroundcolor=:white))
const BLUE = "#235789"
const ORANGE = "#c55a22"
function exportfig(name, f)
    save(joinpath(ROOT,"figs",name*".png"), f; px_per_unit=2)
    save(joinpath(ROOT,"figs",name*".pdf"), f)
end
function table(name, header, columns...)
    open(joinpath(ROOT,"data",name*".tsv"),"w") do io
        println(io,join(header,'\t'))
        for row in zip(columns...); println(io,join(row,'\t')); end
    end
end

# GOE with radius 2 semicircle, unfolded using its ensemble density.
goe = Float64[]
for trial in 1:25
    n=350; X=randn(n,n); E=eigvals(Symmetric((X+X')/sqrt(2n)))
    bulk=E[71:280]
    F(x)=0.5+(x*sqrt(max(0,4-x*x))/4+asin(clamp(x/2,-1,1)))/pi
    append!(goe,diff(n .* F.(bulk)))
end
goe ./= mean(goe)
poisson=randexp(length(goe))
f=Figure(size=(950,410))
ax=Axis(f[1,1],xlabel="Unfolded spacing s",ylabel="Probability density",title="Level repulsion in a GOE ensemble")
hist!(ax,goe; bins=0:0.12:(ceil(maximum(goe)/.12)*.12),normalization=:pdf,color=(BLUE,.55),label="GOE sample")
s=range(0,3.6,length=350)
lines!(ax,s,pi/2 .* s .* exp.(-pi/4 .* s.^2);color=ORANGE,label="GOE Wigner surmise")
lines!(ax,s,exp.(-s);color=:black,linestyle=:dash,label="Poisson: exp(−s)")
xlims!(ax,0,3.6); axislegend(ax;position=:rt,labelsize=13)
ax2=Axis(f[1,2],xlabel="Unfolded spacing s",ylabel="Probability density",title="Independent Poisson spacings")
hist!(ax2,poisson;bins=0:0.12:(ceil(maximum(poisson)/.12)*.12),normalization=:pdf,color=(ORANGE,.5))
lines!(ax2,s,exp.(-s);color=:black);xlims!(ax2,0,3.6)
exportfig("level-statistics",f)
table("spacings",["goe_s","poisson_s"],goe,poisson)

# Dense exact diagonalization. Site 1 is the least significant bit.
L=9; D=2^L; H=zeros(D,D); diagz=zeros(D)
for state in 0:D-1
    z=[iszero(state & (1<<(i-1))) ? 1.0 : -1.0 for i in 1:L]
    H[state+1,state+1]=-sum(z[i]*z[i+1] for i in 1:L-1)-sum((.35+.07i)*z[i] for i in 1:L)
    diagz[state+1]=z[(L+1)÷2]
    for i in 1:L; H[(state ⊻ (1<<(i-1)))+1,state+1]=-1.05; end
end
@assert ishermitian(H)
spec=eigen(Symmetric(H)); E=spec.values; V=spec.vectors
Ann=vec(sum(abs2.(V).*diagz,dims=1))
eligible=findall(==(1.0),diagz)
initial=eligible[argmin(abs.(diag(H)[eligible].-mean(E)))]
c=V[initial,:]; p=abs2.(c); E0=dot(p,E)
Ade=dot(p,Ann); shell=findall(abs.(E.-E0).<.8); Amc=mean(Ann[shell])
times=collect(range(0,45,length=451))
At=[sum(diagz .* abs2.(V*(c.*exp.(-im.*E.*t)))) for t in times]
@assert abs(sum(p)-1)<1e-12
@assert abs(E0-H[initial,initial])<1e-10
@assert abs(At[1]-1)<1e-10
@assert norm(H*V-V*Diagonal(E))/norm(H)<1e-12
Anm=V'*(diagz.*V)
variance=sum(p[m]*p[n]*abs2(Anm[m,n]) for m in 1:D for n in 1:D if m!=n)
f=Figure(size=(1000,420))
ax=Axis(f[1,1],xlabel="Eigenenergy Eₙ",ylabel="⟨n|Z₅|n⟩",title="A local observable in a finite chain")
scatter!(ax,E,Ann;markersize=4.5,color=(BLUE,.7))
vlines!(ax,[E0];color=ORANGE,linestyle=:dash)
ax2=Axis(f[1,2],xlabel="Time (ℏ/J)",ylabel="⟨Z₅(t)⟩",title="Product-state quench, L = 9")
lines!(ax2,times,At;color=BLUE,label="Unitary dynamics")
hlines!(ax2,[Ade];color=ORANGE,label="Diagonal ensemble")
hlines!(ax2,[Amc];color=:black,linestyle=:dash,label="Microcanonical shell")
axislegend(ax2;labelsize=12,position=:rt)
exportfig("eth-quench",f)
table("eigenstates",["energy","Z5","initial_probability"],E,Ann,p)
table("quench",["time","Z5"],times,At)
open(joinpath(ROOT,"data","diagnostics.txt"),"w") do io
    for (k,v) in ("seed"=>20261019,"L"=>L,"D"=>D,"initial_basis_index_zero_based"=>initial-1,"E0"=>E0,"DE_Z5"=>Ade,"MC_Z5"=>Amc,"MC_shell_count"=>length(shell),"energy_width"=>sqrt(dot(p,E.^2)-E0^2),"effective_dimension"=>1/sum(p.^2),"gap_nondegenerate_variance_formula"=>variance)
        println(io,k," = ",v)
    end
end

# Standard map on the two-torus. Same initial conditions in both panels.
f=Figure(size=(940,440))
for (col,K) in enumerate((.2,5.0))
    local ax=Axis(f[1,col],xlabel="Angle θ",ylabel="Momentum p mod 2π",title="Standard map: K = $K")
    for trajectory in 1:9
        theta=2pi*trajectory/10; momentum=2pi*(trajectory*.61803398875%1)
        xs=Float64[]; ys=Float64[]
        for step in 1:1800
            momentum=mod(momentum+K*sin(theta),2pi);theta=mod(theta+momentum,2pi)
            push!(xs,theta); push!(ys,momentum)
        end
        scatter!(ax,xs,ys;markersize=1.1)
    end
    xlims!(ax,0,2pi);ylims!(ax,0,2pi)
end
exportfig("standard-map",f)

# Analytic similarity profile of a specified Fokker--Planck model.
# d=3, S(E)=0.5 log(E), B(E)=E^(3/2), A(E)=sqrt(E).
# The entrance-law solution has x=sqrt(E) ~ Gamma(shape=3,scale=t/8).
f=Figure(size=(940,410))
ax=Axis(f[1,1],xlabel="Energy E",ylabel="P(E,t)",title="Energy diffusion: analytic similarity profiles")
energy=collect(range(.0001,35,length=1400))
for t in (2.,4.,8.)
    scale=t/8; density=sqrt.(energy).*exp.(-sqrt.(energy)./scale)./(4scale^3)
    lines!(ax,energy,density;label="t = $(Int(t))")
end
xlims!(ax,0,18);ylims!(ax,0,1.5);axislegend(ax;labelsize=13)
ax2=Axis(f[1,2],xlabel="Energy fraction u = E₁/Etotal",ylabel="Probability density",title="Two finite systems: equilibrium sharing")
u=collect(range(0,1,length=501)); density=30 .* u.^2 .* (1 .-u).^2
lines!(ax2,u,density;color=BLUE,label="P(u) = 30u²(1−u)²")
axislegend(ax2;labelsize=12,position=:ct)
exportfig("heating",f)
table("energy-sharing",["energy_fraction","density"],u,density)
println("Generated 4 original figures in PNG/PDF, raw data, and diagnostics.")
println(read(joinpath(ROOT,"data","diagnostics.txt"),String))
