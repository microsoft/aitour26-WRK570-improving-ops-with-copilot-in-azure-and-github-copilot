# Improving Ops with Copilot in Azure and GitHub Copilot

## Overview

**Duration:** 60 minutes

### Learning Objectives

By the end of this workshop, you will be able to:

- Deploy AI applications using Azure Developer CLI
- Use Copilot in Azure for operational analysis and troubleshooting
- Improve infrastructure resilience with AI-assisted recommendations
- Enhance CI/CD pipelines using GitHub Copilot

---

## Lab Environment Setup

### Prerequisites

- Windows 11
- Docker Desktop
- Azure CLI
- Azure Developer CLI
- Git command line
- Kubectl
- Helm
- Azure Kubelogin
- Visual Studio Code
- PowerShell 7
- Windows Terminal
- GitHub account
- Azure subscription

===

## Part 1: Deploy AI Application with Azure Developer CLI

**Estimated time:** 8 minutes

### Step 1: Navigate to Project Directory

Open Windows Terminal and update the **azd** tool.

```PowerShell-notab-nocolor
Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression
```

The update will close the terminal.

Open Windows Terminal and clone the the demo project:

```PowerShell-notab-nocolor
git clone https://github.com/microsoft/aitour26-WRK570-improving-ops-with-copilot-in-azure-and-github-copilot aks-store-demo
cd ./aks-store-demo
```

### Step 2: Authenticate with Azure

Run both commands to authenticate:

```PowerShell-notab-nocolor
azd auth login --use-device-code
```

> [!NOTE] This opens a browser window. Use your Azure credentials: <AZURE_USERNAME>

```PowerShell-notab-nocolor
az login
sudo az aks install-cli
```

This opens a prompt for authentication.

Choose "Work or school account" or "Microsoft account" as appropriate for your Azure credentials.

Click "Continue".

On the sign in screen, use <AZURE_USERNAME>.

Click "Next".

Authenticate with your second factor - MFA, Temporary Access Pass, etc.

Click "Sign in".

When asked to "automatically sign in to all desktop apps and websites on this device", choose "No, this app only".

When prompted to select a subscription and tenant, select the subscription you'd like to use.

### Step 3: Register Azure Resource Providers

Execute the following commands to enable required services:

```PowerShell-notab-nocolor
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace Microsoft.ServiceBus
az provider register --namespace Microsoft.DocumentDB
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.AlertsManagement
az provider register --namespace Microsoft.AzureTerraform
```

### Step 4: Configure Deployment Environment

#### Create Environment

```PowerShell-notab-nocolor
azd env new aitour
```

#### Enable Helm Support

```PowerShell-notab-nocolor
azd config set alpha.aks.helm on
```

#### Set Environment Variables

There are some common overrides based on current Azure demand - if you get an error deploying, add an override based on the error from the deployment (the error will list the valid availability zones).

```bash-notab-nocolor
declare -A overrides
overrides[eastus2]="2, 1"
overrides[westus2]="3"
overrides[eastus]="2, 1"

azd env set AZURE_RESOURCE_GROUP "rg-aigenius-251104"
azd env set COMPANY_NAME "Zava"
azd env set AZURE_LOCATION "eastus2"
azd env set AKS_NODE_POOL_VM_SIZE "Standard_D2_v4"
azd env set DEPLOY_AZURE_CONTAINER_REGISTRY "false"
azd env set DEPLOY_AZURE_OPENAI "true"
azd env set AZURE_OPENAI_LOCATION "swedencentral"
azd env set DEPLOY_AZURE_OPENAI_DALL_E_MODEL "false"
azd env set DEPLOY_AZURE_SERVICE_BUS "true"
azd env set DEPLOY_AZURE_COSMOSDB "true"
azd env set AZURE_COSMOSDB_ACCOUNT_KIND "MongoDB"
azd env set DEPLOY_OBSERVABILITY_TOOLS "false"
azd env set SOURCE_REGISTRY "ghcr.io/usepowershell"

location="eastus2"
if [[ -v overrides[$location] ]]; then
    azd env set AKS_AVAILABILITY_ZONES "${overrides[$location]}"
fi
```

