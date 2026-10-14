# Azure Databricks Workshop Deployment Plan

**Status:** Deployed

## Validation

- Compile all Bicep templates.
- Run static diagnostics and security checks.
- Validate region and quota for `eastus2`.
- Run Azure deployment what-if before provisioning.
- Review RBAC role assignments and managed identities.

### All validation checks pass

- [x] AZD and Azure CLI are installed and authenticated.
- [x] `azure.yaml` passes schema validation.
- [x] AZD environment targets the approved subscription and `eastus2`.
- [x] `infra/main.bicep` compiles and passes linting.
- [x] Subscription-scope deployment validation passes.
- [x] Provision preview/what-if reports no deletes.
- [x] Subscription policies are retrieved and checked against the template.
- [x] Managed identity role assignments are statically verified for role, principal, and scope.
- [x] Validation commands and results are recorded below.

### Validation Proof

- Official `azure.yaml` schema validation: PASS.
- `az bicep build --file ./infra/main.bicep`: PASS.
- Azure CLI and AZD authentication: PASS as `admin@MngEnvMCAP975128.onmicrosoft.com`.
- Selected subscription and location: `a2140cfd-9b15-4e80-aa1c-aaf837f8f60b`, `eastus2`.
- ARM subscription state: `Enabled`.
- `az deployment sub validate`: PASS.
- `az deployment sub what-if`: PASS with 22 creates, 0 modifications, and 0 deletes.
- `azd provision --preview --no-prompt`: PASS; no resources were created.
- Azure Policy discovery: PASS; inherited deny policies do not conflict with the planned resource types or SKUs.

### Role Assignment Verification

- Identity: Databricks Access Connector system-assigned managed identity.
- Storage: `Storage Blob Data Contributor`, scoped to the workshop storage account.
- Key Vault: `Key Vault Secrets User`, scoped to the workshop vault.
- Event Hubs: `Azure Event Hubs Data Owner`, scoped to the workshop namespace.
- No generic subscription- or resource-group-level Contributor/Owner assignments are generated.

## Architecture

Provision Azure Databricks Premium, Access Connector, ADLS Gen2 Standard_LRS, Key Vault Standard with RBAC, Event Hubs Standard, and Log Analytics PerGB2018 in `rg-adb-workshop`.

## Deployment Proof

- Final subscription deployment `workshop-1791904469`: `Succeeded`.
- Databricks workspace `dbw-adbws-gnmdid`: Premium, no public IP, provisioning state `Succeeded`.
- Workspace URL: `https://adb-7405612219354661.1.azuredatabricks.net`.
- ADLS Gen2: hierarchical namespace enabled, shared-key access disabled, TLS 1.2, and five private workshop containers.
- Key Vault: RBAC, purge protection, soft delete, and 90-day retention enabled.
- Event Hubs: Standard, local authentication disabled, and four partitions on `workshop-events`.
- Log Analytics: `PerGB2018`, 30-day retention, with diagnostics connected for Storage, Key Vault, Event Hubs, and Databricks.
- Databricks exports `allLogs` and no metrics. Unsupported `AllMetrics` export was removed after the provider returned `Metric export is not enabled`.
- Live RBAC verification confirms the three planned resource-scoped roles for Access Connector principal `b20d58a4-3fce-4e80-9f65-9cdfc9781763`.
