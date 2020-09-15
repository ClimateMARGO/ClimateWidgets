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

# ╔═╡ dc3ef642-f75e-11ea-0e95-e1c64a6fdbf2
begin
	let
		env = mktempdir()
		import Pkg
		Pkg.activate(env)
		Pkg.Registry.update()
		Pkg.add([
			(;name="PlutoUI", version="0.6.1"),
			(;name = "ClimateMARGO", version="0.1.2"),
			(;name = "Plots", version="1.6.4")
		])
	end
	using Plots
	using ClimateMARGO
	using ClimateMARGO.Models
	using ClimateMARGO.Optimization
	using ClimateMARGO.Diagnostics
	using PlutoUI
	plotly();
end;

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

# ╔═╡ f4ce2bb4-f782-11ea-3d14-29a859a3b5b0
md"#### Interactive plot of climate trajectories and the effects of climate intervention policies"

# ╔═╡ c350e13c-f783-11ea-20c9-850f0b9924c4
@bind panel Select(["temp" => "Temperature", "co2" => "CO₂"])

# ╔═╡ 46e25d84-f6ee-11ea-2f08-af76b3b89fd1
md"""### Running ClimateMARGO.jl"""

# ╔═╡ 5f58784e-f6ee-11ea-1ca7-9fb8b53cd779
begin
	params = deepcopy(ClimateMARGO.IO.included_configurations["default"]);
	m = ClimateModel(params);
end;

# ╔═╡ 04b09746-f6ee-11ea-1cf7-67bab932507e
md"""### Plotting functions"""

# ╔═╡ 3a643e88-f6ee-11ea-2e27-f52e39bd930a
default(linewidth = 2.5)

# ╔═╡ fd18f7d0-f6ed-11ea-2d8a-67901fb687d9
function plot_temperature(m)
	temps_plot = plot(t(m), T(m, M=true, R=true, G=true), fillrange = T(m, M=true, R=true), alpha=0.15, color="red", label=nothing);
	plot!(t(m), T(m, M=true, R=true), fillrange = T(m, M=true), alpha=0.15, color="orange", label=nothing);
	plot!(t(m), T(m, M=true), fillrange = T(m), alpha=0.15, color="blue", label=nothing);
	
	if G; plot!(t(m), T(m, M=true, R=true, G=true), label="T(M,R,G)", color="red"); end
	if R; plot!(t(m), T(m, M=true, R=true), label="T(M,R)", color="orange"); end
	if M; plot!(t(m), T(m, M=true), label="T(M)", color="blue"); end
	plot!(t(m), T(m), label="T", color="black")
	if m.domain.present_year > m.domain.initial_year
		fill_lims = ylims(temps_plot)
		plot!(
			[m.domain.initial_year, m.domain.present_year],
			fill_lims[1]*[1., 1.], fillrange = fill_lims[2]*[1., 1.],
			color="gray", alpha=0.1, label="elapsed time"
		)
	end
	
	plot!(xlabel="Year", ylabel="Temperature [ºC]", xlims=(2015., 2205.))
	plot!(yticks=0.:0.5:10.)
	
	return temps_plot
end;

# ╔═╡ 97507428-f783-11ea-3d77-ef80b23a6c66
function plot_CO2(m)
	co2_plot = plot(t(m), c(m, M=true, R=true), fillrange = c(m, M=true), alpha=0.15, color="orange", label=nothing);
	plot!(t(m), c(m, M=true), fillrange = c(m), alpha=0.15, color="blue", label=nothing);
	
	if R; plot!(t(m), c(m, M=true, R=true), label="c(M,R)", color="orange"); end
	if M; plot!(t(m), c(m, M=true), label="c(M)", color="blue"); end
	plot!(t(m), c(m), label="c", color="black")
	if m.domain.present_year > m.domain.initial_year
		fill_lims = ylims(temps_plot)
		plot!(
			[m.domain.initial_year, m.domain.present_year],
			fill_lims[1]*[1., 1.], fillrange = fill_lims[2]*[1., 1.],
			color="gray", alpha=0.1, label="elapsed time"
		)
	end
	
	plot!(xlabel="Year", ylabel="CO2 [ppm]", xlims=(2015., 2205.))
	
	return co2_plot
end;

# ╔═╡ 8179f4ec-f75d-11ea-26eb-2b9b9267f7b0
md"""Pluto magic below"""

# ╔═╡ e59f9724-f6e8-11ea-2ce8-9714ac41b32c
space = html" ";

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
function custom_optimize!(m)
	max_deploy = Dict(
		"mitigate"=>float(M),
		"remove"=>float(R),
		"geoeng"=>float(G),
		"adapt"=>0.
	)
	optimize_controls!(m, obj_option=obj_option, temp_goal = temp_goal, max_deployment=max_deploy);
end;

# ╔═╡ e021f19e-f6e9-11ea-16fe-7998c8b7ad27
begin
	ρslider = @bind ρ Slider(0:0.1:7.5, default=7.5);
	md"""
	$(space) $(ρslider) [Range: 0% – 7.5%]
	"""
