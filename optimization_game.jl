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
	import Pkg
	Pkg.activate(".")
	Pkg.add("Interpolations")
	using Plots
	using ClimateMARGO
	using ClimateMARGO.Models
	using ClimateMARGO.Optimization
	using ClimateMARGO.Diagnostics
	using PlutoUI
	using Interpolations
end;

# ╔═╡ 7cd92dfa-f6ee-11ea-2a62-5de6dc054afe
md"""
# Interactive ClimateMARGO.jl Demo
"""

# ╔═╡ f38a0f5a-f6ee-11ea-28d6-6d93e84f8866
md"""![](https://raw.githubusercontent.com/hdrake/ClimateMARGO.jl/master/docs/src/MARGO_schematic.png)"""

# ╔═╡ f4ce2bb4-f782-11ea-3d14-29a859a3b5b0
md"""#### Interactive plot of climate trajectories and the effects of climate intervention policies

Use the sliders below to customize climate policy!

The first row controls the level and timing of the maximum emissions mitigation (as a percentage of the emissions in that year). The second row controls the level and timing of the maximum carbon dioxide removal (as a percentage of 2020 emissions which are sequestered annually).

The drop down menu lets you switch between viewing the 1) controls, 2) CO₂ emissions, 3) CO₂ concentrations, 4) globally-averaged temperature change, and 5) costs and benefits.
"""

# ╔═╡ c350e13c-f783-11ea-20c9-850f0b9924c4
@bind panel Select([
		"controls" => "Controls",
		"emit" => "CO₂ emissions",
		"co2" => "CO₂ concentrations",
		"temp" => "Temperature change",
		"benefits" => "Economic costs & benefits",
		"discounted_benefits" => "Economic costs & benefits (discounted)",
	])

# ╔═╡ 4dfdbcdc-004c-11eb-16d2-3dd3c1f7c4c4
md"""
The net present benefits (relative to a no-policy baseline) are shown in the top left corner of the "Controls" view and represent the value over all time. For what settings of the controls are you able to maximize net present benefits?

Once you are happy with your policies, reveal the "optimal" solution using the drop-down menu!
"""

# ╔═╡ 968be15e-0049-11eb-2449-3df90fd001a7
function gauss(h, t, t0; w=50.)
	return h * exp.(-(t .- t0).^2 / w^2)
end;

# ╔═╡ 46e25d84-f6ee-11ea-2f08-af76b3b89fd1
md"""### Running ClimateMARGO.jl"""

# ╔═╡ 8535b8ba-0047-11eb-3b34-5dd347543631
begin
	M=true;
	R=true;
	G=false;
	A=false;
	max_deploy = Dict(
		"mitigate"=>float(M),
		"remove"=>float(R),
		"geoeng"=>float(G),
		"adapt"=>float(A)
	)
	delay_deployment = Dict(
		"mitigate"=>0.,
		"remove"=>0.,
		"geoeng"=>0.,
		"adapt"=>0.,
	)
end;

# ╔═╡ 5f58784e-f6ee-11ea-1ca7-9fb8b53cd779
begin
	params = deepcopy(ClimateMARGO.IO.included_configurations["default"]);
	mopt = ClimateModel(params);
	m = ClimateModel(params);
end;

# ╔═╡ 14fe5804-f6ee-11ea-0971-b747e79dba0e
function custom_optimize!(m)
	🔄 = nothing
	optimize_controls!(
		m, obj_option="net_benefit",
		max_deployment=max_deploy, delay_deployment=delay_deployment
	);
	return 🔄
end;

# ╔═╡ 01d7d08e-005d-11eb-2664-2b246ec2d520
🔄 = custom_optimize!(m);

# ╔═╡ 04b09746-f6ee-11ea-1cf7-67bab932507e
md"""### Plotting functions"""

# ╔═╡ 3a643e88-f6ee-11ea-2e27-f52e39bd930a
default(linewidth = 2.5)

# ╔═╡ fd18f7d0-f6ed-11ea-2d8a-67901fb687d9
function Iplot_temperature()
	temps_plot = plot(t(m), T(m, M=true, R=true, G=true), fillrange = T(m, M=true, R=true), alpha=0.15, color="red", label=nothing);
	plot!(t(m), T(m, M=true, R=true), fillrange = T(m, M=true), alpha=0.15, color="orange", label=nothing);
	plot!(t(m), T(m, M=true), fillrange = T(m), alpha=0.15, color="blue", label=nothing);
	
	plot!(t(m), T(m, M=true, R=true), label="T(M,R)", color="orange")
	plot!(t(m), T(m, M=true), label="T(M)", color="blue")
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
function Iplot_CO2()
	co2_plot = plot(t(m), c(m, M=true, R=true), fillrange = c(m, M=true), alpha=0.15, color="orange", label=nothing);
	plot!(t(m), c(m, M=true), fillrange = c(m), alpha=0.15, color="blue", label=nothing);
	
	plot!(t(m), c(m, M=true, R=true), label="c(M,R)", color="orange")
	plot!(t(m), c(m, M=true), label="c(M)", color="blue")
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

