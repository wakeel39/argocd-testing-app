# Testing with Argo CD installed locally

When Argo CD is running on your machine (e.g. in minikube/kind), use these steps to test the same flow as the workflow.

## 1. Expose Argo CD server (if not already)

```bash
# Get the Argo CD server URL (often port 443 or 8080)
kubectl get svc -n argocd argocd-server

# Port-forward so you can use localhost
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then the server URL is **https://localhost:8080** (or **https://127.0.0.1:8080**).

## 2. Get the initial admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Windows (PowerShell):**
```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

## 3. Install Argo CD CLI (if "argocd" is not recognized)

**Windows (PowerShell):**

Option A – Chocolatey (run as Administrator):
```powershell
choco install argocd
```

Option B – Scoop:
```powershell
scoop install argocd
```

Option C – Manual download:
1. Download from [Argo CD releases](https://github.com/argoproj/argo-cd/releases) (e.g. `argocd-windows-amd64.exe`).
2. Rename to `argocd.exe` and put it in a folder that is in your PATH, or add that folder to PATH.

**Linux/macOS:**
```bash
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd && sudo mv argocd /usr/local/bin/
# macOS: use argocd-darwin-amd64 or argocd-darwin-arm64 in the URL
```

Close and reopen the terminal after installing, then run the login command below.

## 4. Login from your machine

```bash
argocd login localhost:8080 --username admin --password <password-from-above> --insecure
```

On Windows with a custom port (e.g. 62076):
```powershell
argocd login localhost:62076 --username admin --password YOUR_PASSWORD --insecure
```

Or if Argo CD is on 443:

```bash
argocd login localhost:443 --username admin --password <password> --insecure
```

## 5. Create the app (one-time, if not exists)

Create an Application that points at this repo, path **helm-chart** (or use the temp copy locally):

```bash
argocd app create argocd-testing-app \
  --repo https://github.com/YOUR_ORG/argocdnodejsapp.git \
  --path helm-chart \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace sardar
```

## 6. Test sync from a local temp copy (like the workflow)

```bash
# From repo root
export VERSION=1.0.99
mkdir -p deploy-temp
cp -r helm-chart deploy-temp/
sed -i "s/^  tag: .*/  tag: $VERSION/" deploy-temp/helm-chart/values.yaml   # Linux/macOS

argocd app sync argocd-testing-app --local-repo-root "$PWD/deploy-temp" --local helm-chart --force
argocd app wait argocd-testing-app --health --timeout 300
argocd app get argocd-testing-app --show-operation

rm -rf deploy-temp
```

## 7. GitHub Actions and local Argo CD

The workflow runs on GitHub’s runners, so **ARGOCD_SERVER** must be reachable from the internet. For local-only testing:

- Either run the steps above on your machine (no workflow), or  
- Expose your local Argo CD (e.g. ngrok, cloud tunnel) and set **ARGOCD_SERVER** in GitHub secrets to that URL.

For local testing, using the script above is enough; you don’t need to change the workflow.
