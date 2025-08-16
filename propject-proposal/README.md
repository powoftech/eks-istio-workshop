# Container Registry Security with Vulnerability Scanning and Policy Enforcement

## Securing the container supply chain on AWS with ECR scanning, Kyverno admission policies, and Falco runtime detection

---

## Executive Summary

Modern software delivery increasingly depends on containers and Kubernetes. While containers accelerate development, they also expand the attack surface across the CI pipeline, images, registries, clusters, and runtime. This proposal delivers an opinionated, end-to-end security solution for a Kubernetes application on AWS that prevents vulnerable or non-compliant images from being deployed and detects threats at runtime.

The solution integrates:

- Amazon ECR with enhanced vulnerability scanning (via Amazon Inspector) to identify CVEs early.
- Policy-as-code using Kyverno to enforce admission controls (e.g., disallow :latest, require non-root).
- Runtime threat detection with Falco to surface suspicious activity in the cluster.
- A secure CI workflow that builds, scans, signs/tags, and gates promotions before deploy.

Business benefits:

- Reduced risk of security incidents and non-compliant deployments.
- Faster, safer releases with automated guardrails.
- Lower mean time to detect (MTTD) and respond (MTTR) to runtime threats.
- Clear audit trails for governance and stakeholder confidence.

This project implements the above using the sample application in [app/app.js](/app/app.js), containerized by [app/Dockerfile](/app/Dockerfile), deployed with Kubernetes manifests in [k8s/deployment.yaml](/k8s/deployment.yaml) and [k8s/service.yaml](/k8s/service.yaml), and protected by Kyverno policies in [k8s/policy-disallow-latest-tag.yaml](/k8s/policy-disallow-latest-tag.yaml) and [k8s/policy-require-non-root.yaml](/k8s/policy-require-non-root.yaml). The CI workflow is orchestrated via GitHub Actions defined in [.github/workflows/ci.yaml](/.github/workflows/ci.yaml).

This proposal follows the structure and grading rubric defined in the FCJ Internship guidelines at [propject-proposal/template.md](/propject-proposal/template.md).

---

## 1. Problem Statement

### Current Situation

- Teams often push images to a registry without consistent vulnerability scanning or policy checks.
- Clusters accept deployments that use insecure defaults (e.g., running as root, mutable latest tags).
- Runtime anomalies (crypto-mining, privilege escalations) are hard to detect quickly.

### Key Challenges

- Lack of automated, enforceable security controls in CI/CD and admission.
- Inconsistent image hygiene and drift across environments.
- Limited runtime visibility and alerting for container workloads.

### Stakeholder Impact

- Security/Compliance: Increased audit exposure and potential policy violations.
- Engineering: Slower incident response, rework from late-stage findings.
- Business: Reputational risk, possible downtime, and increased operational cost.

### Business Consequences

- Higher probability of breaches and CVE exploitation.
- Costly remediation and potential regulatory penalties.
- Slower releases due to manual checks and inconsistent practices.

---

## 2. Solution Architecture

![Architecture Diagram](/.hugo/assets/images/architecture-diagram-bordered.png)

### Architecture Overview

- Source and CI
  - GitHub repository triggers pipeline in [.github/workflows/ci.yaml](/.github/workflows/ci.yaml).
  - CI builds the container from [app/Dockerfile](/app/Dockerfile), runs unit/security checks, and pushes to ECR.
- Registry and Scanning
  - Amazon ECR repository with enhanced scanning (Amazon Inspector) scans images on push and on a schedule.
- Admission Controls
  - Kyverno in EKS enforces policies: block images with tag latest, require non-root, and other baseline hardening via [k8s/policy-disallow-latest-tag.yaml](/k8s/policy-disallow-latest-tag.yaml) and [k8s/policy-require-non-root.yaml](/k8s/policy-require-non-root.yaml).
- Deployment
  - Workloads defined in [k8s/deployment.yaml](/k8s/deployment.yaml) and [k8s/service.yaml](/k8s/service.yaml).
- Runtime Detection
  - Falco monitors system calls and Kubernetes audit events to alert on suspicious behaviors.

### AWS Services Used

