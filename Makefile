# zarr dataset for radiation and precip prescribed nudged run saved by this notebook
# https://github.com/VulcanClimateModeling/explore/blob/master/spencerc/2021-04-08-create-training-data/2021-04-08-radiative-flux-training-data.ipynb
TRAINING_DATA_RAD_PRECIP_PRESCRIBED_ZARR=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf-training-dataset/training_dataset.zarr
TRAINING_DATA_RAD_PRECIP_PRESCRIBED=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf

TRAINING_DATA_CONTROL_ZARR=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-control-30-min-rad-timestep-shifted-start-tke-edmf-training-dataset/training_dataset.zarr
TRAINING_DATA_CONTROL=gs://vcm-ml-experiments/2021-04-13-n2f-c3072/3-hrly-ave-control-30-min-rad-timestep-shifted-start-tke-edmf

TRAINING_DATA_1_HR_TIMESCALE=gs://vcm-ml-experiments/2021-04-28-n2f-c3072-timescale-sensitivity-update/nudging-timescale-1hr
TRAINING_DATA_6_HR_TIMESCALE=gs://vcm-ml-experiments/2021-04-28-n2f-c3072-timescale-sensitivity-update/nudging-timescale-6hr
TRAINING_DATA_12_HR_TIMESCALE=gs://vcm-ml-experiments/2021-04-28-n2f-c3072-timescale-sensitivity-update/nudging-timescale-12hr

FIGURES = (Figure-1 Figure-2 Figure-3 Figure-4 Figure-5 Figure-6 Figure-8 Figure-9 Figure-A1 Figure-A2 Figure-A5 Figure-A6 Figure-A7 Figure-A8 Table-2)

generate_times_prescribed:
	python workflows/train-evaluate-prognostic-run/generate_times.py \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED) \
		workflows/train-evaluate-prognostic-run/train_prescribed_precip_flux.json \
		workflows/train-evaluate-prognostic-run/test_prescribed_precip_flux.json 

generate_times_control:
	python workflows/train-evaluate-prognostic-run/generate_times.py \
		$(TRAINING_DATA_CONTROL) \
		workflows/train-evaluate-prognostic-run/train_control.json \
		workflows/train-evaluate-prognostic-run/test_control.json

generate_times_nudging_sensitivity:
	python workflows/train-evaluate-prognostic-run/generate_times.py \
		$(TRAINING_DATA_1_HR_TIMESCALE) \
		workflows/train-evaluate-prognostic-run/train_tau_sensitivity.json \
		workflows/train-evaluate-prognostic-run/test_tau_sensitivity.json

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
    
# same as above but with fast sat adj turned on
nudge_to_fine_rad_precip_prescribed_fast_sat: deploy_nudge_to_fine
	cd workflows/nudge-to-fine-run; \
	./nudged-run-3-hrly-ave-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf-fast-sat.sh

nudge_to_fine_timescale_sensitivity: deploy_nudge_to_fine
	cd workflows/timescale-sensitivity-nudge-to-fine-run; \
	./run.sh

nudge_to_fine_training_data_zarrs_prescribed:
	python workflows/nudge-to-fine-run/create_training_data_zarrs.py \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED)/state_after_timestep.zarr \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED_ZARR)

nudge_to_fine_training_data_zarrs_control:
	python workflows/nudge-to-fine-run/create_training_data_zarrs.py \
		$(TRAINING_DATA_CONTROL)/state_after_timestep.zarr \
		$(TRAINING_DATA_CONTROL_ZARR)

nudge_to_fine_training_data_zarrs_timescales:
	python workflows/nudge-to-fine-run/create_training_data_zarrs.py \
		$(TRAINING_DATA_1_HR_TIMESCALE)/state_after_timestep.zarr \
		$(TRAINING_DATA_1_HR_TIMESCALE)/prescribed_training_data.zarr
	python workflows/nudge-to-fine-run/create_training_data_zarrs.py \
		$(TRAINING_DATA_6_HR_TIMESCALE)/state_after_timestep.zarr \
		$(TRAINING_DATA_6_HR_TIMESCALE)/prescribed_training_data.zarr
	python workflows/nudge-to-fine-run/create_training_data_zarrs.py \
		$(TRAINING_DATA_12_HR_TIMESCALE)/state_after_timestep.zarr \
		$(TRAINING_DATA_12_HR_TIMESCALE)/prescribed_training_data.zarr
    
# training nudged data has rad and precip prescribed from reference
train_Tq_rf: deploy_ml_experiments_rf generate_times_control
	cd workflows/train-evaluate-prognostic-run;  \
	./run_control_dQ1_dQ2.sh \
		2021-05-11-nudge-to-c3072-corrected-winds/control-dq1-dq2-rf \
		$(TRAINING_DATA_CONTROL) \
		./training-configs/tendency-outputs-dQ1-dQ2-rf.yaml \
		train_control.json \
		test_control.json

