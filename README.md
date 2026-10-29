# 🚀 Thursday GKE App — Private Microservices Architecture

This repository contains a production-grade, decoupled, multi-tier microservices platform deployed on a fully private Google Kubernetes Engine (GKE) cluster.

The infrastructure, networking, container registry, database provisioning, and Kubernetes workloads are managed entirely declaratively using Terraform and automated end-to-end via a custom GitHub Actions CI/CD pipeline using a secure self-hosted runner.

---

## 🗺️ System Architecture

Our platform utilizes **Cross-Namespace Routing** with GKE's implementation of the modern **Kubernetes Gateway API** (`gateway.networking.k8s.io`). This allows multiple decoupled application teams to expose their services over different URL paths while sharing a single, cost-effective Google-managed Internal Layer 7 Load Balancer.

```
                         [ USER BROWSER ]
                                │
                                ▼ (Secure SSH Port-Forward Tunnel)
                     [ http://localhost:8080 ]
                                │
                                ▼ (Through Private Runner VM Bridge)
             [ GKE Shared Internal Gateway (gke-l7-rilb) ]
                   (Internal Load Balancer IP: 10.10.x.x)
                        /                     \
        Path: "/"      /                       \    Path: "/thursday"
                      ▼                         ▼
         [ Namespace: wordpress-app ]     [ Namespace: thursday-app ]
               WordPress Pod                    Thursday App Pod
                     │                                  │
                     ▼ (Port 3306)                      ▼ (Port 3306 - Private IP)
                [ MySQL Pod ]                     [ Managed Cloud SQL ]
```

### 🔒 Core Architectural & Security Pillars

1. **Zero Public Network Exposure (Private VPC):**
   The GKE control plane is fully private (`enable_private_endpoint = true`), and the GKE worker nodes have **no public IP addresses**. To perform administrative commands and manage deployments, we tunnel securely inside the VPC through a private **Compute Engine Bastion/Runner VM** utilizing Google's **Identity-Aware Proxy (IAP)**.
2. **Outbound-Only CI/CD (Self-Hosted Runner VM):**
   Our CI/CD pipeline does not accept any inbound traffic. Instead, the self-hosted runner VM sits in the private VPC subnet (`10.10.0.0/20`) and uses a secure **Cloud NAT Gateway** to establish an outbound-only long-poll connection over WebSockets to GitHub. This maintains an ironclad ingress firewall.
3. **Decoupled multi-tenant namespaces:**
   - **`gateway-infra`**: Manages global ingress routing (`internal-http-gateway` GKE Gateway).
   - **`wordpress-app`**: Hosts the public-facing WordPress front-end and a containerized MySQL backend database.
   - **`thursday-app`**: Hosts our new custom, lightweight database-writer web service.
4. **Declarative Secrets Management (GCP Secret Manager):**
   The Cloud SQL database is protected with a randomly generated, 16-character alphanumeric password. Terraform securely injects this directly into **GCP Secret Manager** (`thursday-db-password`). GKE workloads fetch this password at deploy-time using secure GCP data sources, mapping it directly into Kubernetes secrets—**passwords are never committed to Git, logged, or written to disk**.

---

## 📂 Repository Directory Structure

```text
thursday-gke/
├── .github/workflows/
│   ├── terraform-plan.yml      # CI pipeline (checks paths, validates syntax)
│   └── terraform-apply.yml     # CD pipeline (builds image, deploys infra + apps)
│
├── app-files/                  # Thursday Python web application files
│   ├── app.py                  # Lightweight Flask API writing to Cloud SQL
│   ├── Dockerfile              # Packages app.py with Gunicorn
│   └── requirements.txt        # Python app dependencies (Flask, PyMySQL, etc.)
│
├── foundation/                 # Network & GCS backend layer (applied once)
│   ├── backend.tf              # Points to GCS bucket under "thursday-foundation"
│   ├── cloudsql.tf             # Managed Private Cloud SQL MySQL 8.0 Instance
│   ├── registry.tf             # Artifact Registry Docker repo ("thursday-repo")
│   ├── secret-manager.tf       # Secret Manager container for database password
│   ├── iam.tf                  # Secure service accounts and WIF policy bindings
│   ├── providers.tf            # Google & Random provider configurations
│   ├── variables.tf            # Variables declarations
│   └── terraform.tfvars        # General configuration values
│
├── frontend/                   # Kubernetes app deployment layer (day-to-day)
│   ├── app.tf                  # Deployment, Service, and K8s secrets
│   ├── backend.tf              # Points to GCS bucket under "thursday-app-k8s"
│   ├── data.tf                 # Queries active GCP APIs to dynamically find GKE and SQL
│   ├── route.tf                # HTTPRoute mapping /thursday to thursday-service
│   ├── secret.tf               # Mounts GCP Secret Manager password as K8s Secret
│   ├── providers.tf            # GKE dynamic credential handshake
│   ├── variables.tf            # App variables declarations
│   └── terraform.tfvars        # App deployment variables
│
└── .gitignore                  # Shared gitignore to block local workspace caches
```

---

## 📡 Port-Forwarding & Local Testing Commands

Because your entire application and Gateway operate in a fully private network, your GKE shared gateway has no public IP address. To access the webpages on your local Mac's web browser, you must create a secure secure **SSH Port-Forwarding Tunnel** through your self-hosted runner VM:

### Step 1: Find GKE Gateway's Private IP
SSH into the private runner VM:
```bash
gcloud compute ssh gke-private-runner \
  --zone=us-east1-b \
  --project=modern-nation-510807-e9 \
  --tunnel-through-iap
```

Once inside the VM, query the GKE controller to obtain the private IP address of your Gateway:
```bash
kubectl get gateway -n gateway-infra
```
*Note the IP address listed in the **`ADDRESS`** column (e.g., `10.10.x.x`). Exit the VM.*
```bash
exit
```

### Step 2: Establish the SSH Port-Forward Tunnel
Run this command directly in your **local Mac terminal**, replacing `<INTERNAL_GATEWAY_IP>` with the IP address retrieved from the step above:
```bash
gcloud compute ssh gke-private-runner \
  --zone=us-east1-b \
  --project=modern-nation-510807-e9 \
  --tunnel-through-iap \
  -- -N -L 8080:<INTERNAL_GATEWAY_IP>:80
```
*Note: The `-N` flag tells SSH not to spawn a terminal shell but to keep the tunnel open in the background. Leave this terminal window running.*

### Step 3: Open Your Browser and Test Both Sites!
While the tunnel is running, open your web browser on your Mac and navigate to:

- 🌐 **To view your WordPress site:**  
  👉 [http://localhost:8080/](http://localhost:8080/)  
  *(Routes over the GKE gateway directly to your `wordpress-app` namespace)*

- 🚀 **To view your Thursday app and write to Cloud SQL:**  
  👉 [http://localhost:8080/thursday](http://localhost:8080/thursday)  
  *(Routes over GKE gateway to `thursday-app` namespace, writes "Maya" to Cloud SQL, and displays database rows in real time!)*
