# Copilot Agents Cheat Sheet - AI Operations Workshop

## Overview
This cheat sheet provides a quick reference for workshop proctors on the different Copilot agents and their key commands/tasks used throughout the AI Operations Workshop.

---

## 1. Copilot in Azure Portal

### Context: Resource Group Analysis
**Location:** Azure Portal → Resource Group Overview

#### Key Prompts:
```text
Write a query that finds all changes for last 7 days.
```
**Expected:** KQL query for resource changes

```text
Are there any service alerts impacting this resource group?
```
**Expected:** Service health status report

```text
What is the current health status of my AKS cluster?
```
**Note:** Cancel when prompted (do from AKS context instead)

---

### Context: AKS Cluster Resource
**Location:** Azure Portal → AKS Cluster Overview

#### Health & Status Checks:
```text
What is the current health status of my AKS cluster?
```
**Expected:** Health checks for subnet sharing, K8s version, load balancer, node labels

#### Discovery Commands:
```text
List all namespaces and deployments running in this AKS cluster.
```
**Expected:** kubectl command suggestions with portal execution option

```text
List all public-facing services and their exposed ports.
```
**Follow-up:** 
```text
List all public-facing services in my aks cluster in the pets namespace and their external ip address and exposed ports.
```
**Expected:** Specific kubectl commands for LoadBalancer services

#### Monitoring & Troubleshooting:
```text
Generate a KQL query to detect failed deployments or image pull errors.
```
**Expected:** KQL query for deployment failures

```text
Show me CPU and memory usage for all pods in the pets namespace.
```
**Expected:** `kubectl top pods -n pets` command

```text
Show me the logs for the store-admin deployment in the pets namespace
```
**Follow-up:**
```text
How do I get the pod name for a pod in the store-admin deployment?
```
**Expected:** Multi-step kubectl commands

```text
Explain the liveness probe in my store front deployment
```
**Expected:** YAML editor navigation and probe explanation

---

### Context: Infrastructure Resilience
**Location:** Azure Portal → Resource Group or AKS Cluster

#### Resilience Assessment:
```text
Which Azure resources in my environment are not zone-redundant?
```
**Expected:** Zone-redundancy status query

```text
How would I make this AKS cluster more resilient?
```
**Expected:** Recommendations for backup, zones, maintenance, premium tiers

```text
How can I check if my AKS nodes are using availability zones?
```
**Expected:** kubectl command to check zone distribution

```text
How do I enable availability zones for my AKS cluster?
```
**Follow-up:**
```text
How would I do that in Terraform?
```
**Expected:** Terraform configuration examples

---

### Context: Infrastructure as Code Generation
**Location:** Azure Portal → Resource Group

#### Bicep Generation:
```text
Generate a Bicep configuration to deploy an AKS cluster in the East US region. The cluster should have 3 nodes using Standard_DS2_v2 VM size, enable RBAC, and integrate with Azure Monitor for logging. Include a new resource group, virtual network, and subnet. Also configure a default node pool and enable network plugin 'azure'.
```

#### Terraform Generation:
```text
Generate a Terraform configuration to deploy an AKS cluster in the East US region. The cluster should have 3 nodes using Standard_DS2_v2 VM size, enable RBAC, and integrate with Azure Monitor for logging. Include a new resource group, virtual network, and subnet. Also configure a default node pool and enable network plugin 'azure'.
```

#### Tagging Scripts:
```text
Create a powershell script to tag the resource group and every resource in it with a tag of "lab" and value of "AI Tour"
```

```text
Create an azure cli script to tag the resource group and every resource in it with a tag of "lab" and value of "AI Tour"
```

---

## 2. GitHub Copilot in VS Code

### Context: CI/CD Security Enhancement
**Location:** VS Code → `.github/workflows/package-ai-service.yaml`

#### Security Improvements:
```text
Add security tasks to this workflow
```
**Expected:** Suggestions for dependency scanning, container vulnerability scanning, SAST

