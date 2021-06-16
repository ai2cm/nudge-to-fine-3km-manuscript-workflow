#!/bin/bash

gsutil cp -r surface-rad gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/surface-rad-rectified
gsutil cp -r dQ1-dQ2 gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dq1-dq2
gsutil cp -r dQu-dQv gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dqu-dqv

# config files so offline reports can run
gsutil cp gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn/seed-0/trained_models/postphysics_ML_dQ1_dQ2/training_config.yml \
    gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dq1-dq2
gsutil cp gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn/seed-0/trained_models/postphysics_ML_dQu_dQv/training_config.yml \
    gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dqu-dqv
gsutil cp gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn/seed-0/trained_models/prephysics_ML_surface_flux_rectified/training_config.yml \
    gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/surface-rad-rectified