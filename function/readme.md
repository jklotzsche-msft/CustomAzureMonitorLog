# Function Folder

This folder contains the Azure Functions PowerShell code.

## Function Files

To learn more about each PowerShell function of this module check the comment-based help of each function. You can use the following PowerShell command to read the help of a function:

```PowerShell
Get-Help -Name <FunctionName> -Full
```

## function.json

This file contains the configuration of the Azure Function.The function is triggered by a timer trigger. The default schedule is

- every 15 minutes for obtaining message trace data from Office 365 reporting web service.
- once a week for Teams activity and usage data from Microsoft Graph reporting api.

You can change the schedule in the function.json file of each function using the [CRON expression](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer?tabs=csharp#cron-expressions).

## run.ps1

This file contains the code of the Azure Function. It is a PowerShell script, which is executed by the Azure Function runtime. The script contains the code for the timer trigger, which is executed by the Azure Function. The script also contains the code for the following tasks:

- Obtaining an access token for the Microsoft Graph API
- Obtaining an access token for the Office 365 Reporting Web Service
- Obtaining the message trace data from the Office 365 Reporting Web Service
- Obtaining the Teams activity and usage data from the Microsoft Graph API
- Writing the data to the Log Analytics workspace

## host.json

This file contains the configuration of the Azure Function host. It contains the configuration for the managed dependencies feature of the Azure Function. This feature is used to add the [CustomAzureMonitorLog](../modules/CustomAzureMonitorLog/) module to the function. More information about this feature can be found [here](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell?tabs=portal#dependency-management). For more information about this file check the [host.json](https://learn.microsoft.com/en-us/azure/azure-functions/functions-host-json) documentation.

## requirements.psd1

This file contains the list of all required PowerShell modules for the Azure Function. The Azure Function runtime will install the modules listed in this file automatically. For more information about this file check the [requirements.psd1](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell?tabs=portal#module-management) documentation.

## profile.ps1

This file contains the code, which is executed by the Azure Function runtime before the Azure Function is executed. The file contains the code for connecting to Azure using the "Connect-AzAccount" cmdlet. For more information about this file check the [profile.ps1](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell?tabs=portal#profileps1) documentation.
