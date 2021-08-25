#!/bin/bash

set -e


EXPERIMENT=$1
# Training is split into two jobs because tendencies use open_nudge_to_fine instead of open_zarr
# This is because the tendencies predicted need to be subtracted from the state at end of timestep
TRAIN_TEST_DATA_TENDENCIES=$2
TRAIN_TEST_DATA_SFC=$3
TRAINING_CONFIG_TENDENCIES=$4
TRAINING_CONFIG_SFC=$5
TRAIN_TIMES=$6
TEST_TIMES=$7

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
    --name $NAME-dqs
echo "argo get $NAME-dqs"

# this will crash at the prognostic run step, as the prephysics ML is not incorporated into this template
argo submit \
    --from workflowtemplate/train-diags-prog \
    -p root=$ROOT \
    -p train-test-data=$TRAIN_TEST_DATA_SFC \
    -p training-configs="$( yq . $TRAINING_CONFIG_SFC )" \
    -p training-flags="--local-download-path train-data-download-dir" \
    -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
    -p initial-condition="20160805.000000" \
    -p prognostic-run-config="$(< prognostic-run.yaml)" \
    -p train-times="$(<  $TRAIN_TIMES )" \
    -p test-times="$(<  $TEST_TIMES )" \
    -p memory-offline-diags="12Gi" \
    -p public-report-output=gs://vcm-ml-public/offline_ml_diags/$EXPERIMENT \
    -p segment-count=1 \
    --name $NAME-sfc
echo "argo get $NAME-sfc"