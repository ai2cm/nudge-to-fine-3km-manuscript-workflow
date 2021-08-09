#!/bin/bash

gsutil cp -r dQ1-dQ2-no-tq-reg-mse gs://vcm-ml-experiments/2021-08-05-nudge-to-c3072/nn-no-tq-reg-mse-ensemble-model/trained_models/dq1-dq2
gsutil cp gs://vcm-ml-experiments/2021-08-05-nudge-to-c3072/nn-no-tq-reg-mse/seed-0/trained_models/postphysics_ML_dQ1_dQ2/training_config.yml \
    gs://vcm-ml-experiments/2021-08-05-nudge-to-c3072/nn-no-tq-reg-mse-ensemble-model/trained_models/dq1-dq2/training_config.yml