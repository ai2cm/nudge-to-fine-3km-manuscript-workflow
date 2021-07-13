#!/bin/bash

set -e


EXPERIMENT=$1
TRAIN_TEST_DATA_TENDENCIES=$2
TRAINING_CONFIG_TENDENCIES=$3
TRAIN_TIMES=$4
TEST_TIMES=$5

ROOT=gs://vcm-ml-experiments/$EXPERIMENT
NAME=$(echo $EXPERIMENT | sed -e 's~/~-~')

argo submit \
    --from workflowtemplate/train-diags-prog \
    -p root=$ROOT \
    -p train-test-data=$TRAIN_TEST_DATA_TENDENCIES  \
    -p training-configs="$( yq . $TRAINING_CONFIG_TENDENCIES )" \
    -p training-flags="--local-download-path train-data-download-dir" \
    -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
    -p initial-condition="20160805.000000" \
    -p prognostic-run-config="$(< prognostic-run.yaml )" \
    -p train-times="$(<  $TRAIN_TIMES )" \
    -p test-times="$(<  $TEST_TIMES )" \
    -p memory-offline-diags="20Gi" \
    -p memory-training="12Gi" \
    -p public-report-output=gs://vcm-ml-public/offline_ml_diags/$EXPERIMENT \
    -p segment-count=1 \
    --name $NAME
echo "argo get $NAME"
