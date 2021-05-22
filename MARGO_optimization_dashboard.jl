### A Pluto.jl notebook ###
# v0.12.20

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
	import Pkg
	ENV["JULIA_MARGO_LOAD_PYPLOT"] = "no thank you"
	Pkg.activate(".")
	Pkg.instantiate()
	using Plots
	using ClimateMARGO
	using ClimateMARGO.Models
	using ClimateMARGO.Optimization
	using ClimateMARGO.Diagnostics
	using PlutoUI
end;

# ╔═╡ 7cd92dfa-f6ee-11ea-2a62-5de6dc054afe
md"""
# Interactive ClimateMARGO.jl Demo
"""

# ╔═╡ f38a0f5a-f6ee-11ea-28d6-6d93e84f8866
md"""![](https://raw.githubusercontent.com/ClimateMARGO/ClimateMARGO.jl/main/docs/src/MARGO_schematic.png)"""

# ╔═╡ 20a8c93e-f6ef-11ea-326d-ede483bac48b
md"""##### Optimization Method"""

# ╔═╡ 2e2cbeb4-f6ef-11ea-14a1-3d12143db520
@bind obj_option Select(["net_benefit"=>"Cost-Benefit", "adaptive_temp"=>"Temperature Goal"])

# ╔═╡ 6ad1f3d0-f6ee-11ea-12f8-f752047cbeba
md"""##### Allowed controls"""

# ╔═╡ 284638c6-f6e6-11ea-227f-efddfc053eba
begin
	Mslider = @bind M_enabled CheckBox(default=false)
	Rslider = @bind R_enabled CheckBox(default=false)
	Gslider = @bind G_enabled CheckBox(default=false)
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
@bind panel Select([
		"emit" => "CO₂ emissions",
		"co2" => "CO₂ concentrations",
		"temp" => "Temperature change",
		"benefits" => "Economic costs & benefits",
		"discounted_benefits" => "Economic costs & benefits (discounted)",
	])

# ╔═╡ 59af3e1c-f9b1-11ea-3636-f120ef02e6bd
md"""##### Other parameters"""

# ╔═╡ eb837be2-f9b0-11ea-08fa-a3d5e08a7cd2
md"""
##### Advanced options
"""

# ╔═╡ 46e25d84-f6ee-11ea-2f08-af76b3b89fd1
md"""### Running ClimateMARGO.jl"""

# ╔═╡ 5f58784e-f6ee-11ea-1ca7-9fb8b53cd779
begin
	params = deepcopy(ClimateMARGO.IO.included_configurations["default"]);
	m = ClimateModel(params);
end;

# ╔═╡ 5a0750e0-0d12-4b4a-81e4-4605323f055a
Base.@kwdef mutable struct MRGA{T}
	M::T
	R::T
	G::T
	A::T
end

# ╔═╡ 8380e66b-495a-4e90-b3fe-04f2baa58a01
splat(mrga::MRGA) = [:M => mrga.M, :R => mrga.R, :G => mrga.G, :A => mrga.A]

# ╔═╡ 1c8521d2-f9ac-11ea-09d4-b122b4a01b4e
net_emissions(m; M=false, R=false) = effective_emissions(m; M=M, R=R)/m.physics.r;

# ╔═╡ 04b09746-f6ee-11ea-1cf7-67bab932507e
md"""### Plotting functions"""

# ╔═╡ 3a643e88-f6ee-11ea-2e27-f52e39bd930a
default(linewidth = 2.5)

