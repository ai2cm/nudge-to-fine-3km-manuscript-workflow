#!/bin/bash

gsutil cp -r surface-rad gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/surface-rad-rectified
gsutil cp -r dQ1-dQ2 gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dq1-dq2
gsutil cp -r dQu-dQv gs://vcm-ml-experiments/2021-05-11-nudge-to-c3072-corrected-winds/nn-ensemble-model/trained_models/dqu-dqv