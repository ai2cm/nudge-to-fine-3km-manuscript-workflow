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


# training nudged data has rad and precip prescribed from reference
train_rf: deploy
	cd train-evaluate-prognostic-run; \
	./run.sh \
		2021-05-11-nudge-to-c3072-corrected-winds/rf \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED) \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED_ZARR) \
		./training-configs/tendency-outputs.yaml \
		./training-configs/surface-outputs.yaml \
		train_prescribed_precip_flux.json \
		test_prescribed_precip_flux.json

# training nudged data has rad and precip prescribed from reference
train_nn_random_seeds: deploy
	cd train-evaluate-prognostic-run; \
	./run_random_seeds.sh \
		2021-05-11-nudge-to-c3072-corrected-winds/nn \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED) \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED_ZARR) \
		./training-configs/tendency-outputs-nn.yaml \
		./training-configs/surface-outputs-nn.yaml \
		train_prescribed_precip_flux.json \
		test_prescribed_precip_flux.json


# training nudged data does not have any prescribed surface states
train_rf_control: deploy
	cd train-evaluate-prognostic-run; \
	./run.sh \
		2021-05-11-nudge-to-c3072-corrected-winds/control-rf \
		$(TRAINING_DATA_CONTROL) \
		$(TRAINING_DATA_CONTROL_ZARR) \
		./training-configs/tendency-outputs.yaml \
		./training-configs/surface-outputs.yaml \
		train_control.json \
		test_control.json


 

# training nudged data has rad and precip prescribed from reference
# runs four initial conditions
# prognostic run updates with dQ1, dQ2, dQu, dQv, and rad from ML RF prediction
prognostic_rf_ics: deploy
	cd prognostic-run; \
	./run_ICs.sh \
		training-prescribed-ml-tendencies-rad-rf \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/rf/trained_models/postphysics_ML_tendencies \
		prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-rf.yaml \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/rf/initial_conditions_runs


# training nudged data has rad and precip prescribed from reference
# runs four initial conditions
# prognostic run updates with dQ1, dQ2, dQu, dQv, and rad from ML NN ensemble median prediction
prognostic_nn_ensemble_ics: deploy
	cd prognostic-run; \
	./run_ICs.sh \
		training-prescribed-ml-tendencies-rad-nn \
		"gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dq1-dq2 --model_url gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dqu-dqv" \
		prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-nn-ensemble.yaml \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/initial_conditions_runs



# prognostic run using NN 
# prognostic run updates with dQ1, dQ2, dQu, dQv, and rad from ML NN prediction
prognostic_nn_random_seeds: deploy
	cd prognostic-run; \
	./run_random_seeds.sh \
		nn-random-seeds-rad-l2-2e-2 \
		"gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn/seed-n/trained_models/postphysics_ML_dQ1_dQ2 --model_url gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn/seed-n/trained_models/postphysics_ML_dQu_dQv" \
		prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-nn.yaml \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-rad-l2-2e-2/seed-n/prognostic_run_sfc_rad


# prognostic run using NN ensemble median of seeds 0-3
# prognostic run updates with dQ1, dQ2, dQu, dQv, and rad from ML NN prediction
prognostic_nn_ensemble: deploy
	cd prognostic-run; \
	nn-ensemble-models/upload.sh \
	./run.sh \
		nn-ensemble \
		"20160805.000000" \
		"gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dq1-dq2 --model_url gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dqu-dqv" \
		prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-nn-ensemble.yaml \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/prognostic_run_sfc_rad_l2_1e-2
 

# training nudged data does not have any prescribed surface states
# prognostic run updates with dQ1, dQ2, dQu, dQv, and rad from ML prediction
prognostic_training_control_ml_tendencies_rad: deploy
	cd prognostic-run; \
	./run.sh \
		training-control-ml-tendencies-rad \
		"20160805.000000" \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/control-rf/trained_models/postphysics_ML_tendencies \
		prognostic-configs/training-control-ml-tendencies-rad-rf.yaml \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/control-rf/prognostic_run_sfc_rad


# training nudged data does not have any prescribed surface states
# prognostic run updates with dQ1, dQ2, dQu, dQv from ML prediction
prognostic_training_control_ml_tendencies_only: deploy
	cd prognostic-run; \
	./run.sh \
		training-control-ml-tendencies-only \
		"20160805.000000" \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/control-rf/trained_models/postphysics_ML_tendencies \
		prognostic-configs/ml-tendencies-only.yaml \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/control-rf/prognostic_run_tendencies_only





deploy_ml_experiments: kustomize
	./kustomize build workflows/train-evaluate-prognostic-run | kubectl apply -f -
    
deploy_nudge_to_fine: kustomize
	./kustomize build workflows/nudge-to-fine-run | kubectl apply -f -

kustomize:
	./install_kustomize.sh 3.10.0