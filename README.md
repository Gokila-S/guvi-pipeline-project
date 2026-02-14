# GUVI x KEC (Static Website) — Docker + Kubernetes + EKS (Terraform)

This repository contains a **static website** (HTML/CSS/JS) for the *GUVI x Kongu Engineering College* partnership, plus the infrastructure and deployment manifests to run it in containers and Kubernetes.

## 1) What’s in this repo?

- Static site
  - [index.html](index.html): Landing page (hero, partnership, programs, impact sections)
  - [programs.html](programs.html): Detailed programs page with category filters
  - [script.js](script.js): UI interactions (navbar, smooth scroll, counters, filters, scroll animations)
  - [styles.css](styles.css): All styling (single CSS file)
  - Images: `guvi.png`, `kec.png`

- Containerization
  - [Dockerfile](Dockerfile): Builds an nginx container that serves the static files

- Kubernetes manifests
  - [k8s/namespace.yaml](k8s/namespace.yaml): Namespace `myapp`
  - [k8s/deployment.yaml](k8s/deployment.yaml): Deployment `myapp` (2 replicas)
  - [k8s/service.yaml](k8s/service.yaml): ClusterIP service `myapp-service`
  - [k8s/ingress.yaml](k8s/ingress.yaml): Ingress routing `/` to the service

- AWS EKS provisioning (Terraform)
  - [eks-terraform/main.tf](eks-terraform/main.tf): VPC + EKS cluster + managed node group
  - [eks-terraform/providers.tf](eks-terraform/providers.tf): AWS provider configuration
  - [eks-terraform/variables.tf](eks-terraform/variables.tf): region + cluster name
  - [eks-terraform/outputs.tf](eks-terraform/outputs.tf): cluster endpoint/name outputs

## 2) Quick start (run locally)

Because this is a static site, you can run it without any backend.

### Option A — open directly

- Open [index.html](index.html) in a browser.

### Option B — serve via a local web server (recommended)

From the repo root:

PowerShell (Python 3):

```powershell
python -m http.server 8080
```

Then open:

- `http://localhost:8080/`

## 3) Run with Docker (nginx)

### Build

```powershell
docker build -t guvi-kec:local .
```

### Run

```powershell
docker run --rm -p 8080:80 guvi-kec:local
```

Open:

- `http://localhost:8080/`

### Notes

- The container serves the site on **port 80** internally (nginx).
- The Docker image includes `guvi.png` / `kec.png` so logos render in Docker/Kubernetes.

## 4) Kubernetes deployment (manifests in k8s/)

### Prerequisites

- A Kubernetes cluster
- `kubectl` configured to talk to it
- An Ingress controller if you plan to use Ingress (example manifests assume **nginx ingress**)

### Apply manifests

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

### Verify

```powershell
kubectl -n myapp get all
kubectl -n myapp describe ingress myapp-ingress
```

### Important: port alignment

- The Docker image built from [Dockerfile](Dockerfile) serves on **container port 80** (nginx).
- Kubernetes manifests in [k8s/](k8s/) are aligned to **80** (`containerPort: 80`, `targetPort: 80`).

## 5) Provision AWS EKS with Terraform (eks-terraform/)

### What Terraform creates

- A VPC with public + private subnets
- One NAT gateway
- An EKS cluster (Kubernetes 1.29)
- A managed node group (t3.medium, desired size 1)

### Prerequisites

- AWS account + credentials configured locally (`aws configure` or environment variables)
- Terraform installed

### Steps

From [eks-terraform/](eks-terraform/):

```powershell
terraform init
terraform plan
terraform apply
```

After apply, configure kubectl for the new cluster (AWS CLI required):

```powershell
aws eks update-kubeconfig --region ap-south-1 --name chandru-eks
```

Then you can apply the Kubernetes manifests from the repo root as shown in section 4.

### Variables

Defaults are defined in [eks-terraform/variables.tf](eks-terraform/variables.tf):

- `region`: `ap-south-1`
- `cluster_name`: `chandru-eks`

Override via `-var` or a `*.tfvars` file (note: `*.tfvars` is ignored by git per [.gitignore](.gitignore)).

## 6) Suggested workflow (from start to deployment)

1. Edit site content/styles in [index.html](index.html), [programs.html](programs.html), [script.js](script.js), [styles.css](styles.css)
2. Validate locally (section 2)
3. Containerize and validate in Docker (section 3)
4. Push image to a registry (Docker Hub / ECR) and update the image reference in [k8s/deployment.yaml](k8s/deployment.yaml)
5. Provision EKS with Terraform (section 5)
6. Deploy to Kubernetes (section 4)

## 7) CI/CD (GitHub Actions)

This repo includes GitHub Actions workflows under [.github/workflows/](.github/workflows/):

- [.github/workflows/deploy-ec2.yml](.github/workflows/deploy-ec2.yml): Deploys the published image to an EC2 instance via SSH.
- [.github/workflows/deploy-eks.yml](.github/workflows/deploy-eks.yml): Validates → builds/pushes Docker image → deploys to an **existing** EKS cluster.

### Required GitHub Secrets

Docker Hub:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

AWS (for EKS deploy):

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### EKS access note

The IAM principal used by GitHub Actions must be authorized to access the EKS cluster (Kubernetes RBAC). If deploy fails at `kubectl get nodes` / `kubectl apply` with authorization errors, map the IAM user/role to the cluster (via EKS access entries or the `aws-auth` ConfigMap depending on your cluster setup).

## 8) Common commands

- Check pods:
  ```powershell
  kubectl -n myapp get pods -o wide
  ```
- View pod logs:
  ```powershell
  kubectl -n myapp logs deploy/myapp
  ```
- Restart deployment:
  ```powershell
  kubectl -n myapp rollout restart deploy/myapp
  ```

  ---