# ╔═╡ fd18f7d0-f6ed-11ea-2d8a-67901fb687d9
function Iplot_temperature(m; enabled::MRGA{Bool})
	temps_plot = plot(t(m), T(m, M=true, R=true, G=true), fillrange = T(m, M=true, R=true), alpha=0.15, color="red", label=nothing);
	plot!(t(m), T(m, M=true, R=true), fillrange = T(m, M=true), alpha=0.15, color="orange", label=nothing);
	plot!(t(m), T(m, M=true), fillrange = T(m), alpha=0.15, color="blue", label=nothing);
	
	if enabled.G; plot!(t(m), T(m, M=true, R=true, G=true), label="T(M,R,G)", color="red"); end
	if enabled.R; plot!(t(m), T(m, M=true, R=true), label="T(M,R)", color="orange"); end
	if enabled.M; plot!(t(m), T(m, M=true), label="T(M)", color="blue"); end
	plot!(t(m), T(m), label="T", color="black")
	if m.domain.present_year > m.domain.initial_year
		fill_lims = ylims(temps_plot)
		plot!(
			[m.domain.initial_year, m.domain.present_year],
			fill_lims[1]*[1., 1.], fillrange = fill_lims[2]*[1., 1.],
			color="gray", alpha=0.1, label="elapsed time"
		)
	end
	
	plot!(xlabel="Year", ylabel="Temperature [ºC]", xlims=(2020., 2200.), ylims=(0., maximum(T(m))*1.1))
	plot!(yticks=0.:0.5:10.)
	
	return temps_plot
end;

# ╔═╡ 97507428-f783-11ea-3d77-ef80b23a6c66
function Iplot_CO2(m; enabled::MRGA{Bool})
	co2_plot = plot(t(m), c(m, M=true, R=true), fillrange = c(m, M=true), alpha=0.15, color="orange", label=nothing);
	plot!(t(m), c(m, M=true), fillrange = c(m), alpha=0.15, color="blue", label=nothing);
	
	if enabled.R; plot!(t(m), c(m, M=true, R=true), label="c(M,R)", color="orange"); end
	if enabled.M; plot!(t(m), c(m, M=true), label="c(M)", color="blue"); end
	plot!(t(m), c(m), label="c", color="black")
	if m.domain.present_year > m.domain.initial_year
		fill_lims = ylims(co2_plot)
		plot!(
			[m.domain.initial_year, m.domain.present_year],
			fill_lims[1]*[1., 1.], fillrange = fill_lims[2]*[1., 1.],
			color="gray", alpha=0.1, label="elapsed time"
		)
	end
	
	plot!(xlabel="Year", ylabel="CO2 [ppm]", xlims=(2020., 2200.))
	
	return co2_plot
end;

# ╔═╡ c93f4636-f9ab-11ea-28e2-8db61df34751
function Iplot_emissions(m; enabled::MRGA{Bool})
	emit_plot = plot(t(m), net_emissions(m, M=true, R=true), fillrange = net_emissions(m, M=true), alpha=0.15, color="orange", label=nothing);
	plot!(t(m), net_emissions(m, M=true), fillrange = net_emissions(m), alpha=0.15, color="blue", label=nothing);
	
	if enabled.R; plot!(t(m), net_emissions(m, M=true, R=true), label="Emissions(M,R)", color="orange"); end
	if enabled.M; plot!(t(m), net_emissions(m, M=true), label="Emissions(M)", color="blue"); end
	plot!(t(m), net_emissions(m), label="Emissions", color="black")
	if m.domain.present_year > m.domain.initial_year
		fill_lims = ylims(emit_plot)
		plot!(
			[m.domain.initial_year, m.domain.present_year],
			fill_lims[1]*[1., 1.], fillrange = fill_lims[2]*[1., 1.],
			color="gray", alpha=0.1, label="elapsed time"
		)
	end
	
	plot!(xlabel="Year", ylabel="Net emissions [ppm/year]", xlims=(2020., 2200.))
	
	return emit_plot
end;

