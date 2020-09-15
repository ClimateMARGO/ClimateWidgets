### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 16528aa4-f6ee-11ea-3e81-0b0fc6b61517
begin
	using ClimateMARGO
	using ClimateMARGO.Models
	using ClimateMARGO.Optimization
	using ClimateMARGO.Diagnostics
	
	using Plots;
	plotly();
end;

# ╔═╡ e6070712-f6e8-11ea-10e9-9763c9041ff0
begin
	let
		env = mktempdir()
		import Pkg
		Pkg.activate(env)
		Pkg.Registry.update()
		Pkg.add(Pkg.PackageSpec(;name="PlutoUI", version=v"0.6.1"))
	end
	using PlutoUI
end

# ╔═╡ 7cd92dfa-f6ee-11ea-2a62-5de6dc054afe
md"""
# Interactive ClimateMARGO.jl Demo
"""

# ╔═╡ f38a0f5a-f6ee-11ea-28d6-6d93e84f8866
md"""![](https://raw.githubusercontent.com/hdrake/ClimateMARGO.jl/master/docs/src/MARGO_schematic.png)"""

# ╔═╡ 20a8c93e-f6ef-11ea-326d-ede483bac48b
md"""##### Optimization Method"""

# ╔═╡ 2e2cbeb4-f6ef-11ea-14a1-3d12143db520
@bind obj_option Select(["net_benefit"=>"Cost-Benefit", "temp"=>"Temperature Goal"])

# ╔═╡ 6ad1f3d0-f6ee-11ea-12f8-f752047cbeba
md"""##### Allowed controls"""

# ╔═╡ 284638c6-f6e6-11ea-227f-efddfc053eba
begin
	Mslider = @bind M CheckBox(default=false)
	Rslider = @bind R CheckBox(default=false)
	Gslider = @bind G CheckBox(default=false)
	md"""
	`Mitigation ` $(Mslider); 
	`Removal ` $(Rslider); 
	`Solar-geoengineering ` $(Gslider)
	"""
end

# ╔═╡ 22434c36-f6ec-11ea-1932-09049deed9c1
md"""##### Set parameter values"""

# ╔═╡ 46e25d84-f6ee-11ea-2f08-af76b3b89fd1
md"""### Running ClimateMARGO.jl"""

# ╔═╡ 5f58784e-f6ee-11ea-1ca7-9fb8b53cd779
begin
	params = deepcopy(ClimateMARGO.IO.included_configurations["default"]);
	m = ClimateModel(params);
end

# ╔═╡ 04b09746-f6ee-11ea-1cf7-67bab932507e
md"""### Plotting functions"""

# ╔═╡ 3a643e88-f6ee-11ea-2e27-f52e39bd930a
default(linewidth = 2.5)

# ╔═╡ fd18f7d0-f6ed-11ea-2d8a-67901fb687d9
function plot_temperature(m)
	temps_plot = plot(t(m), T(m, M=true, R=true, G=true), fillrange = T(m, M=true, R=true), alpha=0.15, color="red", label=nothing);
	plot!(t(m), T(m, M=true, R=true), fillrange = T(m, M=true), alpha=0.15, color="orange", label=nothing);
	plot!(t(m), T(m, M=true), fillrange = T(m), alpha=0.15, color="blue", label=nothing);
	
	if G; plot!(t(m), T(m, M=true, R=true, G=true), label="T_MRG", color="red"); end
	if R; plot!(t(m), T(m, M=true, R=true), label="T_MR", color="orange"); end
	if M; plot!(t(m), T(m, M=true), label="T_M", color="blue"); end
	plot!(t(m), T(m), label="T", color="black")
	return temps_plot
end

# ╔═╡ 02a063d2-f6ee-11ea-3972-1f4ab784fccd
function label_plot()
	plot!(xlabel="Year", ylabel="Temperature [ºC]", xlims=(2020., 2205.))
	plot!(yticks=0.:0.5:10.)
end

# ╔═╡ e59f9724-f6e8-11ea-2ce8-9714ac41b32c
space = html" "

# ╔═╡ b2815710-f6ef-11ea-0e7d-19c53be305bc
begin
	if obj_option=="temp"
		temp_slider = @bind temp_goal Slider(1.5:0.1:3., default=2.);
		md"""
		$(space) $(temp_slider) [Range: 1.5 ºC – 3 ºC]
		"""
	else
		temp_goal = 2.;
		print("")
	end
end

# ╔═╡ 7f87ab16-f6ef-11ea-043e-8939edfd0554
begin
	if obj_option=="temp"
		md"""Temperature Goal = $(temp_goal) ºC"""
	end
