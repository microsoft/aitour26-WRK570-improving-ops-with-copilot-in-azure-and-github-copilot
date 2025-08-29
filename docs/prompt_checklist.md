# ✅ Prompt Design Checklist for GitHub Copilot & Copilot in Azure

## 1. Define Clear Intent
- [ ] What do you want the AI to do? (e.g., generate code, analyze logs, suggest improvements)
- [ ] Use action verbs: *generate*, *review*, *optimize*, *deploy*, *analyze*, *fix*
- [ ] Avoid vague requests like “help me with this” — be specific.

**Examples:**
- GitHub Copilot: `Generate a secure CI/CD pipeline for a Node.js app using GitHub Actions.`
- Azure Copilot: `Analyze AKS cluster logs for failed pod restarts in the last 24 hours.`

---

## 2. Include Context
- [ ] Mention the environment (e.g., AKS, Azure Functions, GitHub Actions)
- [ ] Specify the file or resource (e.g., Dockerfile, pipeline.yml, log file)
- [ ] Provide relevant metadata (e.g., service name, region, timeframe)

**Example:**  
`Review the Dockerfile for the payment-service microservice and suggest security improvements.`

---

## 3. Use Natural Language, But Be Precise
- [ ] Write prompts as you would explain to a colleague.
- [ ] Avoid jargon unless necessary.
- [ ] Use complete sentences when possible.

**Example:**  
`Create a Bicep template to deploy a web app with autoscaling and logging enabled.`

---

## 4. Break Down Complex Tasks
- [ ] Split multi-step tasks into separate prompts.
- [ ] Use numbered steps or bullet points if needed.

**Example:**
1. `Identify security vulnerabilities in the pipeline.yml.`
2. `Add steps to scan dependencies using GitHub Advanced Security.`

---

## 5. Request Examples or Explanations
- [ ] Ask Copilot to show examples or explain its suggestions.

**Example:**  
`Show an example of a retry policy for Azure Functions in Bicep.`

---

## 6. Iterate and Refine
- [ ] Review AI output and revise the prompt if needed.
- [ ] Use feedback to improve prompt clarity.

**Example:**  
Initial: `Improve the build process.`  
Refined: `Add caching to the npm install step in the GitHub Actions workflow to speed up builds.`

---

## 7. Use Prompts for Operational Insights
- [ ] Log analysis: `Summarize error patterns from the last 3 days.`
- [ ] Infrastructure as Code: `Generate a Bicep template for a resilient AKS cluster.`
- [ ] Security: `Recommend NSG rules for a public-facing web app.`

---

## 8. Prompt for Collaboration
- [ ] Generate documentation, dashboards, or summaries for team sharing.

**Example:**  
`Create a markdown summary of the deployment changes for the last release.`

---

## 9. Avoid Confidential or Sensitive Prompts
- [ ] Do not include secrets, credentials, or internal user data.
- [ ] Use placeholders or mock data.

**Example:**  
Use `Fix the login bug for a sample user` instead of real user info.

---

## 10. Use Prompt Templates for Reusability

```markdown
### Prompt Template: Log Analysis
"Analyze logs from [resource name] in [region] for [error type] between [start time] and [end time]. Summarize root causes and suggest remediation."
