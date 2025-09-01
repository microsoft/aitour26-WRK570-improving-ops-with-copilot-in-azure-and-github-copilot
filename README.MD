<p align="center">
<img src="img/Banner-MS-AI-Tour-26.png" alt="decorative banner" width="1200"/>
</p>

# [Microsoft AI Tour 2026](https://aitour.microsoft.com)

## 🔥WRK570: Improving Ops with Copilot in Azure and GitHub Copilot

If you will be delivering this session, check the [session-delivery-sources](./session-delivery-resources/) folder for slides, scripts, and other resources.

### Session Description

Learn how Copilot in Azure boosts app resilience by reviewing logs and streamlining ops. Get hands-on with real scenarios, and see how GitHub Copilot can enhance your build and deployment workflows.

### 🧠 Learning Outcomes

By the end of this session, learners will be able to:

- Use **Copilot in Azure** to streamline operational tasks and provides actionable insights
- Develop **Infrastructure resilience** through AI-driven recommendations
- Guide **GitHub Copilot** to enhance CI/CD security and reduces manual configuration effort
- Build effective prompts for **AI assistance** to accelerate both operational troubleshooting and infrastructure

### 💻 Technologies Used

1. Copilot in Azure
1. GitHub Copilot
1. Azure Kubernetes Service (AKS)
1. Azure Developer CLI

### 🔗 Session Resources

| Resources                             | Links                       | Description                    |
| :------------------------------------ | :-------------------------- | :----------------------------- |
| Microsoft Copilot in Azure Overview | https://learn.microsoft.com/azure/copilot/overview | Introduction to Microsoft Copilot in Azure - AI-powered tool to help you do more with Azure |
| Microsoft Copilot in Azure Capabilities | https://learn.microsoft.com/azure/copilot/capabilities | Comprehensive overview of Copilot capabilities including design, operate, optimize, and troubleshoot |
| Introduction to Microsoft Copilot in Azure Training | https://learn.microsoft.com/training/modules/introduction-microsoft-copilot-azure/ | Official Microsoft training module covering functionality and usage |
| Work with AKS clusters efficiently using Copilot | https://learn.microsoft.com/azure/copilot/work-aks-clusters | Complete guide to using Copilot with Azure Kubernetes Service (AKS) |
| AKS Monitoring with Copilot | https://learn.microsoft.com/azure/aks/monitor-aks | Best practices for monitoring AKS clusters, including Copilot integration |
| Kubernetes Events for AKS Troubleshooting | https://learn.microsoft.com/azure/aks/events | Use Kubernetes events to monitor and troubleshoot issues in AKS clusters |
| Example Prompts for Copilot in Azure | https://learn.microsoft.com/azure/copilot/example-prompts | Library of effective prompts for various Azure scenarios |
| Writing Effective Prompts for Copilot | https://learn.microsoft.com/azure/copilot/write-effective-prompts | Tips and best practices for creating prompts that provide helpful responses |

### 📚 Continued Learning Resources

| Resources                          | Links                                                                                                                            | Description                                  |
| :--------------------------------- | :------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------- |
| AI Tour 2026 Resource Center       | https://aka.ms/AITour26-Resource-center                                                                                          | Links to all repos for AI Tour 26 Sessions   |
| Azure AI Foundry Community Discord | [![Microsoft Azure AI Foundry Discord](https://dcbadge.limes.pink/api/server/ByRwuEEgH4)](https://discord.com/invite/ByRwuEEgH4) | Connect with the Azure AI Foundry Community! |
| Learn at AI Tour                   | https://aka.ms/LearnAtAITour                                                                                                     | Continue learning on Microsoft Learn         |

### 🌐 Multi-Language Support

_languages will go here when its time to localize_

## Content Owners

<table>
<tr>
    <td align="center"><a href="http://github.com/smurawski">
        <img src="https://github.com/smurawski.png" width="100px;" alt="Steven Murawski"
"/><br />
        <sub><b> Steven Murawski
</b></sub></a><br />
            <a href="https://github.com/smurawski" title="talk">📢</a> 
    </td>
</tr></table>

## Responsible AI

Microsoft is committed to helping our customers use our AI products responsibly, sharing our learnings, and building trust-based partnerships through tools like Transparency Notes and Impact Assessments. Many of these resources can be found at [https://aka.ms/RAI](https://aka.ms/RAI).
Microsoft’s approach to responsible AI is grounded in our AI principles of fairness, reliability and safety, privacy and security, inclusiveness, transparency, and accountability.

Large-scale natural language, image, and speech models - like the ones used in this sample - can potentially behave in ways that are unfair, unreliable, or offensive, in turn causing harms. Please consult the [Azure OpenAI service Transparency note](https://learn.microsoft.com/legal/cognitive-services/openai/transparency-note?tabs=text) to be informed about risks and limitations.

The recommended approach to mitigating these risks is to include a safety system in your architecture that can detect and prevent harmful behavior. [Azure AI Content Safety](https://learn.microsoft.com/azure/ai-services/content-safety/overview) provides an independent layer of protection, able to detect harmful user-generated and AI-generated content in applications and services. Azure AI Content Safety includes text and image APIs that allow you to detect material that is harmful. Within Azure AI Foundry portal, the Content Safety service allows you to view, explore and try out sample code for detecting harmful content across different modalities. The following [quickstart documentation](https://learn.microsoft.com/azure/ai-services/content-safety/quickstart-text?tabs=visual-studio%2Clinux&pivots=programming-language-rest) guides you through making requests to the service.

Another aspect to take into account is the overall application performance. With multi-modal and multi-models applications, we consider performance to mean that the system performs as you and your users expect, including not generating harmful outputs. It's important to assess the performance of your overall application using [Performance and Quality and Risk and Safety evaluators](https://learn.microsoft.com/azure/ai-studio/concepts/evaluation-metrics-built-in). You also have the ability to create and evaluate with [custom evaluators](https://learn.microsoft.com/azure/ai-studio/how-to/develop/evaluate-sdk#custom-evaluators).

You can evaluate your AI application in your development environment using the [Azure AI Evaluation SDK](https://microsoft.github.io/promptflow/index.html). Given either a test dataset or a target, your generative AI application generations are quantitatively measured with built-in evaluators or custom evaluators of your choice. To get started with the azure ai evaluation sdk to evaluate your system, you can follow the [quickstart guide](https://learn.microsoft.com/azure/ai-studio/how-to/develop/flow-evaluate-sdk). Once you execute an evaluation run, you can [visualize the results in Azure AI Foundry portal ](https://learn.microsoft.com/azure/ai-studio/how-to/evaluate-flow-results).
