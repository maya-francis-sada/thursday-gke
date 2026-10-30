
# 🚀 Thursday GKE App — Private Microservices Architecture (with TLS & HTTP Redirects)

This repository contains a production-grade, decoupled, multi-tier microservices platform deployed on a **fully private Google Kubernetes Engine (GKE) cluster**.

The infrastructure, private VPC peering, container registry, Cloud SQL database, Secret Manager integration, and Kubernetes Gateway API routing (including **TLS termination** and **HTTP-to-HTTPS redirects**) are managed declaratively using Terraform and deployed via a self-hosted GitHub Actions runner inside the private VPC.

---

## 🗺️ System & Traffic Flow Architecture

Our platform uses **Cross-Namespace Routing** with GKE's implementation of the **Kubernetes Gateway API** (`gateway.networking.k8s.io/v1`). Multiple decoupled application teams expose their services on different URL paths while sharing a single Google-managed **Regional Internal Application Load Balancer (`gke-l7-rilb`)**.

```text
                             [ USER WORKSTATION (Mac) ]
                                    │          │
       (HTTP Test: localhost:8080)  │          │  (HTTPS App: localhost:8443)
                                    ▼          ▼
              ══════════ [ GCP Cloud IAP Encrypted SSH Tunnel ] ══════════
                                    │          │
                                    ▼          ▼
                       [ Private Self-Hosted Runner VM ]
                         (Forwards 8080->80 & 8443->443)
                                    │          │
                                    ▼          ▼
         ┌────────────────────────────────────────────────────────────────┐
         │     GKE SHARED INTERNAL GATEWAY (Namespace: gateway-infra)     │
         │            (Regional Internal Envoy LB: 10.0.0.28)             │
         │                                                                │
         │  ┌──────────────────────────┐    ┌──────────────────────────┐  │
         │  │ Listener 1: HTTP (80)    │    │ Listener 2: HTTPS (443)  │  │
         │  │ sectionName: "http"      │    │ sectionName: "https"     │  │
         │  └────────────┬─────────────┘    └────────────┬─────────────┘  │
         └───────────────┼───────────────────────────────┼────────────────┘
                         │                               │
                         ▼                               ▼ (TLS Terminated via K8s Secret)
         ┌──────────────────────────────┐        ┌───────┴────────────────────────┐
         │ HTTPRoute: Redirect Filter   │        │   URL Map Path Evaluation      │
         │ Returns: 301 Moved Perm      │        └───┬────────────────────────┬───┘
         │ Location: https://...        │            │                        │
         └──────────────────────────────┘            │ Path: "/"              │ Path: "/thursday"
                                                     ▼                        ▼
                                      [ Namespace: wordpress-app ]  [ Namespace: thursday-app ]
                                         Service: wordpress:80        Service: thursday-service:8080
                                         (Direct NEG to Pod IP)       (Direct NEG to Pod IP)
                                                     │                        │
                                                     ▼ (Port 3306)            ▼ (Private Peering IP: 3306)
                                              [ MySQL Pod ]          [ Managed Cloud SQL Instance ]
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
│   ├── terraform-plan.yml      # CI pipeline (path checks, format, validate, plan)
│   └── terraform-apply.yml     # CD pipeline (applies infra, builds/pushes image, deploys K8s)
│
├── app-files/                  # Thursday Python web application source
│   ├── app.py                  # Flask app serving /thursday and /healthz, writing to Cloud SQL
│   ├── Dockerfile              # Container build instructions with Gunicorn
│   └── requirements.txt        # Python dependencies (Flask, PyMySQL, Cryptography, Gunicorn)
│
├── foundation/                 # Cloud Infrastructure layer (State prefix: thursday-foundation)
│   ├── backend.tf              # GCS remote state configuration
│   ├── cloudsql.tf             # Private Cloud SQL MySQL 8.0 instance & database module
│   ├── data.tf                 # GCP network and service account data lookups
│   ├── iam.tf                  # Cloud SQL client & Secret Manager IAM bindings
│   ├── providers.tf            # Google & Random provider configurations
│   ├── registry.tf             # Artifact Registry Docker repository
│   ├── secret-manager.tf       # Random password generator & GCP Secret Manager version
│   └── variables.tf            # Infrastructure input variables
│
├── frontend/                   # Kubernetes Deployment layer (State prefix: thursday-app-k8s)
│   ├── app.tf                  # Namespace, K8s Deployment, and NEG-enabled ClusterIP Service
│   ├── backend.tf              # GCS remote state configuration
│   ├── data.tf                 # Dynamic lookups for GKE cluster, Cloud SQL IP, and Secret Manager
│   ├── providers.tf            # Dynamic OAuth2 token handshake with private GKE master
│   ├── route.tf                # HTTPRoute binding /thursday to the Gateway's "https" listener
│   ├── secret.tf               # Injects GCP Secret Manager payload into K8s Secret
│   └── variables.tf            # Workload input variables (including image_tag)
│
├── .gitignore                  # Excludes .terraform caches, state files, and .tfvars
└── README.md                   # Project documentation
```

---

## 📡 Port-Forwarding & Local Testing Commands

