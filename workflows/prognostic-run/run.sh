#!/bin/bash

set -e

EXPERIMENT=$1
INITIAL_CONDITIONS=$2
TENDENCIES_ML_MODEL=$3
PROGNOSTIC_CONFIG=$4
OUTPUT=$5

argo submit \
    --from workflowtemplate/prognostic-run \
    -p output=$OUTPUT \
    -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
    -p initial-condition="${INITIAL_CONDITIONS}" \
    -p config="$(< $PROGNOSTIC_CONFIG )" \
    -p segment-count=8 \
    -p memory="12Gi" \
    -p flags="--model_url ${TENDENCIES_ML_MODEL}" \
    --name "${EXPERIMENT}-${INITIAL_CONDITIONS}"

echo "argo get ${EXPERIMENT}-${INITIAL_CONDITIONS}"