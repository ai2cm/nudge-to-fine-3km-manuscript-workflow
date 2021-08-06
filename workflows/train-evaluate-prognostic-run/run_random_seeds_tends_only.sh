#!/bin/bash

set -e


EXPERIMENT=$1
# Training is split into two jobs because tendencies use open_nudge_to_fine instead of open_zarr
# This is because the tendencies predicted need to be subtracted from the state at end of timestep
TRAIN_TEST_DATA_TENDENCIES=$2
TRAINING_CONFIG_TENDENCIES=$3
TRAIN_TIMES=$4
TEST_TIMES=$5

ROOT=gs://vcm-ml-experiments/$EXPERIMENT
NAME=$(echo $EXPERIMENT | sed -e 's~/~-~')

TMP_CONFIG=training-configs/tmp-config.yml

for i in {0..3}
do
    cp $TRAINING_CONFIG_TENDENCIES $TMP_CONFIG
    sed -i "s/^    random_seed: .*$/    random_seed: $i/" $TMP_CONFIG
    
    argo submit \
        --from workflowtemplate/train-diags-prog \
        -p root=$ROOT/seed-$i \
        -p train-test-data=$TRAIN_TEST_DATA_TENDENCIES  \
        -p training-configs="$( yq . $TMP_CONFIG )" \
        -p training-flags="--local-download-path train-data-download-dir" \
        -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
        -p initial-condition="20160805.000000" \
        -p prognostic-run-config="$(< prognostic-run.yaml )" \
        -p train-times="$(<  $TRAIN_TIMES )" \
        -p test-times="$(<  $TEST_TIMES )" \
        -p memory-offline-diags="25Gi" \
        -p memory-training="12Gi" \
        -p public-report-output=gs://vcm-ml-public/offline_ml_diags/$EXPERIMENT/seed-$i \
        -p segment-count=1 \
        --name $NAME-dqs-$i
    echo "argo get $NAME-dqs-$i"
done
