# Code incident demo: investigate, then hand off to Ricardo

This is an opt-in, intentionally broken checkout build for the demo lab only.
The normal build remains healthy. Credit-card checkout returns HTTP 500 because
of a source-code defect; health, browsing, carts, and cash-on-delivery remain
available. Payments are simulated; never enter real card details.

The source under investigation is `PaymentMethodRegistry.cs` in this directory,
copied into the API by the demo build. The extra integration change is in
`../patches/grubify-demo-incident.patch`. Ricardo should implement the correction
in this repository and rebuild the demo source, rather than changing upstream.

## Guardrails before generating errors

From PowerShell 7:

```powershell
.\labs\starter-lab\scripts\configure-demo-rca.ps1 `
  -ResourceGroup rg-sre-lab `
  -AgentName sre-agent-etyxjwt7mh7dc `
  -BackupDirectory C:\Temp\grubify-demo-backup
```

This backs up settings, removes the lab agent identity's Monitoring Contributor
and Container Apps Contributor assignments, verifies reader-only roles, selects
Review mode, and routes the HTTP alert to `demo-rca`. Global tool policy denies
remediation, terminal execution, incident updates/resolution, and code writes.
GitHub issue creation is explicitly allowed; other unlisted tools require review.
Do not approve any remediation request. The GitHub OAuth connector must already
be healthy with issue-creation access to `ricardocovo/grubify-demo`.

The alert is set to `autoMitigate=false` for this controlled demonstration, so
stopping test traffic does not automatically clear the alert. This is a stateless
alert: repeated traffic can generate additional notifications. No continuous load
generator or scheduled fault is installed. Restore normal alert behavior after
the demo using the backed-up configuration.

## Build the opt-in incident image

From Git Bash in `labs/starter-lab`:

```bash
bash scripts/prepare-grubify-source.sh /tmp/grubify-code-demo --demo-incident
az acr build --registry acrcagrubifyetyxjwt7mh7dc \
  --image grubify-api:code-incident-demo \
  --file /tmp/grubify-code-demo/GrubifyApi/Dockerfile \
  /tmp/grubify-code-demo/GrubifyApi
```

Deploy the resulting immutable image digest to `ca-grubify-etyxjwt7mh7dc` only.
Do not deploy the fault to another environment. Keep `API_VERSION=v1`; the
checkout defect is compiled code, not the separate v2 payment-failure scenario.

## Trigger and present

After the demo image is healthy:

```powershell
.\labs\starter-lab\scripts\trigger-demo-incident.ps1 `
  -BaseUrl https://ca-grubify-etyxjwt7mh7dc.agreeableriver-b5e2ee68.eastus2.azurecontainerapps.io
```

The script sends only eight checkout requests over about 70 seconds. The existing
alert threshold is more than five 5xx responses in five minutes. Allow time for
metric ingestion and the one-minute alert evaluation.

1. Open the Grubify frontend and demonstrate credit-card checkout using fake data.
2. Open Azure SRE Agent, select `sre-agent-etyxjwt7mh7dc`, and open the new incident.
3. Show Review mode, the read-only investigation evidence, and the GitHub issue
   link produced by the agent in `ricardocovo/grubify-demo`.
4. Hand off to Ricardo. The issue should contain RCA, source links, the proposed
   code diff and regression tests; the agent must not apply the fix or close
   the incident. An investigation finishing is not an incident resolution.

## Human-only recovery

The last verified healthy image before this demo is:

```text
acrcagrubifyetyxjwt7mh7dc.azurecr.io/grubify-api@sha256:9836310ca492ff2c45fed13fcc81e727d94fd755ddf00d97a4bb59922df7381f
```

For emergency recovery, a human can deploy that image with `az containerapp update`.
For the intended demonstration, Ricardo should fix the code, build a new image,
verify all three payment methods and the existing regression tests, and close the
incident manually. Carts/orders are in-memory demo state and reset on deployment.
Do not restore contributor permissions merely to close out the demo.
