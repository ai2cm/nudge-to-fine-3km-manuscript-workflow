# zarr dataset for radiation and precip prescribed nudged run saved by this notebook
# https://github.com/VulcanClimateModeling/explore/blob/master/spencerc/2021-04-08-create-training-data/2021-04-08-radiative-flux-training-data.ipynb
TRAINING_DATA_RAD_PRECIP_PRESCRIBED_ZARR=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf-training-dataset/training_dataset.zarr
TRAINING_DATA_RAD_PRECIP_PRESCRIBED=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf

TRAINING_DATA_CONTROL_ZARR=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-control-30-min-rad-timestep-shifted-start-tke-edmf-training-dataset/training_dataset.zarr
TRAINING_DATA_CONTROL=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-control-30-min-rad-timestep-shifted-start-tke-edmf

FIGURES = (Figure-1 Figure-2 Figure-3 Figure-5 Figure-6 Figure-A1 Figure-A2 Figure-A5 Figure-A7 Table-2)

generate_times_prescribed:
	python workflows/train-evaluate-prognostic-run/generate_times.py \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED) \
		train_prescribed_precip_flux.json \
		test_prescribed_precip_flux.json 

generate_times_control:
	python workflows/train-evaluate-prognostic-run/generate_times.py \
		$(TRAINING_DATA_CONTROL) \
		train_control.json \
		test_control.json

# nudged to fine run where we do not set any states based on fine-resolution data, 
# use a radiation timestep of 1800 seconds, start the simulation at 20160801.010000, 
# and use the TKE-EDMF turbulence scheme
nudge_to_fine_control: deploy_nudge_to_fine
	cd workflows/nudge-to-fine-run; \
	./nudged-run-3-hrly-ave-control-30-min-rad-timestep-shifted-start-tke-edmf.sh

# nudged to fine run where we set the surface radiative fluxes and precipitation rate
# based on fine-resolution data, use a radiation timestep of 1800 seconds, start
# the simulation at 20160801.010000, and use the TKE-EDMF turbulence scheme
nudge_to_fine_rad_precip_prescribed: deploy_nudge_to_fine
	cd workflows/nudge-to-fine-run; \
	./nudged-run-3-hrly-ave-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf.sh

nudge_to_fine_training_data_zarrs_prescribed:
	python workflows/nudge-to-fine-run/create_training_data_zarrs.py \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED)/state_after_timestep.zarr \
		gs://vcm-ml-scratch/annak/2021-06-03-test-output
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED_ZARR)

nudge_to_fine_training_data_zarrs_control:
	python workflows/nudge-to-fine-run/create_training_data_zarrs.py \
		$(TRAINING_DATA_CONTROL) \
		$(TRAINING_DATA_CONTROL_ZARR)
        
# training nudged data has rad and precip prescribed from reference
train_Tq_rf: deploy_ml_experiments_rf generate_times_control
	cd workflows/train-evaluate-prognostic-run;  \
	./run_control_dQ1_dQ2.sh \
		2021-05-11-nudge-to-c3072-corrected-winds/control-dq1-dq2-rf \
		$(TRAINING_DATA_CONTROL) \
		./training-configs/tendency-outputs-dQ1-dQ2-rf.yaml \
		train_control.json \
		test_control.json

# training nudged data has rad and precip prescribed from reference
train_rf_TqR: deploy_ml_experiments_rf generate_times_prescribed
	cd workflows/train-evaluate-prognostic-run;  \
	./run.sh \
		2021-06-21-nudge-to-c3072-dq1-dq2-only/rf \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED) \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED_ZARR) \
		./training-configs/tendency-outputs-dQ1-dQ2-rf.yaml \
		./training-configs/surface-outputs.yaml \
		train_prescribed_precip_flux.json \
		test_prescribed_precip_flux.json

# training nudged data has rad and precip prescribed from reference
train_rf_TquvR: deploy_ml_experiments_rf generate_times_prescribed
	cd workflows/train-evaluate-prognostic-run;  \
	./run.sh \
		2021-05-11-nudge-to-c3072-corrected-winds/rf \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED) \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED_ZARR) \
		./training-configs/tendency-outputs.yaml \
		./training-configs/surface-outputs.yaml \
		train_prescribed_precip_flux.json \
		test_prescribed_precip_flux.json

# training nudged data has rad and precip prescribed from reference
train_nn_TquvR_random_seeds: deploy_ml_experiments_nn generate_times_prescribed
	cd workflows/train-evaluate-prognostic-run;  \
	./run_random_seeds.sh \
		2021-05-11-nudge-to-c3072-corrected-winds/nn \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED) \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED_ZARR) \
		./training-configs/tendency-outputs-nn.yaml \
		./training-configs/surface-outputs-nn.yaml \
		train_prescribed_precip_flux.json \
		test_prescribed_precip_flux.json

# ensemble model needs offline report generated, as it is only done automatically for its components
offline_report_nn_ensemble: deploy_ml_experiments_nn generate_times_control
	cd workflows/train-evaluate-prognostic-run; \
	nn-ensemble-models/upload.sh; \
	./ensemble_offline_report.sh \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model-rectified \
		gs://vcm-ml-public/offline_ml_diags/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model-rectified
        
