# CustomAzureMonitorLog (CAML) | How to access data from a web service or Api for more than x days

Have you ever wondered...

- ...how you could get data from a web service like the [Office 365 Reporting Web Service](https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984325(v=office.15)) or the [Microsoft Graph reports Api](https://learn.microsoft.com/en-us/graph/reportroot-concept-overview) using PowerShell?

- ...how you could store that data to investigate it later or simple archiving purposes?

- ...how you could automate the entire process, so that you don't have to get the data manually every time new data is generated?

- ...how you could investigate the collected data?

<b>If yes, CAML is here to help you!</b>

<center><img alt="CAML Logo - A camel sitting on a cloud, smiling" src="./docs/_images/CAML_Logo.jpg" width="250" /></center>

This repository demonstrates an end-to-end solution for gathering log data from an web service or Api and storing it in a Log Analytics workspace using PowerShell only.
In this tutorial, you will request [message trace data](https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984335(v=office.15)) and [message trace detail data](https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984328(v=office.15)) from the Office 365 Reporting web service, as well as [Microsoft Teams device usage reports](https://learn.microsoft.com/en-us/graph/api/resources/microsoft-teams-device-usage-reports?view=graph-rest-1.0) and [Microsoft Teams user activity reports](https://learn.microsoft.com/en-us/graph/api/resources/microsoft-teams-user-activity-reports?view=graph-rest-1.0) and store it in a Azure Log Analytics workspace.

This is just an example of how an web service or API like the Office 365 Reporting web service or Microsoft Graph reportings api can be triggered and the received data redirected. You can customize the functions in this repository to receive data from any other API with ease. If you want to learn more about each file or you want to further customize them, please have a look at the descriptions, readme.md files and help-blocks of each folder or script-file.
If you encounter any problems, want to add a new feature or want to improve the documentation, please open an issue in this repository.

To learn more about the entire project, check out the .md files in the [docs folder](./docs/), as well as the .md files in each subfolder of this project (if created). The .md files outside the docs folder will explain the content of it's own folder in detail.

## Getting started

> IMPORTANT NOTE before we get started: Please try the solution in a test/demo environment before using it in production.

> If you want to use this to collect ALL inbound and outbound emails of your environment, please consider the limitations of the Office 365 reporting web service and also read the [uncontrollable events](https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984332(v=office.15)#uncontrollable-events).

The [CustomAzureMonitorLog powershell module](./function/modules/CustomAzureMonitorLog/) must be used on a Windows machine (MacOS and Linux support coming soon!). You can use the module on your local machine interactively or in an Azure Function automatically. If you want to use it in an Azure Function, you have to deploy the solution to your Azure tenant.

In both cases you need at least the following:

- [PowerShell 7.3](https://learn.microsoft.com/de-de/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3) or later
- PowerShell Module [Az.Accounts](https://www.powershellgallery.com/packages/Az.Accounts/)
- PowerShell Module [Azure.Function.Tools](https://www.powershellgallery.com/packages/Azure.Function.Tools/)

Further pre-requisites are described in the related [deployment description](./docs/deployment/deployment.md).

## Available reports and APIs to request data from using this solution

There are several Exchange Online reports, which can be requested via the Office 365 Reporting web services. Learn more about the available Exchange reports of the Office 365 Reporting web service at [Exchange reports available in Office 365 Reporting web service](https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984342(v=office.15))

Additionally, there are lots of Microsoft 365 usage reports, which can be requested via the Microsoft Graph reports API. Learn more about the available Microsoft 365 usage reports of the Microsoft Graph reports API at [Working with Microsoft 365 usage reports in Microsoft Graph](https://learn.microsoft.com/en-us/graph/api/resources/report?view=graph-rest-1.0)

As described in the introduction, you can easily add new functionalities to get data from any other web service or API. You could, for example, utilize [Microsoft 365 Defender APIs](https://learn.microsoft.com/en-us/microsoft-365/security/defender/api-overview?view=o365-worldwide) or any custom API to collect data and write it to the Log Analytics workspace. In those cases, remember to add the necesarry permissions to your Azure App registration, if needed.

## Customizing the solution

To customize the solution, check out the [customizeFunctions documentation](./docs/customizeFunctions.md).

## Investigate collected data

To learn what you can do with your collected data inside the Log Analytics Workspace, check out the [investigateData documentation](./docs/investigateData.md).

## Removing the solution from your Azure tenant

You can find more information about the manual removal process in the [removeSolution documentation](./docs/manualRemoval.md).

## Known Issues

See [knownIssues](./docs/knownIssues.md) for known issues and workarounds. If you encounter any other issues, please open an issue in this repository. Thanks!

## Author

- [Jamy Klotzsche](https://github.com/jklotzsche-msft)

## Special thanks to

- [Friedrich Weinmann](https://github.com/FriedrichWeinmann) - thanks for supporting me with your knowledge and your PowerShell modules (e.g. [Azure.Function.Tools](https://github.com/FriedrichWeinmann/Azure.Function.Tools) and [PSModuleDevelopment](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment))!
- [Vini Costa](https://github.com/viniciusramosc) - thanks for contributing to this project and the documentation!
- [Thomas Meyer](https://github.com/thmeyer-msft) - thanks for contributing to this project and the documentation!

## Resources / Links

### Office 365 Reporting Web Service

[Modern authentication (OAuth) support for the Reporting Web Service in Office 365](https://www.michev.info/Blog/Post/4067/modern-authentication-oauth-support-for-the-reporting-web-service-in-office-365)

[Exchange reports available in Office 365 Reporting web service](https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984342(v=office.15))

[MessageTrace report documentation](https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984335(v=office.15))

### Azure Functions

[Introduction to Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview)

[Timer trigger for Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer?tabs=in-process&pivots=programming-language-csharp)

### Azure Monitor

[Azure Monitor overview](https://learn.microsoft.com/en-us/azure/azure-monitor/overview)

[Azure Monitor REST API reference](https://learn.microsoft.com/en-us/rest/API/monitor/)

[Tutorial: Send data to Azure Monitor Logs using REST API (Azure portal)](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal#assign-permissions-to-dcr)

### Log Analytics

[Log Analytics REST API Reference](https://learn.microsoft.com/en-us/rest/API/loganalytics/)

[Kusto Query Language (KQL) overview](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/)

[Overview of Log Analytics in Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview)
