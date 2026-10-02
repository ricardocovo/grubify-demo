# Azure Deployment Plan

> **Status:** Deployed

Generated: 2026-10-02

---

## 1. Project Overview

**Goal:** Include the Grubify application source reference in `ricardocovo/grubify-demo` and deploy its API and frontend images to the existing Azure Container Apps infrastructure in `rg-sre-lab`.

**Path:** Add Components

**Scope boundary:** Reuse the existing resource group, registry, Container Apps environment, monitoring, and two Container Apps. Do not provision duplicate infrastructure.

---

## 2. Requirements

| Attribute | Value |
|-----------|-------|
| Classification | POC |
| Scale | Small, fewer than 1,000 users |
| Budget | Cost-Optimized |
| Subscription | `demo` (`d93cb596-61e8-4f61-bb30-f5c7a265632b`) |
| Resource group | `rg-sre-lab` |
| Location | `eastus2` |
| Compliance | No additional requirements supplied; existing inherited policies remain in force |

The Azure target and environment profile are conservative defaults inferred from the explicit request to use the existing SRE lab. The interactive confirmation prompt reported that the user was unavailable.

### Policy Constraints

- Management-group deploy, modify, deny, and audit policy initiatives apply.
- MFA enforcement applies to Azure resource write and delete actions. Deployment may require an interactive MFA challenge.
- Existing security benchmark initiatives are inherited. This plan changes container images and application environment variables only.

---

## 3. Components Detected

| Component | Type | Technology | Planned Path |
|-----------|------|------------|--------------|
| Grubify API | API | .NET 9 Web API, Docker | `labs/starter-lab/src/grubify/GrubifyApi` |
| Grubify frontend | Frontend | React, TypeScript, nginx, Docker | `labs/starter-lab/src/grubify/grubify-frontend` |

### Source Integration

- Add `https://github.com/dm-chelupati/grubify.git` as a Git submodule at `labs/starter-lab/src/grubify`, pinned to the reviewed upstream commit.
- Add source provenance and CI checkout guidance near the starter lab documentation.
- Use a submodule because the upstream repository does not publish a license file. Do not copy/vendor the upstream files into this repository unless the upstream owner confirms redistribution permission.
- The existing `post-provision.sh` already detects this local path and builds both components from it.

---

## 4. Recipe Selection

**Selected:** AZCLI application update within the existing AZD/Bicep-managed lab

**Rationale:**

- The infrastructure already exists and is healthy; this deployment must not run a second infrastructure template or create `rg-grubify-app`.
- Azure Container Registry Tasks can build both images from the checked-out submodule without local Docker or a local .NET SDK.
- Direct, explicit image updates minimize blast radius while preserving the repository's existing AZD/Bicep ownership of infrastructure.
- Future CD can perform the same ACR builds and Container App updates after checking out submodules.

---

## 5. Architecture

**Stack:** Containers on existing Azure Container Apps

### Existing Service Mapping

| Component | Azure Service | Existing Resource / SKU |
|-----------|---------------|-------------------------|
| Grubify API | Azure Container Apps | `ca-grubify-etyxjwt7mh7dc`, Consumption, port 8080 |
| Grubify frontend | Azure Container Apps | `ca-grubify-fe-etyxjwt7mh7dc`, Consumption, port 80 |
| Image builds and storage | Azure Container Registry | `acrcagrubifyetyxjwt7mh7dc`, Basic |
| Runtime environment | Container Apps environment | `cae-etyxjwt7mh7dc` |

### Supporting Services

| Service | Purpose |
|---------|---------|
| Log Analytics | Existing centralized Container Apps logs |
| Application Insights | Existing application monitoring |
| Azure SRE Agent | Existing reliability investigation agent |

### Application Configuration

- API image: `acrcagrubifyetyxjwt7mh7dc.azurecr.io/grubify-api:<source-commit>`
- Frontend image: `acrcagrubifyetyxjwt7mh7dc.azurecr.io/grubify-frontend:<source-commit>`
- API environment: `ASPNETCORE_URLS=http://+:8080`, `ASPNETCORE_ENVIRONMENT=Production`, `API_VERSION=v1`, and `AllowedOrigins__0=<frontend-url>`.
- Frontend environment: `REACT_APP_API_BASE_URL=<api-url>/api`.
- Use immutable source-commit tags; do not rely only on `latest`.

