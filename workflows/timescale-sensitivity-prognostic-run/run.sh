#!/bin/bash

set -e

EXPERIMENT=$1   # 2021-05-11-nudge-to-c3072-corrected-winds/nudged-tau-1-hr
TAU=$2

ROOT=gs://vcm-ml-experiments/$EXPERIMENT
TQ_ML_MODEL="$ROOT/trained_models/postphysics_ML_dQ1_dQ2 "
UV_ML_MODEL="$ROOT/trained_models/postphysics_ML_dQu_dQv"
PROGNOSTIC_CONFIG=prognostic-configs/training-rad-precip-prescribed-ml-tendencies-rad-nn.yaml
# Naming is confusing but leaving as is for now because this is correct for the existing output.
# prognostic_run_sfc_flux = TquvR-NN, prognostic_run_tendencies_only = TqR-NN
OUTPUT_TQUV=$ROOT/prognostic_run_sfc_flux
OUTPUT_TQ=$ROOT/prognostic_run_tendencies_only

TMP_CONFIG=prognostic-configs/tmp-config.yml

NAME=prognostic-run-nudging-timescale-$TAU-hr

echo $OUTPUT
echo $TENDENCIES_ML_MODEL

cp $PROGNOSTIC_CONFIG $TMP_CONFIG
sed -i "s/NUDGING-TIMESCALE/$TAU/" $TMP_CONFIG
argo submit \
    --from workflowtemplate/prognostic-run \
    -p output=$OUTPUT_TQ \
    -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
    -p initial-condition="20160805.000000" \
    -p config="$(< $TMP_CONFIG )" \
    -p segment-count=8 \
    -p memory="12Gi" \
    -p flags="--model_url ${TQ_ML_MODEL}" \
    --name "$NAME"

echo "argo get $NAME"

argo submit \
    --from workflowtemplate/prognostic-run \
    -p output=$OUTPUT_TQUV \
    -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
    -p initial-condition="20160805.000000" \
    -p config="$(< $TMP_CONFIG )" \
    -p segment-count=8 \
    -p memory="12Gi" \
    -p flags="--model_url ${TQ_ML_MODEL} --model_url ${UV_ML_MODEL}" \
    --name "$NAME-full"

echo "argo get $NAME-full"