#### Dockerfile Security:
**Location:** `src/ai-service/Dockerfile`
```text
Review the Dockerfile for the ai-service microservice and suggest security improvements
```
**Expected:** Non-root user, specific versions, security labels, package cleanup

---

## 3. GitHub Copilot with MCP Servers (Bonus)

### Context: Playwright MCP Server
**Setup:** `npx @playwright/mcp@latest` in MCP configuration

#### Store Front Testing:
```text
@playwright Create comprehensive smoke tests for an e-commerce store front at [URL]. Include tests for:
- Homepage loading and basic navigation
- Product catalog browsing
- Product detail page functionality  
- Add to cart workflow
- Shopping cart page accessibility
- Basic checkout flow validation
```

#### Store Admin Testing:
```text
@playwright Create smoke tests for store admin panel at [URL]. Test:
- Admin login page and authentication
- Product management dashboard
- Add new product functionality
- Product editing capabilities
- AI assistant integration features
- Admin navigation and permissions
```

### Context: Terraform MCP Server
**Setup:** `hashicorp/terraform-mcp-server` Docker image in MCP configuration

#### Infrastructure Generation:
```text
@terraform Help me find a production-ready AKS module
```
**Expected:** Enhanced Terraform module recommendations with documentation

---

## 4. AI Shell (Bonus)

### Context: Azure AI Agent
**Setup:** `Start-AiShell` → Select *azure* agent

#### Resource Queries:
```text
List all AKS clusters in my subscription
```

```text
Show me a query to find all failed deployments in my AKS cluster
```

```text
What security improvements can I make to my AKS cluster [CLUSTER_NAME]?
```

```text
Show me the node status for AKS cluster [CLUSTER_NAME] in resource group [RESOURCE_GROUP_NAME]
```

---

## 5. GitHub Copilot for Azure Extension (Bonus)

### Context: VS Code with @azure Chat Participant
**Setup:** GitHub Copilot for Azure extension installed

#### Resource Management:
```text
@azure list all my AKS clusters
```

```text
@azure create an Azure CLI command to scale my AKS cluster [CLUSTER_NAME] to 5 nodes
```

#### Infrastructure Templates:
```text
@azure create a Bicep template for deploying an Azure Container Instance with the nginx image
```

#### Troubleshooting:
```text
@azure my AKS pods are not starting, what are the common causes and how do I diagnose them?
```

#### Monitoring:
```text
@azure write a KQL query to show the top 10 containers by CPU usage in my AKS cluster
```

#### Deployment Scripts:
```text
@azure create a PowerShell script to deploy a new application to my existing AKS cluster using kubectl
```

---

## Common Troubleshooting Tips for Proctors

1. **If Copilot returns a failure:** Start a new chat - previous context can cause issues
2. **For specific queries:** Change context (e.g., go to AKS resource for AKS-specific queries)
3. **Portal execution:** Look for "Yes" buttons to execute suggested commands in Azure Portal
4. **YAML editor:** Available in Kubernetes resources with Copilot assistance
5. **MCP servers:** Require proper permissions and trust settings
6. **Variable substitution:** Use actual URLs/names instead of placeholders in prompts

---

## Expected Learning Outcomes by Section

- **Part 2:** Operational analysis and resource discovery
- **Part 3:** Infrastructure resilience assessment
- **Part 4:** IaC template generation
- **Part 5:** CI/CD security enhancement
- **Bonus:** Advanced tooling integration

---

## Quick Reference: Context Switching

| Task Type | Best Context | Agent/Tool |
|-----------|-------------|------------|
| General Azure queries | Resource Group | Copilot in Azure |
| AKS-specific operations | AKS Cluster page | Copilot in Azure |
| Code security | VS Code | GitHub Copilot |
| Test generation | VS Code + MCP | @playwright |
| Infrastructure code | VS Code + MCP | @terraform |
| Shell operations | Terminal | AI Shell |
| Development workflows | VS Code | @azure participant |