end

# ╔═╡ 14fe5804-f6ee-11ea-0971-b747e79dba0e
function custom_optimize(m)
	max_deploy = Dict(
		"mitigate"=>float(M),
		"remove"=>float(R),
		"geoeng"=>float(G),
		"adapt"=>0.
	)
	raw_stats = optimize_controls!(m, obj_option=obj_option, temp_goal = temp_goal, max_deployment=max_deploy);
	return raw_stats
end;

# ╔═╡ e021f19e-f6e9-11ea-16fe-7998c8b7ad27
begin
	ρslider = @bind ρ Slider(0:0.1:7.5, default=1.);
	md"""
	$(space) $(ρslider) [Range: 0% – 7.5%]
	"""
end

# ╔═╡ 1a5d707a-f6ec-11ea-3c1b-5d72658ee2e9
md"""Discount Rate = $(ρ)% """

# ╔═╡ e1284c58-f6eb-11ea-11a8-fb567b481d0c
begin
	βslider = @bind β Slider(0.:0.1:5., default=2.);
	md"""
	$(space) $(βslider) [Range: 0% – 5%]
	"""
end
		

# ╔═╡ 754b6738-f6ec-11ea-3b67-cdb4cdd49026

md"""
Cost of climate damages = $(β) % GWP for warming of 3 ºC
"""

# ╔═╡ 23ba5204-f6f2-11ea-3153-f5cbb18bd2e2
begin
	Gcost_slider = @bind Gcost Slider(0.:0.1:20., default=5.0);
	md"""
	$(space) $(Gcost_slider) [Range: 0% – 20%]
	"""
end
		

# ╔═╡ 29a867d2-f6f2-11ea-2bbf-7736f7e08c91
md"""
Cost of solar geoengineering = $(Gcost) % GWP for cooling of 8.5 W/m²
"""

# ╔═╡ e9c8002c-f6ed-11ea-10ae-d3a6ae4b0a13
function update_params(m)
	m.economics.ρ = float(ρ/100.);
	m.economics.β = float(β/100. /9.)
	m.economics.geoeng_cost = float(Gcost/100.)
end;

# ╔═╡ 745635be-f6bd-11ea-0626-01b08e16d843
begin
	update_params(m);
	raw_stats = custom_optimize(m);
	plot_temperature(m);
	label_plot();
end

# ╔═╡ Cell order:
# ╟─7cd92dfa-f6ee-11ea-2a62-5de6dc054afe
# ╟─f38a0f5a-f6ee-11ea-28d6-6d93e84f8866
# ╟─20a8c93e-f6ef-11ea-326d-ede483bac48b
# ╟─2e2cbeb4-f6ef-11ea-14a1-3d12143db520
# ╟─7f87ab16-f6ef-11ea-043e-8939edfd0554
# ╟─b2815710-f6ef-11ea-0e7d-19c53be305bc
# ╟─6ad1f3d0-f6ee-11ea-12f8-f752047cbeba
# ╟─284638c6-f6e6-11ea-227f-efddfc053eba
# ╟─22434c36-f6ec-11ea-1932-09049deed9c1
# ╟─1a5d707a-f6ec-11ea-3c1b-5d72658ee2e9
# ╟─e021f19e-f6e9-11ea-16fe-7998c8b7ad27
# ╟─754b6738-f6ec-11ea-3b67-cdb4cdd49026
# ╟─e1284c58-f6eb-11ea-11a8-fb567b481d0c
# ╟─29a867d2-f6f2-11ea-2bbf-7736f7e08c91
# ╟─23ba5204-f6f2-11ea-3153-f5cbb18bd2e2
# ╠═745635be-f6bd-11ea-0626-01b08e16d843
# ╟─46e25d84-f6ee-11ea-2f08-af76b3b89fd1
# ╠═16528aa4-f6ee-11ea-3e81-0b0fc6b61517
# ╠═5f58784e-f6ee-11ea-1ca7-9fb8b53cd779
# ╠═14fe5804-f6ee-11ea-0971-b747e79dba0e
# ╟─04b09746-f6ee-11ea-1cf7-67bab932507e
# ╠═3a643e88-f6ee-11ea-2e27-f52e39bd930a
# ╠═fd18f7d0-f6ed-11ea-2d8a-67901fb687d9
# ╠═02a063d2-f6ee-11ea-3972-1f4ab784fccd
# ╠═e9c8002c-f6ed-11ea-10ae-d3a6ae4b0a13
# ╠═e6070712-f6e8-11ea-10e9-9763c9041ff0
# ╠═e59f9724-f6e8-11ea-2ce8-9714ac41b32c