---

## 6. Provisioning Limit Checklist

No new Azure resources will be provisioned. The operation builds two image repositories/tags and creates one new revision on each existing Container App.

| Resource Type | Number to Deploy | Total After Deployment | Limit/Quota | Notes |
|---------------|------------------|------------------------|-------------|-------|
| `Microsoft.App/managedEnvironments` | 0 | 1 | Not consumed by image update | Existing `cae-etyxjwt7mh7dc`; no environment creation |
| `Microsoft.App/containerApps` | 0 | 2 | Not consumed by image update | Both apps exist and are `Succeeded` |
| Container Apps consumption cores | 0 additional steady-state | 0.75 cores configured | 100 cores | `az containerapp env list-usages`; images retain current CPU allocations |
| Container App revisions | 2 transient new revisions | 2 active plus retained inactive revisions | Managed by single-revision deployment and cleanup policy | Each app currently has one active revision |
| ACR Basic storage | 2 image repositories/tags | Current usage 0 bytes plus image layers | 10 GiB included; 40 TiB maximum | `az acr show-usage` and official ACR limits |

**Quota API result:** The `quota` extension is installed, but `Microsoft.Quota` is not registered. Registering a subscription provider before plan approval was intentionally avoided. Environment usage and official service limits provide the non-mutating fallback.

**Status:** All planned updates are within available limits.

---

## 7. Execution Checklist

### Phase 1: Planning

- [x] Analyze workspace
- [x] Gather requirements using conservative POC defaults
- [x] Detect subscription and location
- [x] Inventory existing Azure resources
- [x] Check Azure Policy assignments
- [x] Check quota API, managed-environment usage, and ACR storage
- [x] Scan upstream app components and deployment requirements
- [x] Select deployment recipe
- [x] Plan architecture, verification, and rollback
- [x] User approved this plan

### Phase 2: Source Integration and Preparation

- [x] Add the pinned Grubify Git submodule at `labs/starter-lab/src/grubify`
- [x] Add source provenance and CI submodule checkout guidance
- [x] Verify API and frontend Docker build contexts
- [x] Verify local lab scripts resolve the submodule paths
- [x] Record upstream commit `6592accc6eef73e2d7c7339885386480cb49838f` for image tags
- [x] Update plan status to `Ready for Validation`

### Phase 3: Validation

- [x] Invoke the azure-validate workflow
- [x] All validation checks pass
	- [x] Validate Git/submodule state and source commit
	- [x] Run core validation: Azure CLI, authentication, Bicep compilation, template validation, and what-if
	- [x] Validate both Docker build contexts and required lock files
	- [x] Build both container images with ACR Tasks because local Docker is unavailable
	- [x] Validate Azure Policy assignments against the image-only update
	- [x] Validate ACR Tasks access and Container App registry configuration
	- [x] Review static RBAC assignments in Bicep
- [x] Record validation proof below and set status to `Validated`

### Phase 4: Deployment

- [x] Invoke the azure-deploy workflow
- [x] Build both immutable images with ACR Tasks
- [x] Confirm both image tags exist in ACR
- [x] Update the API Container App and verify health/API response
- [x] Update the frontend Container App and verify health/API integration
- [x] Verify revisions, logs, and endpoints
- [x] Record deployed image tags and endpoint URLs
- [x] Set plan status to `Deployed`

**Deployment result:**

- API revision: `ca-grubify-etyxjwt7mh7dc--0000002`, healthy and provisioned
- Frontend revision: `ca-grubify-fe-etyxjwt7mh7dc--0000001`, healthy and provisioned
- API endpoint: `https://ca-grubify-etyxjwt7mh7dc.agreeableriver-b5e2ee68.eastus2.azurecontainerapps.io`
- Frontend endpoint: `https://ca-grubify-fe-etyxjwt7mh7dc.agreeableriver-b5e2ee68.eastus2.azurecontainerapps.io`
- Both images use source tag `6592accc6eef73e2d7c7339885386480cb49838f`
- API `/api/restaurants` returned five records; the frontend rendered the same five restaurants
- Latest 50 console log lines for each app contained no matching startup, image-pull, CORS, crash, or HTTP 5xx errors
- Deployment inventory: zero new resources and no cleanup concerns