### Step 5: Deploy Application

```PowerShell-notab-nocolor
azd up
```

> [!NOTE] **ACTION:** You will be prompted to select a subscription to use. Select the same subscription you selected for the Azure CLI login.

> [!NOTE] **What happens next:** Azure Developer CLI deploys infrastructure using Bicep, then uses Helm to deploy the application to AKS. The Azure resources were pre-deployed when the lab started, but it will take a few minutes to validate everything is in place.

### Step 6: Verify Deployment

The output of the deployment will contain the URLs for the store front and store admin services.

> [!NOTE] **If you cleared your screen** or otherwise lost your current view in the terminal, you can find the endpoints in the _azd_ environment values

Get service endpoints:

```PowerShell-notab-nocolor
azd env get-values
```

Look for these values:

- `SERVICE_STORE_FRONT_ENDPOINT_URL`
- `SERVICE_STORE_ADMIN_ENDPOINT_URL`

### Step 7: Test Store Front

1. Ctrl+click the store-front URL from terminal output
2. Browse the site and click on 2-3 products
3. Verify the site loads correctly

### Step 8: Test AI Features

1. Ctrl+click the store-admin URL
2. Navigate to **Products** → **Add Product**
3. Enter the following:
   - Product name: `AI Tour Treats`
   - Price: `5`
   - Keywords: `agent`, `flavorful`, `ops`
4. Click **Ask AI Assistant** (wait for button to appear)
5. Verify AI generates a product description
6. Click **Save Product**

---

===

## Part 2: Operational Analysis with Copilot in Azure

**Estimated time:** 19 minutes

> [!ALERT] **Important:** AI responses are non-deterministic. Your results may vary slightly from the examples shown.

### Activity 1: Resource Group Analysis (6 minutes)

The objective here is to start to build an awareness of the resources under our control.

#### Access Your Resource Group

Navigate to <AZURE_RESOURCE_GROUP_NAME> in the browser.

```PowerShell-notab-nocolor
https://portal.azure.com/#@<AZURE_TENANT_NAME>/resource/subscriptions/<AZURE_SUBSCRIPTION_ID>/resourceGroups/<AZURE_RESOURCE_GROUP_NAME>/overview

https://portal.azure.com/#@164bdd76-e1fc-43d1-8d2d-b0c6c87ac808/resource/subscriptions/92b0d2db-6657-41a8-b1a0-9299dd0b4a6d/resourceGroups/rg-aigenius-251104/overview
```

#### Open Copilot in Azure

Click the **Copilot** button at the top of the Azure Portal.

#### Query Recent Changes

**Prompt:**

```text-notab-nocolor
過去7日間のすべての変更を検索するクエリを作成してください。
```

**Expected result:** KQL query similar to:

```kql-nocode
resourcechanges
| extend targetResourceId = tostring(properties.targetResourceId), changeTime = todatetime(properties.changeAttributes.timestamp)
| where changeTime > ago(7d)
| project targetResourceId, changeTime
```

Run the generated query to see recent resource changes.

Go back to the resource group overview.

#### Check Service Health

**Prompt:**

```text-notab-nocolor
このリソース グループに影響を与えるサービス アラートはありますか？
```

**Expected result:** Status report showing no active alerts (assuming healthy environment).

#### Check AKS Health (Initial)

**Prompt:**

```text-nocolor-notab
現在のAKSクラスターのhealth statusはどのようになっていますか？
```

