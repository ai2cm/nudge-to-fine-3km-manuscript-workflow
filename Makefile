FIGURES = figure_x

# nudged to fine run where we do not set any states based on fine-resolution data, 
# use a radiation timestep of 1800 seconds, start the simulation at 20160801.010000, 
# and use the TKE-EDMF turbulence scheme
nudge_to_fine_control_half_hour_rad_timestep_shifted_start_tke_edmf: deploy_nudge_to_fine
	cd workflows/nudge-to-fine-run; \
	./nudged-run-3-hrly-ave-control-30-min-rad-timestep-shifted-start-tke-edmf.sh

# nudged to fine run where we set the surface radiative fluxes and precipitation rate
# based on fine-resolution data, use a radiation timestep of 1800 seconds, start
# the simulation at 20160801.010000, and use the TKE-EDMF turbulence scheme
nudge_to_fine_rad_precip_half_hour_rad_timestep_shifted_start_tke_edmf: deploy_nudge_to_fine
	cd workflows/nudge-to-fine-run; \
	./nudged-run-3-hrly-ave-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf.sh
    
deploy: kustomize
	./kustomize build . | kubectl apply -f -
    
deploy_nudge_to_fine: kustomize
	./kustomize build workflows/nudge-to-fine-run | kubectl apply -f -

kustomize:
	./install_kustomize.sh 3.10.0

create_environment:
	make -C fv3net update_submodules && make -C fv3net create_environment

create_figures: create_environment $(addprefix execute_notebook_, $(FIGURES))

execute_notebook_%:
	jupyter nbconvert --to notebook --execute notebooks/$**.ipynb
