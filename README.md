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
```