# ╔═╡ 1c8521d2-f9ac-11ea-09d4-b122b4a01b4e
net_emissions(m; M=false, R=false) = effective_emissions(m; M=M, R=R)/m.physics.r;

# ╔═╡ 35d675ba-004a-11eb-3083-ad10120d98d2
function Iplot_emissions()
	emit_plot = plot(t(m), net_emissions(m, M=true, R=true), fillrange = net_emissions(m, M=true), alpha=0.15, color="orange", label=nothing);
	plot!(t(m), net_emissions(m, M=true), fillrange = net_emissions(m), alpha=0.15, color="blue", label=nothing);
	
	plot!(t(m), net_emissions(m, M=true, R=true), label="Emissions(M,R)", color="orange")
	plot!(t(m), net_emissions(m, M=true), label="Emissions(M)", color="blue")
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
function Iplot_benefits(; discounting=false)
	benefit_plot = plot(t(m), -cost(m, discounting=discounting, M=M, R=R, G=G, A=A), label="Economic losses from control policies", color="red");
	plot!(t(m), benefit(m, discounting=discounting, M=M, R=R, G=G, A=A), label="Damages avoided due to control policies", color="blue");
	plot!(t(m), net_benefit(m, discounting=discounting, M=M, R=R, G=G, A=A), label="Net benefits of control policies", color="black")
	
	if discounting
		plot!(t(m), 0. .* net_benefit(m, discounting=discounting, M=M, R=R, G=G, A=A), fillrange = net_benefit(m, discounting=discounting, M=M, R=R, G=G, A=A), alpha=0.12, color="black", label="Area = Net Present Benefits");
	end
	max_cost = maximum(cost(m, discounting=discounting, M=M, R=R, G=G, A=A))*1.3
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

# ╔═╡ edd01696-0048-11eb-1e9a-5b3f2e079b2b
begin
	t_M_slider = @bind t_M Slider(2020:5:2200, default=2100.);
	h_M_slider = @bind h_M Slider(0:0.05:1., default=0.);

	t_R_slider = @bind t_R Slider(2020:5:2200, default=2150);
	h_R_slider = @bind h_R Slider(0:0.05:1., default=0.);
	
	md"""
	$(space) Mitigation $(h_M_slider) [0% – 100%];
	$(space) Timing $(t_M_slider) [2020 – 2200]

	$(space) CO₂ removal $(h_R_slider) [0% – 100%];
	$(space) Timing $(t_R_slider) [2020 – 2200]
	"""
end

# ╔═╡ c912442c-0049-11eb-1cce-2bf1e879b468
function custom_user!(m)
	🔄
	Mmax, Mi = findmax(copy(mopt.controls.mitigate))
	Mitp = extrapolate(interpolate(
		(collect(t(mopt)) .- t(mopt)[Mi],),
		mopt.controls.mitigate/Mmax,
		Gridded(Linear())
	), 0.)
	Rmax, Ri = findmax(copy(mopt.controls.remove))
	Ritp = extrapolate(interpolate(
		(collect(t(mopt)) .- t(mopt)[Ri],),
		mopt.controls.remove/Rmax,
		Gridded(Linear())
	), 0.)
	m.controls.mitigate = h_M*copy(Mitp(t(mopt).-t_M))
	m.controls.remove = h_R*copy(Ritp(t(mopt).-t_R))
end;

# ╔═╡ 485a0f10-004c-11eb-0c6f-ebffd6fe21a3
begin
	optBox = @bind reveal_optimum CheckBox(default=false);
	md"""
	$(space) **Reveal optimal solution:** $(optBox)
	"""
end

# ╔═╡ 37aaa67c-004a-11eb-2cdf-93af1dbfc67c
function Iplot_controls()
	control_plot = plot(t(m), 0. .*t(m), fillrange = m.controls.remove*100, alpha=0.15, color="orange", label=nothing);
	plot!(t(m), 0. .*t(m), fillrange = m.controls.mitigate*100, alpha=0.15, color="blue", label=nothing);
	if reveal_optimum
		plot!(t(mopt), mopt.controls.remove*100, linestyle=:dash, color="orange", label=nothing);
		plot!(t(mopt), mopt.controls.mitigate*100, linestyle=:dash, color="blue", label=nothing);
	end
	
	plot!(xlabel="Year", ylabel="Controls [%]", xlims=(2020., 2200.), ylims=(0, 100))
	mytext = string("Your benefits: ", round(net_present_benefit(m, M=true, R=true), digits=1), " trillion USD")
	annotate!(2025, 95, text(mytext, :black, :left, 13))
	if reveal_optimum
		mytext = string("Optimal benefits: ", round(net_present_benefit(mopt, M=true, R=true), digits=1), " trillion USD")
		annotate!(2025, 86, text(mytext, :black, :left, 13))
	end
	return control_plot
end;


# ╔═╡ a21198e4-005f-11eb-1263-c52cca974dfd
begin
	βslider = @bind β Slider(0.2:0.2:10., default=3.);
	md"""
	$(space) $(βslider) [Range: 0% – 10%]
	"""
end
		