# train NN models on 1/6/12 hr nudging timescale data
train_timescale_sensitivites: deploy_ml_experiments_nn generate_times_nudging_sensitivity
	cd workflows/train-evaluate-prognostic-run;  \
	./run.sh \
		2021-05-11-nudge-to-c3072-corrected-winds/nudged-tau-1-hr \
		$(TRAINING_DATA_1_HR_TIMESCALE) \
		$(TRAINING_DATA_1_HR_TIMESCALE)/prescribed_training_data.zarr \
		./training-configs/tendency-outputs-nn.yaml \
		./training-configs/surface-outputs-nn.yaml \
		train_tau_sensitivity.json \
		test_tau_sensitivity.json
	./run.sh \
		2021-05-11-nudge-to-c3072-corrected-winds/nudged-tau-6-hr \
		$(TRAINING_DATA_6_HR_TIMESCALE) \
		$(TRAINING_DATA_6_HR_TIMESCALE)/prescribed_training_data.zarr \
		./training-configs/tendency-outputs-nn.yaml \
		./training-configs/surface-outputs-nn.yaml \
		train_tau_sensitivity.json \
		test_tau_sensitivity.json
	./run.sh \
		2021-05-11-nudge-to-c3072-corrected-winds/nudged-tau-12-hr \
		$(TRAINING_DATA_12_HR_TIMESCALE) \
		$(TRAINING_DATA_12_HR_TIMESCALE)/prescribed_training_data.zarr \
		./training-configs/tendency-outputs-nn.yaml \
		./training-configs/surface-outputs-nn.yaml \
		train_tau_sensitivity.json \
		test_tau_sensitivity.json


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
        
# same as above but without Tq NN regularization
train_nn_TquvR_no_reg_random_seeds: deploy_ml_experiments_nn generate_times_prescribed
	cd workflows/train-evaluate-prognostic-run;  \
	./run_random_seeds_tends_only.sh \
		2021-08-05-nudge-to-c3072/nn-no-tq-reg \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED) \
		./training-configs/tendency-outputs-nn-no-tq-reg.yaml \
		train_prescribed_precip_flux.json \
		test_prescribed_precip_flux.json
        
# same as above but with mse loss
train_nn_TquvR_no_reg_mse_random_seeds: deploy_ml_experiments_nn generate_times_prescribed
	cd workflows/train-evaluate-prognostic-run;  \
	./run_random_seeds_tends_only.sh \
		2021-08-05-nudge-to-c3072/nn-no-tq-reg-mse \
		$(TRAINING_DATA_RAD_PRECIP_PRESCRIBED) \
		./training-configs/tendency-outputs-nn-no-tq-reg-mse.yaml \
		train_prescribed_precip_flux.json \
		test_prescribed_precip_flux.json

# ensemble model needs offline report generated, as it is only done automatically for its components
offline_report_nn_ensemble: deploy_ml_experiments_nn generate_times_prescribed
	cd workflows/train-evaluate-prognostic-run; \
	nn-ensemble-models/upload.sh; \
	./ensemble_offline_report.sh \
		gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model-rectified \
		gs://vcm-ml-public/offline_ml_diags/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model-rectified
               
# same as offline_report_nn_ensemble but for the NNs without Tq regularization
offline_report_nn_no_tq_reg_ensemble: deploy_ml_experiments_nn generate_times_prescribed
	cd workflows/train-evaluate-prognostic-run; \
	cd nn-ensemble-models; ./upload_no_tq_reg.sh; \
	cd ..; ./ensemble_offline_report_no_tq_reg.sh \
		gs://vcm-ml-experiments/2021-08-05-nudge-to-c3072/nn-no-tq-reg-ensemble-model \
		gs://vcm-ml-public/offline_ml_diags/2021-08-05-nudge-to-c3072/nn-no-tq-reg-ensemble-model
        
# same as above but with mse loss
offline_report_nn_no_tq_reg_mse_ensemble: deploy_ml_experiments_nn generate_times_prescribed
	cd workflows/train-evaluate-prognostic-run; \
	cd nn-ensemble-models; ./upload_no_tq_reg_mse.sh; \
	cd ..; ./ensemble_offline_report_no_tq_reg_mse.sh \
		gs://vcm-ml-experiments/2021-08-05-nudge-to-c3072/nn-no-tq-reg-mse-ensemble-model \
		gs://vcm-ml-public/offline_ml_diags/2021-08-05-nudge-to-c3072/nn-no-tq-reg-mse-ensemble-model
        
# baseline no-ML prognostic runs at different start times
prognostic_baseline: deploy_ml_experiments_rf
	cd workflows/prognostic-run; \
	./run_baseline.sh 20160801.010000; \
	./run_baseline.sh 20160805.000000; \
	./run_baseline.sh 20160813.000000; \
	./run_baseline.sh 20160821.000000; \
	./run_baseline.sh 20160829.000000
        
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
        
# same as above but with NNs with no Tq regularization and mse loss 
prognostic_TqR_nn_no_tq_reg_mse_ensemble_ics: deploy_ml_experiments_nn
	cd workflows/prognostic-run; \
	./run_ICs.sh \
		prognostic-tqr-nn-no-tq-reg-mse-ensemble-ics \
		gs://vcm-ml-experiments/2021-08-05-nudge-to-c3072/nn-no-tq-reg-mse-ensemble-model/trained_models/dq1-dq2 \
		prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-nn-ensemble.yaml \
		gs://vcm-ml-experiments/2021-08-05-nudge-to-c3072/nn-no-tq-reg-mse-ensemble-model/initial_conditions_runs

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

# prognostic runs for nudging timescale sensitivity experiment
prognostic_timescale_sensitivity:  deploy_ml_experiments_nn 
	cd workflows/timescale-sensitivity-prognostic-run; \
	./run.sh 2021-05-11-nudge-to-c3072-corrected-winds/nudged-tau-1-hr 1; \
	./run.sh 2021-05-11-nudge-to-c3072-corrected-winds/nudged-tau-6-hr 6; \
	./run.sh 2021-05-11-nudge-to-c3072-corrected-winds/nudged-tau-12-hr 12;

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

prognostic_report_nudging_timescale: deploy_ml_experiments_rf
	cd workflows/prognostic-run-report; \
	./run.sh nudge-to-3km-timescale-sensitivity

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
