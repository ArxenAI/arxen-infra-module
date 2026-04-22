# Arxen Infrastructure Modules — A Plain-Language Guide

> This document is written for anyone — business stakeholders, product managers, designers, or curious newcomers — who wants to understand what this repository does, why it exists, and why it matters. No prior technical knowledge is required.

---

## What Problem Are We Solving?

Imagine that every time a new team at Arxen needed to build a product, they had to construct their own house from scratch — laying their own foundation, running their own electrical wiring, building their own plumbing. Every house would look different, have different safety standards, and be prone to the same preventable mistakes over and over again.

That is exactly what happens when software teams build cloud infrastructure without shared standards. Every team ends up reinventing the wheel, often making different (sometimes dangerous) choices about security, naming, and reliability.

**This repository is the solution.** It is a library of pre-built, pre-approved, pre-secured "building blocks" that any Arxen team can pick up and use to deploy their product — confident that every safety requirement is already baked in.

---

## What Is "Cloud Infrastructure"?

When you use any modern app — a banking app, a streaming service, a SaaS platform — that app is running on servers owned by a cloud provider like Microsoft Azure, Amazon Web Services (AWS), or Google Cloud. These providers rent computing power, storage, databases, and networking to companies so that those companies don't have to own physical hardware.

Managing all of these cloud resources — deciding which ones to use, how to configure them, how to connect them, and how to keep them secure — is called **cloud infrastructure management**.

---

## What Is "Infrastructure as Code"?

Traditionally, someone would log into the cloud provider's website and click buttons to set up a database, a network, a server. This is error-prone, hard to repeat, and impossible to audit.

**Infrastructure as Code (IaC)** means writing those configuration instructions down as files, just like writing a recipe instead of improvising in the kitchen. The tool this project uses is called **OpenTofu** (an open-source version of the popular tool Terraform).

With IaC:
- Every change is reviewed by a human before it is applied, just like code review for software.
- The history of every change is stored in Git (a version control system), so you always know who changed what and when.
- The same configuration can be applied identically to multiple environments (development, staging, production) without manual steps.

---

## What Are "Golden Paths"?

A **Golden Path** is an opinionated, pre-approved way of doing something. Instead of asking each team to figure out the right way to set up a database, we provide one correct, secure way — and all teams use that.

This concept comes from large engineering organizations (Netflix, Spotify, and others coined it) and it works because:

- Teams move faster — they don't spend time researching best practices from scratch.
- Security is guaranteed — the approved configuration already has all the right controls.
- Compliance is easier — auditors can verify one standard, not a hundred different approaches.

This repository **is the Arxen Golden Path library** for cloud infrastructure.

---

## What Is This Repository, Exactly?

This repository (`arxen-infra-module`) contains a collection of **modules** — reusable building blocks — for cloud infrastructure on Microsoft Azure (with AWS and Google Cloud planned for the future).

Think of each module like a LEGO brick. A brick has a standard shape and connector so it can fit with any other brick. Each module here has a standard interface so it can connect with other modules cleanly. You assemble the bricks together to build an environment for a product.

The repository does **not** contain any live infrastructure. It only contains the blueprints. A separate repository (`arxen-infra-live`) uses these blueprints to actually build real environments.

---

## The Building Blocks: What Each Module Does

Here is a plain-language explanation of every module currently available.

### Networking — `azure/vnet`
**The Roads and Plumbing**

Before you can put anything in the cloud, you need a network — a private, isolated space where your resources can talk to each other safely. This module creates that private network (called a Virtual Network, or VNet) with four dedicated "lanes" (subnets):

- One lane for the application servers (compute nodes).
- One lane for the containers those servers run.
- One lane for secure connections to databases and other services.
- One lane for the front door (the gateway that faces the internet, when needed).

Every lane has a firewall (called a Network Security Group) attached by default, blocking all unexpected inbound traffic from day one. Nothing on the public internet can reach the private network unless explicitly allowed.

---

### Application Platform — `azure/aks`
**The Operating System for Your Applications**

