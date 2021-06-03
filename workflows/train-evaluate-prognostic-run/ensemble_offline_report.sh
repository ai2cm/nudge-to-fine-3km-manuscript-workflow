#!/bin/bash

set -e

TEST_TIMES=test_prescribed_precip_flux.json

EXPERIMENT_ROOT=$1
REPORT_OUTPUT_ROOT=$2 

argo submit \
    --from workflowtemplate/offline-diags \
    -p ml-model="$EXPERIMENT_ROOT/trained_models/dq1-dq2" \
    -p times="$(<  $TEST_TIMES )" \
    -p offline-diags-output="$EXPERIMENT_ROOT/offline_diags/dq1-dq2" \
    -p report-output="$REPORT_OUTPUT_ROOT/dq1-dq2" \
    -p memory="25Gi" \
    --name "offline-nn-ensemble-dq1-dq2"

argo submit \
    --from workflowtemplate/offline-diags \
    -p ml-model="$EXPERIMENT_ROOT/trained_models/dqu-dqv" \
    -p times="$(<  $TEST_TIMES )" \
    -p offline-diags-output="$EXPERIMENT_ROOT/offline_diags/dqu-dqv" \
    -p report-output="$REPORT_OUTPUT_ROOT/dqu-dqv" \
    -p memory="25Gi" \
    --name "offline-nn-ensemble-dqu-dqv"

argo submit \
    --from workflowtemplate/offline-diags \
    -p ml-model="$EXPERIMENT_ROOT/trained_models/surface-rad" \
    -p times="$(<  $TEST_TIMES )" \
    -p offline-diags-output="$EXPERIMENT_ROOT/offline_diags/surface-rad" \
    -p report-output="$REPORT_OUTPUT_ROOT/surface-rad" \
    -p memory="25Gi" \
    --name "offline-nn-ensemble-surface-rad"