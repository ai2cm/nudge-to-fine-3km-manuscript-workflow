#!/bin/bash

set -e

EXPERIMENT=2021-04-13-n2f-c3072

argo submit --from workflowtemplate/prognostic-run \
    -p output="gs://vcm-ml-experiments/${EXPERIMENT}/3-hrly-ave-control-30-min-rad-timestep-shifted-start-tke-edmf" \
    -p config="$(< nudging-config-3-hrly-ave-control-30-min-rad-timestep-shifted-start-tke-edmf.yaml)" \
    -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
    -p initial-condition="20160801.010000" \
    -p segment-count="7" \
    --name "${EXPERIMENT}-nudge-to-fine-control-tke-edmf"