# ╔═╡ 94e7c94a-005f-11eb-0234-31c8ad724602
md"""
##### Modify parameter values
Cost of climate damages = $(β) % GWP for warming of 3 ºC
"""

# ╔═╡ 9caa5db6-f9b1-11ea-1916-df297297d41e
begin
	ρslider = @bind ρ Slider(0:0.25:7.5, default=1.);
	md"""
	$(space) $(ρslider) [Range: 0% – 7.5%]
	"""
end

# ╔═╡ 77a3fcaa-f9b1-11ea-1a1e-5d4fc30691ae
md"""Discount Rate = $(ρ)% """

# ╔═╡ 11e7a3e8-f9b2-11ea-083c-65c28fe60aa1
begin
	Mcost_slider = @bind Mcost Slider(0.:1:100., default=35);
	md"""
	$(space) $(Mcost_slider) [Range: 0 USD – 100 USD]
	"""
end

# ╔═╡ a21b07a8-f9b1-11ea-394a-e58c37684104
md"""
Cost of emissions mitigation (at 100%) = $(Mcost) USD per ton of CO₂
"""

# ╔═╡ e9c8002c-f6ed-11ea-10ae-d3a6ae4b0a13
function update_params!(m)
	m.economics.ρ = float(ρ/100.);
	m.economics.β = float(β/100. /9.)
	if Bool(M)
		m.economics.mitigate_cost = float(Mcost*1.e9/1.e12)
	end
end;

# ╔═╡ 4a836eee-f77d-11ea-07bf-61bc1108d06e
function update_plot!(m)
	update_params!(m);
	custom_user!(m);
	custom_optimize!(mopt);
	if panel == "controls"
		panel_plot = Iplot_controls();
	elseif panel == "emit"
		panel_plot = Iplot_emissions();
	elseif panel == "co2"
		panel_plot = Iplot_CO2();
	elseif panel == "temp"
		panel_plot = Iplot_temperature();
	elseif panel == "benefits"
		panel_plot = Iplot_benefits();
	elseif panel == "discounted_benefits"
		panel_plot = Iplot_benefits(discounting=true);
	end
	return panel_plot
end;

# ╔═╡ 7ce36c32-f777-11ea-10c7-5bd7257cf131
begin
	update_plot!(m)
end

# ╔═╡ Cell order:
# ╟─dc3ef642-f75e-11ea-0e95-e1c64a6fdbf2
# ╟─7cd92dfa-f6ee-11ea-2a62-5de6dc054afe
# ╟─f38a0f5a-f6ee-11ea-28d6-6d93e84f8866
# ╟─f4ce2bb4-f782-11ea-3d14-29a859a3b5b0
# ╟─c350e13c-f783-11ea-20c9-850f0b9924c4
# ╟─edd01696-0048-11eb-1e9a-5b3f2e079b2b
# ╟─7ce36c32-f777-11ea-10c7-5bd7257cf131
# ╟─4dfdbcdc-004c-11eb-16d2-3dd3c1f7c4c4
# ╟─485a0f10-004c-11eb-0c6f-ebffd6fe21a3
# ╟─94e7c94a-005f-11eb-0234-31c8ad724602
# ╟─a21198e4-005f-11eb-1263-c52cca974dfd
# ╟─77a3fcaa-f9b1-11ea-1a1e-5d4fc30691ae
# ╟─9caa5db6-f9b1-11ea-1916-df297297d41e
# ╟─a21b07a8-f9b1-11ea-394a-e58c37684104
# ╟─11e7a3e8-f9b2-11ea-083c-65c28fe60aa1
# ╟─968be15e-0049-11eb-2449-3df90fd001a7
# ╟─46e25d84-f6ee-11ea-2f08-af76b3b89fd1
# ╠═8535b8ba-0047-11eb-3b34-5dd347543631
# ╠═5f58784e-f6ee-11ea-1ca7-9fb8b53cd779
# ╠═14fe5804-f6ee-11ea-0971-b747e79dba0e
# ╠═01d7d08e-005d-11eb-2664-2b246ec2d520
# ╠═c912442c-0049-11eb-1cce-2bf1e879b468
# ╟─04b09746-f6ee-11ea-1cf7-67bab932507e
# ╠═3a643e88-f6ee-11ea-2e27-f52e39bd930a
# ╠═4a836eee-f77d-11ea-07bf-61bc1108d06e
# ╠═37aaa67c-004a-11eb-2cdf-93af1dbfc67c
# ╠═35d675ba-004a-11eb-3083-ad10120d98d2
# ╠═fd18f7d0-f6ed-11ea-2d8a-67901fb687d9
# ╠═97507428-f783-11ea-3d77-ef80b23a6c66
# ╠═1c8521d2-f9ac-11ea-09d4-b122b4a01b4e
# ╠═bc328530-f9ac-11ea-3f7a-8b8cc013c856
# ╠═e9c8002c-f6ed-11ea-10ae-d3a6ae4b0a13
# ╟─8179f4ec-f75d-11ea-26eb-2b9b9267f7b0
# ╠═e59f9724-f6e8-11ea-2ce8-9714ac41b32c
