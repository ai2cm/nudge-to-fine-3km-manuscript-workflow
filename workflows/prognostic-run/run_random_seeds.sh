#!/bin/bash

set -e

EXPERIMENT=$1
TENDENCIES_ML_MODEL=$2
PROGNOSTIC_CONFIG=$3
OUTPUT=$4

TMP_CONFIG=prognostic-configs/tmp-config.yml

for i in {0..3}
do
    cp $PROGNOSTIC_CONFIG $TMP_CONFIG
    sed -i "s/seed-n/seed-$i/" $TMP_CONFIG
    RANDOM_SEED_TENDENCIES_ML_MODEL="${TENDENCIES_ML_MODEL//seed-n/seed-$i}"    
    OUTPUT_SEED="${OUTPUT//seed-n/seed-$i}"
    argo submit \
        --from workflowtemplate/prognostic-run \
        -p output=$OUTPUT_SEED \
        -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
        -p initial-condition="20160805.000000" \
        -p config="$(< $TMP_CONFIG )" \
        -p segment-count=8 \
        -p memory="12Gi" \
        -p flags="--model_url ${RANDOM_SEED_TENDENCIES_ML_MODEL}" \
        --name "prog-$EXPERIMENT-$i"

    echo "argo get prog-$EXPERIMENT-$i"
done