# ╔═╡ bc328530-f9ac-11ea-3f7a-8b8cc013c856
function Iplot_benefits(m; enabled::MRGA{Bool}, discounting=false)
	A=false
	benefit_plot = plot(t(m), -cost(m; discounting=discounting, splat(enabled)...), label="Economic losses from control policies", color="red");
	plot!(t(m), benefit(m; discounting=discounting, splat(enabled)...), label="Damages avoided due to control policies", color="blue");
	plot!(t(m), net_benefit(m; discounting=discounting, splat(enabled)...), label="Net benefits of control policies", color="black")
	
	if discounting
		plot!(t(m), 0. .* net_benefit(m; discounting=discounting, splat(enabled)...), fillrange = net_benefit(m, discounting=discounting, splat(enabled)...), alpha=0.12, color="black", label="Area = Net Present Benefits");
	end
	max_cost = maximum(cost(m; discounting=discounting, splat(enabled)...))*1.3
	plot!(ylims=(-max_cost,max_cost*5.))
	if m.domain.present_year > m.domain.initial_year
		fill_lims = ylims(benefit_plot)
		plot!(
			[m.domain.initial_year, m.domain.present_year],
			fill_lims[1]*[1., 1.], fillrange = fill_lims[2]*[1., 1.],
			color="gray", alpha=0.1, label="elapsed time"
		)
	end
	
	plot!(xlabel="Year", ylabel="Economics benefits [trillion US\$]", xlims=xlims=(2020., 2200.))
	
	return benefit_plot
end;

# ╔═╡ 8179f4ec-f75d-11ea-26eb-2b9b9267f7b0
md"""Pluto magic below"""

# ╔═╡ e59f9724-f6e8-11ea-2ce8-9714ac41b32c
space = html" ";

# ╔═╡ b2815710-f6ef-11ea-0e7d-19c53be305bc
begin
	if obj_option=="adaptive_temp"
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
	if obj_option=="adaptive_temp"
		md"""Temperature Goal = $(temp_goal) ºC"""
	end
end

# ╔═╡ 14fe5804-f6ee-11ea-0971-b747e79dba0e
function custom_optimize!(m; enabled::MRGA{Bool})
	max_deploy = Dict(
		"mitigate"=>float(enabled.M),
		"remove"=>float(enabled.R),
		"geoeng"=>float(enabled.G),
		"adapt"=>0.
	)
	optimize_controls!(m, obj_option=obj_option, temp_goal = temp_goal, max_deployment=max_deploy);
end;

# ╔═╡ e1284c58-f6eb-11ea-11a8-fb567b481d0c
begin
	βslider = @bind β Slider(0.2:0.2:10., default=0.2);
	md"""
	$(space) $(βslider) [Range: 0% – 10%]
	"""
end
		

# ╔═╡ 754b6738-f6ec-11ea-3b67-cdb4cdd49026

md"""
Cost of climate damages = $(β) % GWP for warming of 3 ºC
"""

# ╔═╡ 9caa5db6-f9b1-11ea-1916-df297297d41e
begin
	ρslider = @bind ρ Slider(0:0.25:7.5, default=2.);
	md"""
	$(space) $(ρslider) [Range: 0% – 7.5%]
	"""
end

# ╔═╡ 77a3fcaa-f9b1-11ea-1a1e-5d4fc30691ae
md"""Discount Rate = $(ρ)% """

# ╔═╡ e9c8002c-f6ed-11ea-10ae-d3a6ae4b0a13
function update_params!(m; enabled::MRGA{Bool}, cost::MRGA{<:Real})
	m.economics.ρ = float(ρ/100.);
	m.economics.β = float(β/100. /9.)
	if enabled.G
		m.economics.geoeng_cost = float(cost.G/100.)
	end
	if enabled.R
		m.economics.remove_cost = float(
			(cost.R*ClimateMARGO.Utils.ppm_to_tCO2(emissions(m))[1]/1e12)/2.
		)
	end
	if enabled.M
		m.economics.mitigate_cost = float(cost.M*1.e9/1.e12)
	end
end;

