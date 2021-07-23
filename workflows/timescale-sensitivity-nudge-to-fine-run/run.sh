#!/bin/bash
set -e

EXPERIMENT=2021-04-28-n2f-c3072-timescale-sensitivity-update

BASE_CONFIG=nudging-config-template.yaml
TMP_CONFIG=tmp-nudging-config.yaml

# 1 hr is special case because tendencies not averaged over 3 hr
argo submit --from workflowtemplate/prognostic-run \
    -p output="gs://vcm-ml-experiments/${EXPERIMENT}/nudging-timescale-1hr" \
    -p config="$(< nudging-config-1hr.yaml )" \
    -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
    -p initial-condition="20160801.001500" \
    -p segment-count=19 \
    --name "${EXPERIMENT}-1hr"
echo "argo get ${EXPERIMENT}-1hr"

# nudging timescale is in hours
for tau in 6 12 
do 
    cp $BASE_CONFIG $TMP_CONFIG
    sed -i "s/nudging-timescale-hours/$tau/g"  $TMP_CONFIG
    argo submit --from workflowtemplate/prognostic-run \
        -p output="gs://vcm-ml-experiments/${EXPERIMENT}/nudging-timescale-${tau}hr" \
        -p config="$(< $TMP_CONFIG )" \
        -p reference-restarts=gs://vcm-ml-experiments/2020-06-02-fine-res/coarsen_restarts \
        -p initial-condition="20160801.001500" \
        -p segment-count=19 \
        --name "${EXPERIMENT}-${tau}hr"
    echo "argo get ${EXPERIMENT}-${tau}hr"
done


