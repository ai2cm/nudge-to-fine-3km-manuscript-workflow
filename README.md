# nudge-to-fine-3km-manuscript-workflow
A reproducible set of workflows for the N2F-3km manuscript

The repository consists of two major types of configurations:
1) argo workflows for generating the data used in machine learning, training models, and running the FV3GFS model prognostically
2) using data generated above, scripts and notebooks for generating the figures in the manuscript


Repository structure:
```
├── LICENSE
├── Makefile
├── README.md
├── install_kustomize.sh
├── kustomization.yaml
├── kustomize
└── workflows
    └── nudge-to-fine-run
    └── prognostic-run
    └── prognostic-run-report
    └── train-evaluate-prognostic-run
```

# Reproducing the results

Running the make commands in the order shown in the DAGs below will reproduce the experiments described in this paper. 


#### Main experiment
This DAG outlines how to generate our main results for the random forest and neural network ensemble trained on nudged-to-3km dataset with surface fluxes and precipitation prescribed from the fine resolution reference.

![](main-experiment-dag.png)

#### Sensitivity to nudged training data and ML radiative fluxes

This DAG outlines how to generate the results of our sensitivity study testing the effects of i) prescribing surface radiative fluxes and precipitation to the fine res reference in the nudged training run, and ii) training an ML model to predict surface radiative fluxes and update with its predictions during the prognostic run.

Greyed out boxes indicate steps that have already been completed, assuming the workflow in the above DAG for the main experiment has already run.
![](sensitivity-experiment-dag.png)