# ╔═╡ 4a836eee-f77d-11ea-07bf-61bc1108d06e
function update_plot!(m; enabled::MRGA{Bool}, cost::MRGA{Float64})
	update_params!(m; enabled=enabled, cost=cost);
	custom_optimize!(m; enabled=enabled);
	if panel == "temp"
		panel_plot = Iplot_temperature(m; enabled=enabled);
	elseif panel == "co2"
		panel_plot = Iplot_CO2(m; enabled=enabled);
	elseif panel == "emit"
		panel_plot = Iplot_emissions(m; enabled=enabled);
	elseif panel == "benefits"
		panel_plot = Iplot_benefits(m; enabled=enabled);
	elseif panel == "discounted_benefits"
		panel_plot = Iplot_benefits(m, discounting=true, enabled=enabled);
	end
	return panel_plot
end;

# ╔═╡ 11e7a3e8-f9b2-11ea-083c-65c28fe60aa1
begin
	Mcost_slider = @bind M_cost Slider(0.:1:200., default=70);
	if M_enabled
		md"""
		$(space) $(Mcost_slider) [Range: 0 USD – 200 USD]
		"""
	end
end

# ╔═╡ a21b07a8-f9b1-11ea-394a-e58c37684104
begin
	if M_enabled
		md"""
		Marginal cost of emissions mitigation (at 100%) = $(M_cost) USD per ton of CO₂
		"""
	end
end

# ╔═╡ 61ead2de-592d-11eb-06de-f978f23c1eac
begin
	Rcost_slider = @bind R_cost Slider(0.:1:700., default=700);
	if R_enabled
		md"""
		$(space) $(Rcost_slider) [Range: 0 USD – 700 USD]
		"""
	end
end

# ╔═╡ 503cde1c-592d-11eb-3248-c335b71693eb
begin
	if R_enabled
		md"""
		Marginal cost of carbon dioxide removal (at 100%) = $(R_cost) USD per ton of CO₂
		"""
	end
end

# ╔═╡ 5939d712-f9b1-11ea-2634-13c74b486efc
begin
	Gcost_slider = @bind G_cost Slider(0.:0.5:30., default=30.);
	if G_enabled
		md"""
		$(space) $(Gcost_slider) [Range: 0% – 30%]
		"""
	end
end

# ╔═╡ 739be53c-f9b1-11ea-249f-6bdd08a2c521
begin
	if G_enabled
		md"""
		Cost of solar geoengineering = $(G_cost) % GWP for cooling of 8.5 W/m²
		"""
	end
end

# ╔═╡ a1f524c6-f77d-11ea-0ff7-b16c47a77192
let
	ResetButton = @bind 🔄 Button("Reset 🔄")
	FFNumberField = @bind Δt NumberField(0:100, default=20)
	FFButton = @bind ⏩ Button("Fast forward ⏩")
	RWButton = @bind ⏪ Button("⏪ Rewind")
	md"""
	$(space) $(ResetButton) $(RWButton) $(FFNumberField) years $(FFButton)
	"""
end

# ╔═╡ 5358754e-f766-11ea-27c5-b946b2495cfa
begin
	🔄
	🔄trigger = nothing
	m.domain.present_year = m.domain.initial_year
end;

# ╔═╡ 26d67348-f761-11ea-1acc-8539522de585
begin
	⏩
	⏩trigger = nothing
	ClimateMARGO.PolicyResponse.step_forward!(m, float(Δt));
end;

# ╔═╡ 9efee730-f761-11ea-0454-3f86e1a91359
begin
	⏪
	⏪trigger = nothing
	ClimateMARGO.PolicyResponse.step_forward!(m, float(-Δt));
end;

# ╔═╡ 7ce36c32-f777-11ea-10c7-5bd7257cf131
let
	🔄trigger
	⏩trigger
	⏪trigger
	
	enabled = MRGA{Bool}(M_enabled, R_enabled, G_enabled, false)
	cost = MRGA{Float64}(M_cost, R_cost, G_cost, 1.0)
	update_plot!(m; enabled=enabled, cost=cost)