Because your entire application and Gateway operate in a fully private network, your GKE shared gateway has no public IP address. To access the webpages on your local Mac's web browser, you must create a secure secure **SSH Port-Forwarding Tunnel** through your self-hosted runner VM:

### Step 1: Open the Dual-Port IAP SSH Tunnel
Run this command in your local Mac terminal and leave the window open:

```bash
gcloud compute ssh github-self-hosted-runner \
  --zone=us-east1-b \
  --project=modern-nation-510807-e9 \
  --tunnel-through-iap \
  -- -N -L 8080:10.0.0.28:80 -L 8443:10.0.0.28:443
```

### Step 2: Verify the HTTP-to-HTTPS `301` Redirect (Port 8080 $\rightarrow$ Port 80)
In a new terminal tab on your Mac, run `curl -I` against the plain HTTP tunnel port:

```bash
curl -I http://localhost:8080/thursday
```

**Expected Output:**
```http
HTTP/1.1 301 Moved Permanently
location: https://localhost:8080/thursday
date: Fri, 30 Oct 2026 06:48:38 GMT
via: 1.1 google
```
*(Note: In a local SSH tunnel, the browser cannot follow `https://localhost:8080` automatically because local port `8080` is mapped to plain HTTP port `80`. In production with standard DNS on ports `80`/`443`, the browser follows this redirect seamlessly).*

## 🔐 How TLS Termination & HTTP-to-HTTPS Redirects Work

### 1. Declarative TLS Key & Certificate Generation
Because the GKE cluster and internal load balancer live strictly inside a private RFC 1918 network (`10.0.0.28`) with no public DNS or internet exposure, public Certificate Authorities (like Let's Encrypt) cannot reach into the VPC to perform ACME challenges.
* Instead, Terraform dynamically generates a **2048-bit RSA Private Key** (`tls_private_key`) and a **Self-Signed X.509 Certificate** (`tls_self_signed_cert`).
* Terraform stores the certificate and private key inside a Kubernetes Secret (`type = "kubernetes.io/tls"`) named **`gateway-tls-cert`** in the `gateway-infra` namespace.

### 2. Dual-Listener Gateway Configuration
The shared `Gateway` (`internal-http-gateway`) configures two distinct listeners on the underlying Google Cloud Envoy proxy load balancer:
* **Listener 1 (`name: "http"`, Port `80`, Protocol `HTTP`):** Accepts unencrypted HTTP requests strictly for the purpose of redirecting clients to HTTPS.
* **Listener 2 (`name: "https"`, Port `443`, Protocol `HTTPS`):** References the `gateway-tls-cert` Kubernetes Secret with `tls.mode = "Terminate"`.
  * **Why Terminate at the Gateway?** The Google-managed Envoy proxy handles the heavy cryptographic SSL/TLS decryption at the edge of the cluster and forwards lightweight, unencrypted HTTP traffic over the private VPC network directly to the Pod IPs via **Network Endpoint Groups (NEGs)**.

### 3. Step-by-Step Packet Flow: HTTP Redirect vs. HTTPS Request

#### Flow A: When a User Requests `http://...` (Port 80 Redirect Flow)
1. **Packet Arrival:** The client sends a plain HTTP request to port `80` on the Internal Gateway.
2. **Listener Match:** The Gateway matches the request to the `sectionName = "http"` listener.
3. **Route Interception:** The `http-to-https-redirect` `HTTPRoute` (which is bound strictly to `sectionName = "http"`) intercepts the packet before it ever reaches a backend pod.
4. **301 Redirect Response:** The route's `RequestRedirect` filter immediately returns an **`HTTP/1.1 301 Moved Permanently`** status code with the response header `Location: https://<host>/<path>`.
   * *Why 301 instead of 302?* A `301` is a permanent redirect, instructing the browser to cache the redirect locally so future requests automatically use HTTPS without making an unencrypted network trip first.

#### Flow B: When a User Requests `https://...` (Port 443 Application Flow)
1. **TLS Handshake:** The client initiates a TLS handshake on port `443`. The Gateway's `https` listener presents the certificate from `gateway-tls-cert` and establishes an encrypted session.
2. **TLS Termination & L7 Inspection:** Envoy decrypts the payload and inspects the HTTP URI path:
   * If the path starts with **`/thursday`**, it matches `thursday-httproute` (bound to `sectionName = "https"` in the `thursday-app` namespace).
   * If the path starts with **`/`**, it matches `wordpress-httproute` (bound to `sectionName = "https"` in the `wordpress-app` namespace).
3. **Container-Native Load Balancing (NEG):** Using the `cloud.google.com/neg: '{"ingress": true}'` annotation on the Kubernetes Service, the Envoy proxy bypasses `kube-proxy` and NodePort hops entirely, routing the request directly to a healthy Pod's private IP (`10.20.x.x:8080`).
4. **Cloud SQL Write:** The Python Flask container reads its database credentials from in-memory environment variables (populated from **GCP Secret Manager**), connects to the **Cloud SQL Private IP** over the **Private Services Access (VPC Peering)** bridge, writes the visitor's name, and returns the rendered HTML table.