- Amazon ECR: Private container registry and vulnerability scanning.
- Amazon EKS: Managed Kubernetes control plane.
- Amazon EC2: Worker nodes for the EKS cluster.
- (Optional) Amazon CloudWatch: Centralized logs and metrics.
- (Optional) AWS IAM: Fine-grained access control for CI and cluster components.
- (Optional) AWS KMS/SSM Parameter Store: Secrets and key management.

### Component Design

- CI builds, tags with immutable semantic versions, signs/tags as “passed-scan” only when no high/critical CVEs remain.
- Admission denies non-compliant images or manifests that breach policies.
- Falco alerts route to logs or notification channels for triage.

### Security Architecture

- Shift-left scanning at build and registry push.
- Policy enforcement at admission with Kyverno.
- Runtime detection with Falco and audit trails in CloudWatch (optional).
- Principle of least privilege (IAM roles for service accounts).

### Scalability Design

- EKS node groups scale with application demand.
- ECR scales with artifact count; lifecycle policies control retention.
- Policies and Falco rules remain consistent across environments.

---

## 3. Technical Implementation

### Implementation Phases

1. Foundation
   - Provision ECR and EKS (IaC optional).
   - Configure Amazon Inspector enhanced scanning for ECR.
2. CI Pipeline
   - Implement build/test/scan/push in [.github/workflows/ci.yaml](/.github/workflows/ci.yaml).
3. Admission Controls
   - Install Kyverno and apply policies:
     - [k8s/policy-disallow-latest-tag.yaml](/k8s/policy-disallow-latest-tag.yaml)
     - [k8s/policy-require-non-root.yaml](/k8s/policy-require-non-root.yaml)
   - Validate with:
     - [k8s/test-non-root-container-level.yaml](/k8s/test-non-root-container-level.yaml)
     - [k8s/test-non-root-pod-level.yaml](/k8s/test-non-root-pod-level.yaml)
     - [k8s/test-root-pod.yaml](/k8s/test-root-pod.yaml)
4. Runtime Detection
   - Install Falco and verify alerting.
5. Application Deployment
   - Deploy via [k8s/deployment.yaml](/k8s/deployment.yaml) and [k8s/service.yaml](/k8s/service.yaml).
6. Documentation
   - Reference workshop guides:
     - [.hugo/content/provision-eks-cluster-and-ecr-repository/\_index.en.md](/.hugo/content/provision-eks-cluster-and-ecr-repository/_index.en.md)
     - [.hugo/content/create-secure-buildable-application-and-ci-workflow/\_index.en.md](/.hugo/content/create-secure-buildable-application-and-ci-workflow/_index.en.md)
     - [.hugo/content/install-and-configure-kyverno-as-cluster-gatekeeper/\_index.en.md](/.hugo/content/install-and-configure-kyverno-as-cluster-gatekeeper/_index.en.md)
     - [.hugo/content/install-and-test-falco-for-runtime-threat-detection/\_index.en.md](/.hugo/content/install-and-test-falco-for-runtime-threat-detection/_index.en.md)

### Technical Requirements

- Kubernetes 1.27+ on EKS.
- GitHub Actions with OIDC to assume an IAM role for ECR push and EKS deploy.
- Immutable image tagging; lifecycle policies in ECR.

### Development Approach

- Trunk-based development with protected main branch.
- Policy-as-code and security-as-code in repo under [k8s](/k8s/).

### Testing Strategy

- CI: unit tests for [app/app.js](/app/app.js), Docker build and basic smoke tests.
- Security: ECR scan gate on high/critical CVEs; policy tests using the manifests in [k8s](/k8s/).
- Integration: deploy to a dev namespace and run probes.

### Deployment Plan

- Dev → Staging → Prod promotion controlled by tags and policy checks.
- Rollback via previous immutable image tag and Kubernetes rollout undo.

---

## 4. Timeline & Milestones

### Project Timeline (4–5 weeks)

- Week 1: EKS/ECR provisioning; CI bootstrap.
- Week 2: CI security gates; push to ECR with scans.
- Week 3: Kyverno install and policy enforcement; validation tests.
- Week 4: Falco deployment; alert routing; run end-to-end drills.
- Week 5: Documentation, tuning, and sign-off.

### Key Milestones

