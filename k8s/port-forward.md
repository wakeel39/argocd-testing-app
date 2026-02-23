# Port-forward for node-app

Use the **resource type** and **name**; pods have auto-generated names.

**Option 1 – Forward to the Service (recommended)**  
Local port 9000 → service port 80 (which targets container 3000):

```bash
kubectl port-forward service/node-app-service -n sardar 9000:80
```

Then open: http://localhost:9000

**Option 2 – Forward to the Deployment**  
kubectl will pick a pod for you. Container listens on 3000:

```bash
kubectl port-forward deployment/node-app -n sardar 9000:3000
```

Then open: http://localhost:9000

**Option 3 – Forward to a specific Pod**  
First get the pod name, then forward:

```bash
kubectl get pods -n sardar -l app=node-app
kubectl port-forward pod/<pod-name> -n sardar 9000:3000
```

---

**Why `node-app` failed:**  
`kubectl port-forward node-app` is treated as “forward to **pod** named node-app”. There is no pod with that exact name; only the deployment is named `node-app`. Use `deployment/node-app` or `service/node-app-service` as above.