Modern applications are packaged as **containers** — lightweight, self-contained boxes that include everything the app needs to run. **Kubernetes** is the industry-standard system for running, scaling, and managing thousands of containers across many servers.

This module provisions a **managed Kubernetes cluster** (Azure Kubernetes Service, or AKS) — the backbone that runs all Arxen applications. Key protections that are always turned on:

- **Private cluster:** The control panel of the cluster is not reachable from the public internet. Only internal network access is allowed.
- **No static passwords:** Applications running inside the cluster prove their identity to other Azure services using a modern, token-based system (Workload Identity) instead of usernames and passwords stored in files.
- **Policy enforcement:** A built-in policy engine rejects any workload that violates security rules before it even starts running.
- **Always-on audit log:** Every action taken inside the cluster is logged and sent to the monitoring system.

---

### Secrets Safe — `azure/keyvault`
**The Vault**

Every application needs secrets: database passwords, API keys, encryption keys. Storing these in code files or emails is one of the most common causes of security breaches.

This module creates an **Azure Key Vault** — a hardened, access-controlled safe for all secrets. Rules that are always enforced:

- The vault is never accessible over the public internet; only internal network traffic can reach it.
- If a secret is accidentally deleted, it is recoverable for 90 days (soft delete).
- Permanent deletion of the vault itself requires explicit, additional approval (purge protection).
- Access is controlled with individual permissions — no "master key" that opens everything.

---

### Container Registry — `azure/acr`
**The Private App Store**

When you build an application as a container, the container image (the packaged app) needs to be stored somewhere before it can be deployed to Kubernetes. This module creates a private **Azure Container Registry (ACR)** — think of it as a private app store that only the Arxen platform can access.

Public access is permanently disabled. The Kubernetes cluster is the only thing allowed to pull images from this registry, and it authenticates using its managed identity (no passwords).

---

### Storage — `azure/storage`
**The File Cabinet in the Cloud**

Applications often need to store files: uploaded documents, AI training datasets, logs, backups. This module creates a private **Azure Storage Account** for blob (binary large object) storage — the cloud equivalent of a file cabinet.

All data is encrypted. Access is only possible over the private internal network, never over the public internet.

---

### Database — `azure/postgresql`
**The Structured Filing System**

Most applications store structured data (user records, transaction history, configuration) in a relational database. This module provisions an **Azure PostgreSQL** database — a managed, enterprise-grade database.

Key protections always enabled:

- **No public access:** The database cannot be reached from the internet, ever.
- **Encrypted connections:** All data in transit is encrypted (SSL/TLS enforced).
- **Automated backups:** Data is backed up for 35 days with geographic redundancy in staging and production environments, so a regional failure does not cause data loss.

---

### Monitoring — `azure/observability`
**The Health Dashboard and Security Cameras**

You cannot fix what you cannot see. This module sets up the monitoring foundation for every Arxen environment:

- **Azure Log Analytics Workspace:** A central place where all logs from the cluster, the database, the vault, and the applications flow. Think of it as a searchable archive of everything that happened.
- **Application Insights:** Real-time performance monitoring for applications — like a health dashboard showing response times, error rates, and usage patterns.

Logs are retained for a configurable number of days. All downstream modules (AKS, Key Vault, Storage) send their logs here automatically.

---

### AI / Machine Learning Workspace — `azure/ai-workspace`
**The AI Lab**

For teams building AI-powered features, this module provisions an **Azure Machine Learning Workspace** — a managed environment for training models, running experiments, and deploying AI services.

It connects all the other building blocks together: secrets are stored in Key Vault, datasets live in Storage, container images come from the Container Registry. Public access is disabled by default. The workspace authenticates to other Azure services using a managed identity — no credentials stored anywhere.

---

### Kubernetes Namespace — `common/k8s-namespace`
**The Office Floor Plan**

Inside the Kubernetes cluster, applications are organized into **namespaces** — isolated compartments. This module creates a namespace with security defaults:

- By default, no traffic can enter the namespace from other parts of the cluster (deny-all inbound policy).
- Teams are given either "viewer" (read-only) or "editor" (read/write) access to their namespace — nothing more.

