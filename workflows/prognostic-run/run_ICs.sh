#!/bin/bash

set -e

EXPERIMENT=$1
TENDENCIES_ML_MODEL=$2
PROGNOSTIC_CONFIG=$3
OUTPUT=$4

INITIAL_CONDITIONS_ENSEMBLE=(20160805.000000 20160813.000000 20160821.000000 20160829.000000)

for INITIAL_CONDITIONS in ${INITIAL_CONDITIONS_ENSEMBLE[@]}; do
    argo submit \
        --from workflowtemplate/prognostic-run \
        -p output="${OUTPUT}/${INITIAL_CONDITIONS}" \
        -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
        -p initial-condition="${INITIAL_CONDITIONS}" \
        -p config="$(< $PROGNOSTIC_CONFIG )" \
        -p segment-count=8 \
        -p memory="12Gi" \
        -p flags="--model_url ${TENDENCIES_ML_MODEL}" \
        --name "${EXPERIMENT}-${INITIAL_CONDITIONS}"
    echo "argo get ${EXPERIMENT}-${INITIAL_CONDITIONS}"
done