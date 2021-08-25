#!/bin/bash

set -e

START_TIME=$1

argo submit \
    --from workflowtemplate/prognostic-run \
    -p output="gs://vcm-ml-experiments/2021-04-13/baseline-physics-run-${START_TIME}-start-rad-step-1800s" \
    -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
    -p initial-condition="${START_TIME}" \
    -p config="$(< prognostic-configs/baseline.yaml)" \
    -p segment-count=8 \
    --name "baseline-physics-${START_TIME}-start-rad-step-1800s"