## How to deliver this session

🥇 Thanks for delivering this session!

Prior to delivering the workshop please:

1.  Read this document and all included resources included in their entirety.
2.  Watch the video presentation
3.  Ask questions of the content leads! We're here to help!

## 📁 File Summary

| Resources                  | Links                                           | Description                                                                        |
| ---------------------      | ----------------------------------------------- | ---------------------------------------------------------------------------------- |
| Workshop Slide Deck        | [Presentation](https://aka.ms/WRK570-slides)    | Presentation slides for this workshop with presenter notes and embedded demo video |
| Session Delivery Recording | [Recording](https://youtu.be/vIxljMD_Sk8)    | The session delivery Recording                                                        |
| Prompt Checklist           | [Prompt Checklist](../docs/prompt_checklist.md) | Tips for effective prompting                                                       |

## 🚀Get Started

The workshop is divided into multiple sections including a short slide presentation and 3 hands on labs, with four bonus labs if there's time or for future exploration.

### 🕐Timing

| Time          | Description        |
| ------------- | ------------------ |
| 0:00 - 11:00  | Intro and overview |
| 11:00 - 70:00 | Session Steps      |
| 70:00 - 75:00 | Wrap up and Q&A    |

### 🏋️Preparation

**Part 1: Deploy AI Application with Azure Developer CLI (8 minutes)**

Actions for this section are in the terminal and the browser.

- Navigate to project directory
- Authenticate with Azure (azd auth login, az login)
- Register Azure Resource Providers
- Configure deployment environment
- Deploy application with azd up
- Verify deployment
- Test store front
- Test AI features

**Part 2: Operational Analysis with Copilot in Azure (19 minutes)**

Actions for this section are in the Azure Portal.

- Activity 1: Resource Group Analysis (6 minutes)
  - Access resource group
  - Open Copilot in Azure
  - Query recent changes
  - Check service health
  - Check AKS health (initial)
- Activity 2: AKS-Specific Analysis (7 minutes)
  - Navigate to AKS resource
  - Check cluster health
  - Discover workloads
  - Find public services (general and specific)
- Activity 3: Operational Monitoring (6 minutes)
  - Generate failure detection query
  - Monitor resource usage
  - Access application logs
  - Understand health checks

**Part 3: Infrastructure Resilience Analysis (6 minutes)**

Actions for this section are in the Azure Portal.

- Activity 1: Zone Redundancy Assessment
  - Return to resource group
  - Check zone redundancy
- Activity 2: AKS Resilience Recommendations
  - Return to AKS resource
  - Get resilience recommendations
  - Check availability zones
  - Learn about zone enablement

**Part 4: Infrastructure as Code Generation (5 minutes)**

Actions for this section are in the Azure Portal.

- Activity 1: Generate Bicep Configuration
  - Return to resource group
  - Generate AKS Bicep template
- Activity 2: Generate Terraform Configuration
- Activity 3: Generate Tagging Scripts
  - PowerShell script
  - Azure CLI script

**Part 5: GitHub Copilot for CI/CD Enhancement (12 minutes)**

Actions for this section are in the browser, terminal, and VS Code.

- Step 1: Setup Development Environment
  - GitHub account setup
  - Fork the AKS Store Demo project
  - Open Visual Studio Code
  - Update Git remote in VS Code
  - Create a new branch
  - Sign in to GitHub in VS Code
- Step 2: Enhance Container Security (6 minutes)
  - Open workflow file
  - Improve security
  - Update Dockerfile
- Step 3: Deploy Enhanced Pipeline (6 minutes)
  - Commit and push changes using VS Code Git integration
  - Monitor build

**Part 6: Bonus Steps**

The bonus steps are there for folks who may have gone through the lab more quickly or are for independent followup after the event.
- Step 1: Using the Playwright MCP Server to create smoke tests
- Step 2: Using AI Shell to bring Copilot in Azure into your shell
- Step 3: Bring Azure into VS Code with the GitHub Copilot for Azure extension
- Step 4: Improve your Infrastructure as Code with the Terraform MCP server.
