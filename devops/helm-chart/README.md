# Argo CD Node.js App – Helm chart

All configuration is in `values.yaml`; templates are fully declarative.

## Argo CD Application

Create an Application in Argo CD that points at this repo with path **helm-chart** (Git source path = `helm-chart`).  
The deploy workflow syncs from a **temp copy** with the new image tag; the folder in GitHub is not modified.

## Required GitHub secrets (for deploy workflow)

| Secret             | Description                          |
|--------------------|--------------------------------------|
| `ARGOCD_SERVER`    | Argo CD URL (e.g. `https://argocd.example.com`) |
| `ARGOCD_USERNAME`  | Argo CD username (e.g. `admin`)      |
| `ARGOCD_PASSWORD`  | Argo CD password                     |
| `ARGOCD_APP_NAME`  | Application name in Argo CD (e.g. `argocd-testing-app`) |

## Override values

Set `image.tag` (and any other values) when installing/upgrading; the CI workflow sets the tag in a temp copy and syncs via Argo CD CLI.
