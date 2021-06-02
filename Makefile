# zarr dataset for radiation and precip prescribed nudged run saved by this notebook
# https://github.com/VulcanClimateModeling/explore/blob/master/spencerc/2021-04-08-create-training-data/2021-04-08-radiative-flux-training-data.ipynb
TRAINING_DATA_RAD_PRECIP_PRESCRIBED_ZARR=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf-training-dataset/training_dataset.zarr
TRAINING_DATA_RAD_PRECIP_PRESCRIBED=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf

TRAINING_DATA_CONTROL_ZARR=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-control-30-min-rad-timestep-shifted-start-tke-edmf-training-dataset/training_dataset.zarr
TRAINING_DATA_CONTROL=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-control-30-min-rad-timestep-shifted-start-tke-edmf

generate_times:
	cd train-evaluate-prognostic-run; \
	python generate_times.py \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED) \
		train_prescribed_precip_flux.json \
		test_prescribed_precip_flux.json ; \
	python generate_times.py \
		$(TRAINING_DATA_CONTROL) \
		train_control.json \
		test_control.json


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

nudge_to_fine_create_training_data_zarrs:
	python workflows/nudge-to-fine-run/create_training_data_zarrs.py

deploy_ml_experiments: kustomize
	./kustomize build workflows/train-evaluate-prognostic-run | kubectl apply -f -
    
deploy_nudge_to_fine: kustomize
	./kustomize build workflows/nudge-to-fine-run | kubectl apply -f -

kustomize:
	./install_kustomize.sh 3.10.0