- M1: EKS/ECR ready and CI builds passing.
- M2: ECR enhanced scans gating deployments.
- M3: Kyverno policies blocking non-compliant manifests.
- M4: Falco producing actionable alerts.
- M5: Final demo and documentation complete.

### Dependencies

- AWS account access and permissions.
- GitHub Actions OIDC and IAM role setup.
- DNS/logging destinations (if alerting to external systems).

### Resource Allocation

- 1–2 engineers part-time; 1 security reviewer for policy review.

---

## 5. Budget Estimation

Note: Validate with AWS Pricing Calculator for your region and usage.

- EKS control plane: ~$74/month per cluster.
- 2× t3.medium worker nodes for dev: ~$40–50/month each (on-demand), ~$80–100/month total.
- ECR storage: ~$0.10/GB-month (assume 10 GB → ~$1/month) plus data transfer.
- ECR enhanced scanning (Amazon Inspector): per-image scanning cost; assume 200 image scans/month → budget ~$20–30.
- CloudWatch logs/metrics (optional): ~$10–20 for dev scale.
- Total dev-scale estimate: ~$185–225/month.

One-time development costs: engineering effort for setup and policy creation (internal).

ROI Analysis:

- Avoided incidents and downtime reduce potential losses (often far exceeding monthly costs).
- Automated gates reduce rework and manual review time by 20–30% for releases.
- Faster MTTR with Falco reduces outage impact.

Cost Optimization:

- Use small dev node groups; scale to zero for non-working hours.
- Image lifecycle policies in ECR to minimize storage.
- Rightsize nodes and consider Spot for non-prod.

---

## 6. Risk Assessment

### Risk Matrix (examples)

- Misconfigured policies block valid deployments (Likelihood: M, Impact: M).
- False negatives in vulnerability scans (L, H).
- Falco noise/false positives (M, M).
- IAM misconfig leading to over-privilege (L, H).
- Supply chain risk from third-party base images (M, H).

### Mitigation Strategies

- Stage policies in audit mode before enforce; use test manifests:
  - [k8s/test-non-root-container-level.yaml](/k8s/test-non-root-container-level.yaml)
  - [k8s/test-non-root-pod-level.yaml](/k8s/test-non-root-pod-level.yaml)
  - [k8s/test-root-pod.yaml](/k8s/test-root-pod.yaml)
- Pin and regularly update base images; SBOM generation in CI.
- Tune Falco rules and alert thresholds; route to a triage channel.
- Least privilege IAM; periodic access reviews.

### Contingency Plans

- Rapid rollback with immutable tags and Kubernetes rollout undo.
- Temporary policy exceptions via documented change control.
- Fallback monitoring via CloudWatch and manual inspection.

---

## 7. Expected Outcomes

### Success Metrics

- 100% images scanned; 0 high/critical CVEs deployed.
- 100% workloads pass Kyverno policies (no :latest, no root).
- Time-to-detect suspicious runtime events < 5 minutes.
- Deployment lead time unchanged or improved versus baseline.

### Business Benefits

- Reduced breach risk and audit findings.
- Faster, safer deployments with automated gates.
- Clear governance and evidence for compliance.

### Technical Improvements

- Standardized image hygiene and immutable tags.
- Policy-as-code baseline for all namespaces.
- Actionable runtime telemetry.

### Long-term Value

- Extensible framework to add signing/verification (e.g., Sigstore), SBOMs, and additional policies.
- Reusable guardrails for other services and teams.

---

## Appendices

## A. Technical Specifications

- Application: [app/app.js](/app/app.js), [app/Dockerfile](/app/Dockerfile)
- K8s Manifests: [k8s/deployment.yaml](/k8s/deployment.yaml), [k8s/service.yaml](/k8s/service.yaml)
- Policies: [k8s/policy-disallow-latest-tag.yaml](/k8s/policy-disallow-latest-tag.yaml), [k8s/policy-require-non-root.yaml](/k8s/policy-require-non-root.yaml)
- CI Workflow: [.github/workflows/ci.yaml](/.github/workflows/ci.yaml)

## B. Cost Calculations

- Keep calculator exports and assumptions; review monthly.

## C. Architecture Diagrams

- High-level system and deployment diagrams (draw.io).

## D. References
