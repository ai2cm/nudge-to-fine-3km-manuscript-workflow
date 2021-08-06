#!/bin/bash

set -e

EXPERIMENT=2021-04-13-n2f-c3072
RANDOM=$(openssl rand --hex 6)

argo submit --from workflowtemplate/prognostic-run \
    -p output="gs://vcm-ml-experiments/${EXPERIMENT}/3-hrly-ave-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf-fast-sat" \
    -p config="$(< nudging-config-3-hrly-ave-rad-precip-setting-30-min-rad-timestep-shifted-start-tke-edmf-fast-sat.yaml)" \
    -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
    -p initial-condition="20160801.010000" \
    -p segment-count="8" \
    --name "${EXPERIMENT}-nudge-to-fine-${RANDOM}"
