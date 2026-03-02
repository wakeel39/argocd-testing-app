#!/usr/bin/env bash
# Sync this app to local Argo CD (same flow as the workflow, no Git push).
# Usage: ./scripts/sync-local-argocd.sh [VERSION]
# Example: ./scripts/sync-local-argocd.sh 1.0.5

set -e
VERSION="${1:-1.0.1}"
APP_NAME="${ARGOCD_APP_NAME:-argocd-testing-app}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Version: $VERSION | App: $APP_NAME"
mkdir -p "$REPO_ROOT/deploy-temp"
cp -r "$REPO_ROOT/helm-chart" "$REPO_ROOT/deploy-temp/"

if sed --version 2>/dev/null | grep -q GNU; then
  sed -i "s/^  tag: .*/  tag: $VERSION/" "$REPO_ROOT/deploy-temp/helm-chart/values.yaml"
else
  sed -i '' "s/^  tag: .*/  tag: $VERSION/" "$REPO_ROOT/deploy-temp/helm-chart/values.yaml"
fi

argocd app sync "$APP_NAME" --local-repo-root "$REPO_ROOT/deploy-temp" --local helm-chart --force
argocd app wait "$APP_NAME" --health --timeout 300
argocd app get "$APP_NAME" --show-operation

rm -rf "$REPO_ROOT/deploy-temp"
echo "Done. Temp folder removed."
