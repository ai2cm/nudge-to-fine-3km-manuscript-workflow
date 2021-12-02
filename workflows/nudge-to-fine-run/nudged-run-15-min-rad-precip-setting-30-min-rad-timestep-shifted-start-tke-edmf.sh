#!/bin/bash

set -e

EXPERIMENT=2021-04-13-n2f-c3072
RANDOM=$(openssl rand --hex 6)

argo submit --from workflowtemplate/prognostic-run \
    -p output="gs://vcm-ml-experiments/${EXPERIMENT}/15-min-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf" \
    -p config="$(< nudging-config-15-min-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf.yaml)" \
    -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
    -p initial-condition="20160801.010000" \
    -p segment-count="2" \
    --name "${EXPERIMENT}-nudge-to-fine-${RANDOM}"