end

# ╔═╡ Cell order:
# ╠═dc3ef642-f75e-11ea-0e95-e1c64a6fdbf2
# ╟─7cd92dfa-f6ee-11ea-2a62-5de6dc054afe
# ╟─f38a0f5a-f6ee-11ea-28d6-6d93e84f8866
# ╟─20a8c93e-f6ef-11ea-326d-ede483bac48b
# ╟─2e2cbeb4-f6ef-11ea-14a1-3d12143db520
# ╟─7f87ab16-f6ef-11ea-043e-8939edfd0554
# ╟─b2815710-f6ef-11ea-0e7d-19c53be305bc
# ╟─6ad1f3d0-f6ee-11ea-12f8-f752047cbeba
# ╟─284638c6-f6e6-11ea-227f-efddfc053eba
# ╟─22434c36-f6ec-11ea-1932-09049deed9c1
# ╟─754b6738-f6ec-11ea-3b67-cdb4cdd49026
# ╟─e1284c58-f6eb-11ea-11a8-fb567b481d0c
# ╟─f4ce2bb4-f782-11ea-3d14-29a859a3b5b0
# ╟─c350e13c-f783-11ea-20c9-850f0b9924c4
# ╟─7ce36c32-f777-11ea-10c7-5bd7257cf131
# ╟─59af3e1c-f9b1-11ea-3636-f120ef02e6bd
# ╟─77a3fcaa-f9b1-11ea-1a1e-5d4fc30691ae
# ╟─9caa5db6-f9b1-11ea-1916-df297297d41e
# ╟─a21b07a8-f9b1-11ea-394a-e58c37684104
# ╟─11e7a3e8-f9b2-11ea-083c-65c28fe60aa1
# ╟─503cde1c-592d-11eb-3248-c335b71693eb
# ╟─61ead2de-592d-11eb-06de-f978f23c1eac
# ╟─739be53c-f9b1-11ea-249f-6bdd08a2c521
# ╟─5939d712-f9b1-11ea-2634-13c74b486efc
# ╟─eb837be2-f9b0-11ea-08fa-a3d5e08a7cd2
# ╟─a1f524c6-f77d-11ea-0ff7-b16c47a77192
# ╟─46e25d84-f6ee-11ea-2f08-af76b3b89fd1
# ╠═5f58784e-f6ee-11ea-1ca7-9fb8b53cd779
# ╠═14fe5804-f6ee-11ea-0971-b747e79dba0e
# ╠═5358754e-f766-11ea-27c5-b946b2495cfa
# ╠═26d67348-f761-11ea-1acc-8539522de585
# ╠═9efee730-f761-11ea-0454-3f86e1a91359
# ╠═e9c8002c-f6ed-11ea-10ae-d3a6ae4b0a13
# ╠═5a0750e0-0d12-4b4a-81e4-4605323f055a
# ╠═8380e66b-495a-4e90-b3fe-04f2baa58a01
# ╠═1c8521d2-f9ac-11ea-09d4-b122b4a01b4e
# ╟─04b09746-f6ee-11ea-1cf7-67bab932507e
# ╠═3a643e88-f6ee-11ea-2e27-f52e39bd930a
# ╠═4a836eee-f77d-11ea-07bf-61bc1108d06e
# ╠═fd18f7d0-f6ed-11ea-2d8a-67901fb687d9
# ╠═97507428-f783-11ea-3d77-ef80b23a6c66
# ╠═c93f4636-f9ab-11ea-28e2-8db61df34751
# ╠═bc328530-f9ac-11ea-3f7a-8b8cc013c856
# ╟─8179f4ec-f75d-11ea-26eb-2b9b9267f7b0
# ╠═e59f9724-f6e8-11ea-2ce8-9714ac41b32c
