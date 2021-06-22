#!/bin/bash

RUNDIRS=$1
NAME="prog-report-"${RUNDIRS}


argo submit --from=workflowtemplate/prognostic-run-diags \
    --name $NAME \
    -p runs="$(< ${RUNDIRS}.json)" \
    -p make-movies=false \
    -p memory-compute-diags="18Gi" \
    -p memory-report="16Gi"

echo "report generated at: https://storage.googleapis.com/vcm-ml-public/argo/${NAME}/index.html"
echo "argo get ${NAME}"