# training nudged data does not have any prescribed surface states
# runs four initial conditions
# prognostic run updates with dQ1, dQ2 from ML RF prediction
prognostic_Tq_rf_ics: deploy_ml_experiments_rf
	cd workflows/prognostic-run; \
	./run_ICs.sh \
		training-control-tq-rf \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/control-dq1-dq2-rf/trained_models/postphysics_ML_tendencies \
		prognostic-configs/ml-tendencies-only.yaml \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/control-dq1-dq2-rf/initial_conditions_runs

# training nudged data has rad and precip prescribed from reference
# runs four initial conditions
# prognostic run updates with dQ1, dQ2, and rad from ML RF prediction
prognostic_TqR_rf_ics: deploy_ml_experiments_rf
	cd workflows/prognostic-run; \
	./run_ICs.sh \
		training-prescribed-tqr-rad-rf \
		gs://vcm-ml-experiments/2021-06-21-nudge-to-c3072-dq1-dq2-only/rf/trained_models/postphysics_ML_tendencies \
		prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-rf.yaml \
		gs://vcm-ml-experiments/2021-06-21-nudge-to-c3072-dq1-dq2-only/rf/initial_conditions_runs

# training nudged data has rad and precip prescribed from reference
# runs four initial conditions
# prognostic run updates with dQ1, dQ2, dQu, dQv, and rad from ML RF prediction
prognostic_TquvR_rf_ics: deploy_ml_experiments_rf
	cd workflows/prognostic-run; \
	./run_ICs.sh \
		training-prescribed-tquvr-rad-rf \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/rf/trained_models/postphysics_ML_tendencies \
		prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-rf.yaml \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/rf/initial_conditions_runs

# training nudged data has rad and precip prescribed from reference
# runs four initial conditions
# prognostic run updates with dQ1, dQ2 and rad from ML NN ensemble median prediction
prognostic_TqR_nn_ensemble_ics: deploy_ml_experiments_nn
	cd workflows/prognostic-run; \
	./run_ICs.sh \
		training-prescribed-tq-rad-rect-nn \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dq1-dq2 \
		prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-nn-ensemble.yaml \
		gs://vcm-ml-experiments/2021-06-21-nudge-to-c3072-dq1-dq2-only/nn-ensemble-model/initial_conditions_runs

# training nudged data has rad and precip prescribed from reference
# runs four initial conditions
# prognostic run updates with dQ1, dQ2, dQu, dQv, and rad from ML NN ensemble median prediction
prognostic_TquvR_nn_ensemble_ics: deploy_ml_experiments_nn
	cd workflows/prognostic-run; \
	./run_ICs.sh \
		training-prescribed-tquv-rad-rect-nn \
		"gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dq1-dq2 --model_url gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dqu-dqv" \
		prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-nn-ensemble.yaml \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/initial_conditions_runs_rectified_nn_rad
        
# prognostic run using NN 
# prognostic run updates with dQ1, dQ2 and rad from ML NN prediction
prognostic_TqR_nn_random_seeds: deploy_ml_experiments_nn
	cd workflows/prognostic-run; \
	./run_random_seeds.sh \
		nn-tqr-random-seeds \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn/seed-n/trained_models/postphysics_ML_dQ1_dQ2 \
		prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-nn.yaml \
		gs://vcm-ml-experiments/2021-06-21-nudge-to-c3072-dq1-dq2-only/nn/seed-n/prognostic_run_sfc_rad
        
# prognostic run using NN 
# prognostic run updates with dQ1, dQ2, dQu, dQv, and rad from ML NN prediction
prognostic_TquvR_nn_random_seeds: deploy_ml_experiments_nn
	cd workflows/prognostic-run; \
	./run_random_seeds.sh \
		nn-tquvr-random-seeds \
		"gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn/seed-n/trained_models/postphysics_ML_dQ1_dQ2 --model_url gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn/seed-n/trained_models/postphysics_ML_dQu_dQv" \
		prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-nn.yaml \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn/seed-n/prognostic_run_sfc_rad_rectified

prognostic_run_report_nudged_training: deploy_ml_experiments_rf
	cd workflows/prognostic-run-report && ./run.sh nudge-to-3km-nudged-training
    
prognostic_report_ic_ensembles: deploy_ml_experiments_rf
	cd workflows/prognostic-run-report; \
	./run.sh nudge-to-3km-ic-ensembles
    
prognostic_report_nn_seeds: deploy_ml_experiments_rf
	cd workflows/prognostic-run-report; \
	./run.sh nudge-to-3km-nn-seeds

prognostic_report_sensitivity: deploy_ml_experiments_rf
	cd workflows/prognostic-run-report; \
	./run.sh nudge-to-3km-sensitivity

deploy_ml_experiments_rf: kustomize
	./kustomize build workflows/train-evaluate-prognostic-run/kustomize_rf | kubectl apply -f -

deploy_ml_experiments_nn: kustomize
	./kustomize build workflows/train-evaluate-prognostic-run/kustomize_nn_rectified | kubectl apply -f -	
    
deploy_nudge_to_fine: kustomize
	./kustomize build workflows/nudge-to-fine-run | kubectl apply -f -

kustomize:
	./install_kustomize.sh 3.10.0

create_environment:
	make -C fv3net update_submodules && make -C fv3net create_environment

create_figures: create_environment $(addprefix execute_notebook_, $(FIGURES))

execute_notebook_%:
	jupyter nbconvert --to notebook --execute notebooks/$**.ipynb