end

# ╔═╡ 1a5d707a-f6ec-11ea-3c1b-5d72658ee2e9
md"""Discount Rate = $(ρ)% """

# ╔═╡ e1284c58-f6eb-11ea-11a8-fb567b481d0c
begin
	βslider = @bind β Slider(0.1:0.1:5., default=0.1);
	md"""
	$(space) $(βslider) [Range: 0% – 5%]
	"""
end
		

# ╔═╡ 754b6738-f6ec-11ea-3b67-cdb4cdd49026

md"""
Cost of climate damages = $(β) % GWP for warming of 3 ºC
"""

# ╔═╡ 41290136-f76b-11ea-086e-678cfac105dc
begin
	if G
		Gcost_slider = @bind Gcost Slider(0.:0.1:30., default=5.);
		md"""
		$(space) $(Gcost_slider) [Range: 0% – 30%]
		"""
	end
end

# ╔═╡ 29a867d2-f6f2-11ea-2bbf-7736f7e08c91
begin
	if G
		md"""
		Cost of solar geoengineering = $(Gcost) % GWP for cooling of 8.5 W/m²
		"""
	end
end

# ╔═╡ e9c8002c-f6ed-11ea-10ae-d3a6ae4b0a13
function update_params!(m)
	m.economics.ρ = float(ρ/100.);
	m.economics.β = float(β/100. /9.)
	if G
		m.economics.geoeng_cost = float(Gcost/100.)
	end
end;

# ╔═╡ 4a836eee-f77d-11ea-07bf-61bc1108d06e
function update_plot!(m)
	update_params!(m);
	custom_optimize!(m);
	if panel == "temp"
		panel_plot = plot_temperature(m);
	elseif panel == "co2"
		panel_plot = plot_CO2(m);
	end
	return panel_plot
end;

# ╔═╡ 501b939a-f75f-11ea-25e1-994d67753d7f
let
	UpdateButton = @bind 🔄 Button("Update 🔄")
	md"""
	The control panel below can be used to step forward of backward in time (make sure to press the "Update" button to update the plot above!
	
	$(space) $(UpdateButton)
	"""
end

# ╔═╡ a1f524c6-f77d-11ea-0ff7-b16c47a77192
let
	ResetButton = @bind reset Button("Reset ↺")
	FFNumberField = @bind Δt NumberField(0:100, default=20)
	FFButton = @bind ⏩ Button("Fast forward ⏩")
	RWButton = @bind ⏪ Button("⏪ Rewind")
	md"""
	$(space) $(ResetButton) $(RWButton) $(FFNumberField) years $(FFButton)
	"""
end

# ╔═╡ 7ce36c32-f777-11ea-10c7-5bd7257cf131
let
	🔄
	⏩
	⏪
	reset
	update_plot!(m)
end

# ╔═╡ 5358754e-f766-11ea-27c5-b946b2495cfa
begin
	reset
	m.domain.present_year = m.domain.initial_year
end;

# ╔═╡ 26d67348-f761-11ea-1acc-8539522de585
begin
	⏩
	ClimateMARGO.PolicyResponse.step_forward!(m, float(Δt));
end;

# ╔═╡ 9efee730-f761-11ea-0454-3f86e1a91359
begin
	⏪
	ClimateMARGO.PolicyResponse.step_forward!(m, float(-Δt));
end;

# ╔═╡ Cell order:
# ╟─dc3ef642-f75e-11ea-0e95-e1c64a6fdbf2
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
# ╟─41290136-f76b-11ea-086e-678cfac105dc
# ╟─f4ce2bb4-f782-11ea-3d14-29a859a3b5b0
# ╟─c350e13c-f783-11ea-20c9-850f0b9924c4
# ╟─7ce36c32-f777-11ea-10c7-5bd7257cf131
# ╟─501b939a-f75f-11ea-25e1-994d67753d7f
# ╟─a1f524c6-f77d-11ea-0ff7-b16c47a77192
# ╟─46e25d84-f6ee-11ea-2f08-af76b3b89fd1
# ╠═5f58784e-f6ee-11ea-1ca7-9fb8b53cd779
# ╠═14fe5804-f6ee-11ea-0971-b747e79dba0e
# ╠═5358754e-f766-11ea-27c5-b946b2495cfa
# ╠═26d67348-f761-11ea-1acc-8539522de585
# ╠═9efee730-f761-11ea-0454-3f86e1a91359
# ╟─04b09746-f6ee-11ea-1cf7-67bab932507e
# ╠═3a643e88-f6ee-11ea-2e27-f52e39bd930a
# ╠═4a836eee-f77d-11ea-07bf-61bc1108d06e
# ╠═fd18f7d0-f6ed-11ea-2d8a-67901fb687d9
# ╠═97507428-f783-11ea-3d77-ef80b23a6c66
# ╠═e9c8002c-f6ed-11ea-10ae-d3a6ae4b0a13
# ╟─8179f4ec-f75d-11ea-26eb-2b9b9267f7b0
# ╠═e59f9724-f6e8-11ea-2ce8-9714ac41b32c