> [!NOTE] **Action:** Cancel when prompted to select a cluster (we'll do this from the AKS context next).

===

### Activity 2: AKS-Specific Analysis (7 minutes)

Here you'll see how changing the context for Copilot in Azure enables specific capabilities, while you learn more about the deployed resources.

#### Navigate to AKS Resource

Go to the AKS Cluster.

```PowerShell-notab-nocolor
https://portal.azure.com/#@<AZURE_TENANT_NAME>/resource/subscriptions/<AZURE_SUBSCRIPTION_ID>/resourceGroups/<AZURE_RESOURCE_GROUP_NAME>/providers/Microsoft.ContainerService/managedClusters/<AZURE_AKS_CLUSTER_NAME>/overview
```

#### Check Cluster Health

**Prompt:**

```text-nocolor-notab
現在のAKSクラスターのhealth statusはどのようになっていますか？
```

**Expected result:** Health report showing passed checks for:

- ✅ Subnet Sharing
- ✅ Kubernetes Version Check
- ✅ Cluster Load Balancer
- ✅ Deprecated Node Labels

If Copilot asks if you want to continue troubleshooting, select "Cancel".

#### Discover Workloads

**Prompt:**

```text-nocolor-notab
このAKSクラスターで実行中のすべての名前空間とデプロイメントを一覧表示して
```

**Expected result:** kubectl command suggestion with option to run via Azure Portal.

> [!NOTE] Click **Yes** to go to the run command page. Click the **Send** button to run the command.

> [!KNOWLEDGE] Even if you are experienced with kubectl commands, Copilot in Azure can help you figure out the right syntax to get what you are looking for, and it's available right in the command window. Type what you are looking for and press the Copilot button and see what Copilot gives you back.

#### Find Public Services (General)

**Prompt:**

```text-nocolor-notab
公開されているすべてのサービスとその公開ポートを一覧表示する
```

> [!NOTE] This query will be too broad. We'll refine it next.

#### Find Public Services (Specific)

**Prompt:**

```text-nocolor-notab
pets 名前空間内の私の AKS クラスターで公開されているすべてのサービス、およびそれらの外部 IP アドレスと公開ポートを一覧表示してください。
```

**Expected result:** kubectl command for LoadBalancer services in pets namespace.

> [!NOTE] Click **Yes** to go to the run command page. Click the **Send** button to run the command.

> [!KNOWLEDGE] Discovery commands are a great use of Copilot in Azure. You can interactively learn about your services with a variety of tools, while showing you the commands or queries to get the information. You can use these as the basis for your own automation.

===

### Activity 3: Operational Monitoring (6 minutes)

Your objective in this activity is to start building a library of queries and commands to get a baseline understanding of how the services behave and help troubleshoot future problems.

#### Navigate to AKS Resource

Go to the AKS Cluster.

```PowerShell-notab-nocolor
https://portal.azure.com/#@<AZURE_TENANT_NAME>/resource/subscriptions/<AZURE_SUBSCRIPTION_ID>/resourceGroups/<AZURE_RESOURCE_GROUP_NAME>/providers/Microsoft.ContainerService/managedClusters/<AZURE_AKS_CLUSTER_NAME>/overview
```

#### Generate Failure Detection Query

**Prompt:**

```text-nocolor-notab
デプロイの失敗またはイメージのプルエラーを検出するためのKQLクエリを生成する。
```

**Expected result:** KQL query checking for failed provisioning states and deployment issues.

Go back to the AKS cluster resource.

#### Monitor Resource Usage

**Prompt:**

```text-nocolor-notab
pets ネームスペース内のすべてのポッドの CPU およびメモリ使用率を表示してください。
```

**Expected result:** ++kubectl top pods -n pets++ command.

> [!NOTE] Click **Yes** to go to the run command page. Click the **Send** button to run the command.

#### Access Application Logs

**Prompt:**

```text-nocolor-notab
pets ネームスペース内の store-admin デプロイメントのログを表示してください
```

**Expected result:** Instructions to get pod name first, then view logs.

**Follow-up prompt:**

```text-nocolor-notab
store-adminデプロイメント内のポッドのポッド名を取得するにはどうすればよいですか？
```

> [!NOTE] Execute the suggested command, then manually construct the logs command.

#### Understand Health Checks

**Prompt:**

```PowerShell-notab-nocolor
store frontデプロイメントにおける正常性プローブについて説明してください
```

> [!NOTE] Click **Navigate to YAML Editor** when prompted.

**Suggested follow-up:**

```PowerShell-notab-nocolor
Kubernetesにおける正常性プローブの目的は何ですか？
```

> [!KNOWLEDGE] Copilot can build sample YAML files to show specific configurations.

> [!KNOWLEDGE] The YAML editor is available in any of the Kubernetes resources surfaced in the Azure Portal and Copilot is there to help you better understand and effectively edit those files.

---

===

## Part 3: Infrastructure Resilience Analysis

**Estimated time:** 6 minutes

### Activity 1: Zone Redundancy Assessment

#### Return to Resource Group

Navigate back to the Resource Group Overview

```PowerShell-notab-nocolor
https://portal.azure.com/#@<AZURE_TENANT_NAME>/resource/subscriptions/<AZURE_SUBSCRIPTION_ID>/resourceGroups/<AZURE_RESOURCE_GROUP_NAME>/overview
```

#### Check Zone Redundancy

> [!KNOWLEDGE] Zone redundancy in Azure ensures high availability by distributing resources across multiple physical locations within a region, protecting applications from datacenter-level failures.

**Prompt:**

```PowerShell-notab-nocolor
私の環境において、どの Azure リソースがゾーン冗長化されていないでしょうか？
```

**Expected result:** Query showing zone-redundancy status of resources.

### Activity 2: AKS Resilience Recommendations

#### Return to AKS Resource

Go back to the AKS Cluster

```PowerShell-notab-nocolor
https://portal.azure.com/#@<AZURE_TENANT_NAME>/resource/subscriptions/<AZURE_SUBSCRIPTION_ID>/resourceGroups/<AZURE_RESOURCE_GROUP_NAME>/providers/Microsoft.ContainerService/managedClusters/<AZURE_AKS_CLUSTER_NAME>/overview
```

#### Get Resilience Recommendations

**Prompt:**

```PowerShell-notab-nocolor
このAKSクラスターの耐障害性を高めるにはどうすればよいですか？
```

**Expected recommendations:**

- AKS Backup for persistent volumes
- Zone redundancy for storage accounts
- Maintenance configurations
- VM Scale Sets improvements
- Service Bus premium tier

#### Check Availability Zones

**Prompt:**

```PowerShell-notab-nocolor
AKSノードがavailability zoneを使用しているかどうかを確認するにはどうすればよいですか？
```

> [!NOTE] Execute the suggested ++kubectl++ command to see zone distribution.

#### Learn About Zone Enablement

**Prompt:**

```PowerShell-notab-nocolor
AKSクラスターでavailability zoneを有効にするにはどうすればよいですか？
```

**Follow-up:**

```PowerShell-notab-nocolor
Terraformでそれをどう実現すればよいですか？
```

> [!NOTE] Review the generated Terraform configuration.

---

## Part 4: Infrastructure as Code Generation

**Estimated time:** 5 minutes

### Activity 1: Generate Bicep Configuration

#### Return to Resource Group

Navigate to the Resource Group Overview

```PowerShell-notab-nocolor
https://portal.azure.com/#@<AZURE_TENANT_NAME>/resource/subscriptions/<AZURE_SUBSCRIPTION_ID>/resourceGroups/<AZURE_RESOURCE_GROUP_NAME>/overview
```

#### Generate AKS Bicep Template

**Prompt:**

```PowerShell-notab-nocolor
East US2リージョンにAKSクラスターを展開するためのBicep構成を生成します。クラスターはStandard_DS2_v2 VMサイズを使用する3ノードで構成し、RBACを有効化し、Azure Monitorとの統合によりログ記録を行います。新しいリソースグループ、仮想ネットワーク、サブネットを含めます。また、デフォルトノードプールを設定し、ネットワークプラグイン「azure」を有効化します。
```

> [!NOTE] Click **Open full view** to review the complete Bicep template.

### Activity 2: Generate Terraform Configuration

**Prompt:**

```PowerShell-notab-nocolor
East US2リージョンにAKSクラスターを展開するためのTerraform構成を生成します。クラスターはStandard_DS2_v2 VMサイズを使用する3ノードで構成し、RBACを有効化し、Azure Monitorとの統合によるロギングを設定します。新規リソースグループ、仮想ネットワーク、サブネットを含めます。また、デフォルトノードプールを設定し、ネットワークプラグイン「azure」を有効化します。
```

> [!NOTE] Click **Open full view** to review the complete Terraform configuration.

### Activity 3: Generate Tagging Scripts

#### PowerShell Script

**Prompt:**

```PowerShell-notab-nocolor
PowerShell スクリプトを作成し、リソース グループとその中のすべてのリソースに「lab」というタグと「AI Tour」という値を付与します。
```

#### Azure CLI Script

**Prompt:**

```PowerShell-notab-nocolor
Azure CLI スクリプトを作成し、リソース グループとその中のすべてのリソースに「lab」というタグと「AI Tour」という値を付与します。
```

---

## Part 5: GitHub Copilot for CI/CD Enhancement

**Estimated time:** 12 minutes

### Step 1: Setup Development Environment

#### GitHub Account Signin

If you have a GitHub account:

1. Navigate to [github.com](https://github.com)
2. Click **Sign in**
3. Enter your credentials

#### GitHub Account Setup

If you don't have a GitHub account:

1. Navigate to [github.com](https://github.com)
2. Click **Sign up**
3. Enter email address and create password
4. Choose a username
5. Complete email verification
6. Select Free plan

#### Fork the AKS Store Demo Project

1. In the browser, navigate to [the workshop repository](https://github.com/microsoft/aitour26-WRK570-improving-ops-with-copilot-in-azure-and-github-copilot)
2. Click fork to create your own copy of the repository

#### Open Visual Studio Code

Launch VS Code and open the `aks-store-demo` folder.

#### Update Git Remote in VS Code

In VS Code terminal, run:

```PowerShell-nocolor-notab
git remote remove origin
git remote add origin <ADD THE URL TO YOUR FORK HERE>
```

#### Create a New Branch

Create a new branch from the terminal:

```PowerShell-nocolor-notab
git checkout -b aitour/improve_build
```

#### Sign in to GitHub in VS Code

1. Click on the Accounts icon in the Activity Bar (bottom-left corner)
2. Select "Sign in to GitHub" from the dropdown
3. A browser window will open prompting you to authorize VS Code to access your GitHub account
4. After signing in and authorizing, VS Code will automatically link your GitHub account

### Step 2: Enhance Container Security (6 minutes)

#### Open Workflow File

Navigate to `.github/workflows/package-ai-service.yaml`

#### Improve Security

Open GitHub Copilot Chat and prompt:

```PowerShell-notab-nocolor
このワークフローにセキュリティタスクを追加する
```

> [!KNOWLEDGE] **Review suggested improvements:**
>
> - Dependency scanning
> - Container image vulnerability scanning
> - Security linting
> - SAST (Static Application Security Testing)

#### Update Dockerfile

Open `src/ai-service/Dockerfile`

**Prompt:**

```PowerShell-notab-nocolor
ai-serviceマイクロサービスのDockerfileを確認し、セキュリティ改善策を提案してください
```

> [!KNOWLEDGE] **Expected improvements:**
>
> - Use specific base image versions
> - Run as non-root user
> - Remove unnecessary packages
> - Add security labels

### Step 3: Deploy Enhanced Pipeline (6 minutes)

#### Commit and Push Changes Using VS Code Git Integration

##### Stage Modified Files

1. Click the **Source Control** icon in VS Code Activity Bar (or press `Ctrl+Shift+G`)
2. Review the files listed under **Changes**
3. Click the **+** (plus) icon next to each modified file to stage them
   - Alternatively, click **+** next to **Changes** to stage all files at once

##### Create Commit

1. In the **Message** text box at the top of the Source Control panel, enter a descriptive commit message:

   ```text-notab-nocolor
   Add security enhancements to CI/CD pipeline

   - Added container vulnerability scanning
   - Implemented SAST checks
   - Enhanced Dockerfile security practices
   ```

2. Click the **Commit** button (checkmark icon)

##### Push Changes to Remote Repository

1. Click the **Sync Changes** button that appears after committing
   - This will push your changes and pull any remote updates
2. Alternatively, click the **...** (more actions) menu in Source Control panel and select **Push**

> [!NOTE] If prompted about publishing the branch, click **OK** to push your branch to the remote repository.

#### Monitor Build

> [!NOTE] Watch the GitHub Actions workflow execute with new security checks. You may need to enable GitHub actions on the repository.

---

## Summary

### Key Takeaways

- **Copilot in Azure** streamlines operational tasks and provides actionable insights
- **Infrastructure resilience** can be improved through AI-driven recommendations
- **GitHub Copilot** enhances CI/CD security and reduces manual configuration effort
- **AI assistance** accelerates both operational troubleshooting and infrastructure automation

### Next Steps

- Explore additional Copilot in Azure scenarios with your own workloads
- Implement suggested resilience improvements in production environments
- Integrate GitHub Copilot into your daily development workflow
- <!-- TODO: Add specific next steps or additional resources -->

---

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Copilot in Azure Overview](https://learn.microsoft.com/azure/copilot
- [GitHub Copilot Documentation](https://docs.github.com/copilot)

## Troubleshooting

- If Copilot returns a failure to process your request, try starting a new chat. It's possible that existing context from previous chat messages and responses can lead to failures in providing a response.

> **Questions?**

## Bonus Steps

### Add the Playwright MCP Server to GitHub Copilot

**Estimated time:** 12 minutes

#### Prerequisites

- VS Code with GitHub Copilot enabled
- Active GitHub Copilot subscription
- Node.js installed

#### Step 1: Install Playwright

In VS Code terminal, navigate to the tests directory and install the Playwright tools:

```PowerShell-notab-nocolor
cd tests
npm install
npx playwright install
```

#### Step 2: Configure

Add the Playwright MCP server to GitHub Copilot's configuration:

1. Open Command Palette (Ctrl+Shift+P)
2. Type "MCP: Add Server" and hit Enter.
3. Select "Command (stdio)"
4. Enter the command to run

```PowerShell-notab-nocolor
npx @playwright/mcp@latest
```

5. Change the server id to "Playwright".
6. Select Workspace as the scope for the MCP server.
7. Choose "Trust" to enable the MCP server.

#### Step 4: Generate Store Front Smoke Tests Using MCP

Open GitHub Copilot Chat and use the enhanced Playwright capabilities:

```text-notab-nocolor
#playwright Create comprehensive smoke tests for an e-commerce store front at [SERVICE_STORE_FRONT_ENDPOINT_URL]. Include tests for:
- Homepage loading and basic navigation
- Product catalog browsing
- Product detail page functionality
- Add to cart workflow
- Shopping cart page accessibility
- Basic checkout flow validation
```

#### Step 5: Generate Store Admin Tests with MCP

Prompt GitHub Copilot Chat:

```text-notab-nocolor
#playwright Create smoke tests for store admin panel at [SERVICE_STORE_ADMIN_ENDPOINT_URL]. Test:
- Admin login page and authentication
- Product management dashboard
- Add new product functionality
- Product editing capabilities
- AI assistant integration features
- Admin navigation and permissions
```

#### Step 6: Run and Validate Tests

Execute the MCP-generated tests:

```PowerShell-notab-nocolor
npx playwright test --headed
npx playwright show-report
```

> [!NOTE] The Playwright MCP server enhances GitHub Copilot's ability to generate more sophisticated and context-aware browser automation tests. Replace the URL placeholders with your actual application URLs.

### Bring Copilot in Azure into your shell with AI Shell

**Estimated time:** 8 minutes

#### Prerequisites

- PowerShell 7+ installed
- Azure CLI authenticated

#### Step 1: Install AI Shell

Install AI Shell using PowerShell:

```PowerShell-notab-nocolor
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-aishell.ps1') }"
```

#### Step 2: Configure Azure Integration

Launch AI Shell and configure Azure provider:

```PowerShell-notab-nocolor
Start-AiShell
```

In AI Shell, select the _azure_ AI agent.

#### Step 3: Query Your AKS Cluster

Ask AI Shell about your resources:

```text-notab-nocolor
List all AKS clusters in my subscription
```

#### Step 4: Generate Resource Queries

Generate KQL queries directly in your shell:

```text-notab-nocolor
Show me a query to find all failed deployments in my AKS cluster
```

#### Step 5: Get Resource Recommendations

Ask for improvement suggestions:

```text-notab-nocolor
What security improvements can I make to my AKS cluster [CLUSTER_NAME]?
```

#### Step 6: Execute Azure Commands

Let AI Shell generate and execute Azure CLI commands:

```text-notab-nocolor
Show me the node status for AKS cluster [CLUSTER_NAME] in resource group [RESOURCE_GROUP_NAME]
```

> [!NOTE] You can use placeholders and the _azure_ agent can help you replace them with `/replace`

### Bring Azure into your development environment with the GitHub Copilot for Azure extension

**Estimated time:** 12 minutes

#### Prerequisites

- VS Code with GitHub Copilot enabled
- Active GitHub Copilot subscription
- Azure subscription access

#### Step 1: Install GitHub Copilot for Azure Extension

In VS Code:

1. Open Extensions (Ctrl+Shift+X)
2. Search for "GitHub Copilot for Azure"
3. Click Install on the official Microsoft extension

#### Step 2: Sign in to Azure

1. Open Command Palette (Ctrl+Shift+P)
2. Type "Azure: Sign In"
3. Use your Azure credentials

#### Step 3: Explore Azure Resources from VS Code

Open GitHub Copilot Chat (Ctrl+Shift+P → "GitHub Copilot: Open Chat"):

```text-notab-nocolor
@azure list all my AKS clusters
```

#### Step 4: Generate Azure CLI Commands

Ask Copilot to generate deployment commands:

```text-notab-nocolor
@azure create an Azure CLI command to scale my AKS cluster [CLUSTER_NAME] to 5 nodes
```

#### Step 5: Create Infrastructure Templates

Generate Bicep templates directly in VS Code:

```text-notab-nocolor
@azure create a Bicep template for deploying an Azure Container Instance with the nginx image
```

#### Step 6: Troubleshoot Resources

Get troubleshooting help:

```text-notab-nocolor
@azure my AKS pods are not starting, what are the common causes and how do I diagnose them?
```

#### Step 7: Generate Monitoring Queries

Create KQL queries for Azure Monitor:

```text-notab-nocolor
@azure write a KQL query to show the top 10 containers by CPU usage in my AKS cluster
```

#### Step 8: Create Deployment Scripts

Generate PowerShell deployment scripts:

```text-notab-nocolor
@azure create a PowerShell script to deploy a new application to my existing AKS cluster using kubectl
```

> [!NOTE] The @azure chat participant provides Azure-specific assistance directly within your development environment, combining the power of GitHub Copilot with Azure expertise.

### Add the Terraform MCP Server to improve your infrastructure as code capabilities

**Estimated time:** 18 minutes

#### Prerequisites

- Terraform installed and in PATH
- VS Code with GitHub Copilot enabled
- Azure CLI authenticated

#### Step 1: Install Terraform MCP Server

Add the Terraform MCP server to GitHub Copilot's configuration:

1. Open Command Palette (Ctrl+Shift+P)
2. Type "MCP: Add Server" and hit Enter
3. Choose "Docker" as the type of server.
4. Add the image name.

```PowerShell-notab-nocolor
hashicorp/terraform-mcp-server:0.3.0
```

5. Choose "Allow" for the required permissions.
6. Accept the proposed server id.
7. Select "Workspace" as the scope for the MCP server.
8. Choose "Trust" to enable the MCP server.

#### Step 2: Create Terraform Project Structure

Create a new Terraform project directory:

```PowerShell-notab-nocolor
mkdir terraform-aks-infrastructure
cd terraform-aks-infrastructure
```

#### Step 5: Generate Provider Configuration with MCP

Open GitHub Copilot Chat and use the enhanced Terraform capabilities:

```text-notab-nocolor
#terraform Help me find a production-ready AKS module
```

> [!NOTE] The Terraform MCP server significantly enhances GitHub Copilot's ability to generate production-ready infrastructure code with direct access to module documentation.