This module works with any cloud (Azure, AWS, GCP) because it operates inside Kubernetes, not at the cloud level.

---

### Kubernetes Labels — `common/k8s-labels`
**The Labeling System**

Every resource in Kubernetes (every running app, every configuration file, every service) can carry labels — metadata tags. This utility module generates a standardized set of labels that every Arxen resource must carry, so that:

- Any team can find resources belonging to a specific application or team with a single query.
- Cost attribution and billing are accurate.
- Monitoring dashboards can filter by any dimension (team, environment, application).

This module creates no cloud resources — it is purely a tool for enforcing naming consistency.

---

## How the Modules Connect Together

The modules are designed to be assembled in a specific order because each one depends on the previous. Here is the typical sequence for deploying a full Arxen environment:

```
1. Networking (vnet)          — creates the private network
         ↓
2. Monitoring (observability) — creates the log destination
         ↓
3. Secrets Safe (keyvault)    — creates the vault
4. Storage (storage)          — creates the file cabinet
5. Registry (acr)             — creates the container store
         ↓ (steps 3-5 can run in parallel)
6. Database (postgresql)      — creates the database
7. AI Lab (ai-workspace)      — wires keyvault + storage + acr together
         ↓
8. Cluster (aks)              — wires networking + monitoring together
         ↓
9. Namespace (k8s-namespace)  — creates isolated app compartments inside the cluster
```

No module hardcodes the output of another — they are connected by passing outputs explicitly, so the whole stack is traceable and auditable.

---

## Security Philosophy

Every module in this library follows a "**secure by default**" philosophy. This means:

- The most secure configuration is the default. Teams have to explicitly opt out of security controls (and only for development environments), not opt in.
- No wildcard permissions. Access grants are always specific to the exact resource needed.
- Encryption everywhere. Data at rest and data in transit is always encrypted.
- Private networking by default. No resource is publicly reachable unless it is explicitly designed to be (like a load balancer).
- No stored credentials. Services authenticate to each other using managed identities — automatically rotated tokens managed by Azure, with no passwords that can leak.

These controls are **non-negotiable** — they cannot be disabled by the teams consuming these modules. This is a deliberate design choice: the platform team takes on the security burden so that product teams don't have to think about it.

---

## Versioning: Stability and Safety

Every module is versioned using **semantic versioning** (e.g., `v2.1.0`). This works like software versions:

| Change Type | Version Bump | Meaning |
|---|---|---|
| Breaking change (e.g., renamed a required setting) | MAJOR (v2 → v3) | Teams must update their usage |
| New optional setting added | MINOR (v2.1 → v2.2) | Backwards compatible, teams can adopt at their own pace |
| Bug fix or documentation update | PATCH (v2.1.0 → v2.1.1) | Safe to apply immediately |

Teams that use these modules pin to a specific version. They will never have an unexpected change forced on them — upgrades are always explicit decisions.

---

## What's Coming Next

The current modules cover **Microsoft Azure** (the MVP cloud provider). The roadmap mirrors the exact same catalog for two additional clouds:

- **Amazon Web Services (AWS):** EKS (Kubernetes), VPC (networking), Secrets Manager, ECR (container registry), S3 (storage), RDS (database), Bedrock (AI).
- **Google Cloud Platform (GCP):** GKE (Kubernetes), VPC, Secret Manager, Artifact Registry, GCS (storage), Cloud SQL (database), Vertex AI (AI).

When these are added, the same interface contract applies — meaning a team can switch cloud providers by changing a single line in their configuration, with all the same security guarantees.

---

## Summary

| What | Why |
|---|---|
| Pre-built, reusable building blocks for cloud infrastructure | So every team starts from a secure, proven foundation instead of guessing |
| Secure by default — controls are locked, not optional | So security is guaranteed, not hoped for |
| Versioned and audited like software | So changes are predictable and every configuration is traceable |
| Modular and composable | So teams assemble only what they need, nothing more |
| Cloud-agnostic design | So Arxen is not locked into a single cloud provider forever |

This repository is the foundation that everything in the Arxen platform stands on.