---

## 8. Validation Proof

| Check | Command Run | Result | Timestamp |
|-------|-------------|--------|-----------|
| Source pin | `git submodule status -- labs/starter-lab/src/grubify` | PASS: exact commit `6592accc6eef73e2d7c7339885386480cb49838f`; both Dockerfiles and frontend lockfile present | 2026-10-02 |
| Core Azure preflight | AZCLI `validate-deployment.ps1` at subscription scope | PASS: CLI, authentication, Bicep compile, ARM validation, and what-if | 2026-10-02 |
| Infrastructure drift guard | Subscription deployment what-if | PASS with warning: 3 create, 25 modify, 24 delete; do not apply Bicep for this image-only deployment | 2026-10-02 |
| API image build | ACR Task quick run `ch1` | PASS: `grubify-api:6592accc6eef73e2d7c7339885386480cb49838f`, digest `sha256:67bce1bcff17f475833324d08c10c755cf9eac61e9aa348656ca4957d5edb518` | 2026-10-02 17:52 UTC |
| Frontend image build | ACR Task quick run `ch2` | PASS: `grubify-frontend:6592accc6eef73e2d7c7339885386480cb49838f`, digest `sha256:d7b46a8bc2732bf1c35d0ddd9dc9cfaf788f72ca0abc7cd2402703e17236fc9c` | 2026-10-02 17:55 UTC |
| Azure Policy | Azure MCP `policy_assignment_list` | PASS: inherited governance/security initiatives reviewed; image update is compatible; MFA write enforcement applies | 2026-10-02 |
| Target resources | Azure MCP Container Apps and ACR queries | PASS: both apps are `Succeeded`; registry and credential-secret configuration present | 2026-10-02 |
| Static RBAC | Review of `subscription-rbac.bicep`, `sre-agent.bicep`, and `container-app.bicep` | PASS: app image pulls use existing ACR credential secrets; SRE Agent roles are separate from this update | 2026-10-02 |

**Validated by:** Azure validation workflow.

**Non-blocking upstream finding:** The frontend build completed successfully, but `npm ci` reported 64 dependency vulnerabilities (12 low, 14 moderate, 36 high, 2 critical). Dependency remediation is outside this deployment and should be tracked before production use.

---

## 9. Verification and Rollback

### Verification

1. Confirm ACR contains API and frontend tags matching the pinned source commit.
2. Confirm both Container Apps reach `provisioningState=Succeeded` and the new revisions become active.
3. Request the API restaurants endpoint and require a successful JSON response.
4. Request the frontend root and require HTTP 200 with Grubify content.
5. Exercise frontend-to-API restaurant loading and add-to-cart flow.
6. Inspect Container Apps logs for startup, CORS, image-pull, and HTTP errors.

### Rollback

1. Record the currently active revision and image before each update.
2. If a health check fails, reactivate the prior revision or restore its image before proceeding.
3. Current pre-deployment images are:
	- API: `mcr.microsoft.com/dotnet/samples:aspnetapp`
	- Frontend: `mcr.microsoft.com/azuredocs/containerapps-helloworld:latest`
4. A frontend update is blocked until API verification passes.

---

## 10. Files to Generate or Modify

| File | Purpose | Status |
|------|---------|--------|
| `.azure/deployment-plan.md` | Deployment source of truth | Deployed |
| `.azure/deploy-result.json` | Deployment inventory and endpoint record | Added |
| `.gitmodules` | Pin the separate Grubify source repository | Added |
| `labs/starter-lab/src/grubify` | Gitlink pinned to reviewed application source | Added |
| `labs/starter-lab/README.md` | Source provenance and CI/CD checkout guidance | Updated |

No infrastructure file changes are planned.

---

## 11. Approval

> Current phase: Deployment completed and verified.

The approved plan was executed without provisioning or deleting Azure resources.
