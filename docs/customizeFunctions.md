# Customize Functions

Before we customize any functions, we should learn how the core of this project, the "CustomAzureMonitorLog" PowerShell module works.

## How does the "CustomAzureMonitorLog" PowerShell module work?

Functions used by CAML are defined in the PowerShell module "CustomAzureMonitorLog". The module is located in the folder [CustomAzureMonitorLog](../function/modules/CustomAzureMonitorLog/).
The .psd1 (PowerShell Data File) contains a link to the related .psm1 (PowerShell Module File):

``` powershell
    # Script module or binary module file associated with this manifest.
    RootModule = 'CustomAzureMonitorLog.psm1'
```

The .psm1 file itself does not contain much code. It only looks through the subfolder 'functions' and loads all .ps1 files it finds there:

``` powershell
    # Import all functions from the functions folder and all subfolders into the current session using dot-sourcing
    foreach ($file in Get-ChildItem -Path "$PSScriptRoot/functions" -Filter *.ps1 -Recurse) {
        . $file.FullName
    }
```

The functions are defined in the subfolder [functions](../function/modules/CustomAzureMonitorLog/functions/). The functions are divided into the following categories:

- Office365ReportingApi: Functions to get data from the Office365 Reporting web service
- MicrosoftGraphReportingApi: Functions to get data from the Microsoft Graph reporting Api
- internal: Functions used by the other functions

### 'Internal' functions

The following functions are defined as internal, because other functions use them:

- Connect-CAMLClientCertificate: Connect to the Microsoft Graph reporting Api using a client certificate
- Connect-CAMLClientSecret: Connect to the Microsoft Graph reporting Api using a client secret
- Get-CAMLCustomLogTable: Get data from a custom log table in Azure Log Analytics workspace. This is used by multiple functions to determine the latest timestamp of the data in the custom log table, to know from which timestamp to get new data.
- Add-CAMLDataToCustomLogTable: Add data to a custom log table in Azure Log Analytics workspace. This is used by multiple functions to add data to a custom log table.

### 'Office365 Reporting web service' functions

Inside the [Office365ReportingApi](../function/modules/CustomAzureMonitorLog/functions/Office365ReportingApi) folder there is one subfolder for each functionality. Each folder contains two functions, which are necessary to GET the required data and ADD the data to a custom log table in Azure Log Analytics workspace.

The following folders and functions are pre-defined:

- Folder: MessageTrace
  - Get-CAMLMessageTrace: Get message trace data from the Office365 Reporting web service
  - Add-CAMLMessageTraceData: Add message trace data to the custom log table, which was obtained used the Get-CAMLMessageTrace function. To add data the internal function "Add-CAMLDataToCustomLogTable" is used.
- Folder: MessageTraceDetail
  - Get-CAMLMessageTraceDetail: Get message trace detail data from the Office365 Reporting web service
  - Add-CAMLMessageTraceDetailData: Add message trace detail data to the custom log table, which was obtained used the Get-CAMLMessageTraceDetail function. To add data the internal function "Add-CAMLDataToCustomLogTable" is used.

### 'Microsoft Graph reporting Api' functions

Inside the [MicrosoftGraphReportingApi](../function/modules/CustomAzureMonitorLog/functions/MicrosoftGraphReportingApi) folder there is one subfolder for each functionality. Each folder contains two functions, which are necessary to GET the required data and ADD the data to a custom log table in Azure Log Analytics workspace.

The following folders and functions are pre-defined:

- Folder: TeamsDeviceUsage
  - Get-CAMLTeamsDeviceUsage: Get Teams device usage data from the Microsoft Graph reporting Api
  - Add-CAMLTeamsDeviceUsageData: Add Teams device usage data to the custom log table, which was obtained used the Get-CAMLTeamsDeviceUsage function. To add data the internal function "Add-CAMLDataToCustomLogTable" is used.
- Folder: TeamsUserActivity
  - Get-CAMLTeamsUserActivity: Get Teams user activity data from the Microsoft Graph reporting Api
  - Add-CAMLTeamsUserActivityData: Add Teams user activity data to the custom log table, which was obtained used the Get-CAMLTeamsUserActivity function. To add data the internal function "Add-CAMLDataToCustomLogTable" is used.

### Azure Function App functions

Of course, we would like to run the functions above unattended as well. Therefore, the "CustomAzureMonitorLog" module must be imported in some kind of automation and run periodically. To achieve that, we decided to use an Azure Function App. The Azure Function App must have it's own "Azure Function App functions", which call the functions of the "CustomAzureMonitorLog" module.

Inside the [function](../function/) folder, there are subfolders for each function you want to run periodically.

- Add-CAMLMessageTraceDataTimer
- Add-CAMLMessageTraceDetailDataTimer
- Add-CAMLTeamsDeviceUsageDataTimer
- Add-CAMLTeamsUserActivityDataTimer

Each folder contains exactly two files:

#### function.json

This file contains the configuration of the Azure Function.The function is triggered by a timer trigger. The default schedule is

- every 15 minutes for obtaining message trace data from Office 365 reporting web service.
- once a week for Teams activity and usage data from Microsoft Graph reporting api.

You can change the schedule in the function.json file of each function using the [CRON expression](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer?tabs=csharp#cron-expressions).

#### run.ps1

This file contains the code of the Azure Function. It is a PowerShell script, which is executed by the Azure Function runtime. The script contains the code for the timer trigger, which is executed by the Azure Function. The script also contains the code for the following tasks:

- Obtaining an access token for the Microsoft Graph API
- Obtaining an access token for the Office 365 Reporting Web Service
- Obtaining the message trace data from the Office 365 Reporting Web Service
- Obtaining the Teams activity and usage data from the Microsoft Graph API
- Writing the data to the Log Analytics workspace

## Create your own functions

If you want to create your own functions, you can do so by creating a new folder in the [functions](../function/modules/CustomAzureMonitorLog/functions) folder. The folder name should be the name of the functionality you want to create. The folder must contain two files:

- Get-CAML\<FunctionalityName\>.ps1
- Add-CAML\<FunctionalityName\>Data.ps1

You can also copy an existing folder and adjust the code to your needs.

The Get-CAML\<FunctionalityName\>.ps1 file must contain a function named "Get-CAML\<FunctionalityName\>". The Add-CAML\<FunctionalityName\>Data.ps1 file must contain a function named "Add-CAML\<FunctionalityName\>Data".

The Get-CAML\<FunctionalityName\>.ps1 function must return an array of objects. Each object must have the same properties. The properties must be named exactly like the columns of the custom log table in Azure Log Analytics workspace. The Add-CAML\<FunctionalityName\>Data.ps1 function must accept an array of objects as input. The objects must have the same properties as the custom log table in Azure Log Analytics workspace.

To get an example, look at any of the existing Get-CAML*.ps1 and Add-CAML*.ps1 functions.

Lastly, you must add the new functions to the [CustomAzureMonitorLog.psd1](../function/modules/CustomAzureMonitorLog/CustomAzureMonitorLog.psd1) file. Add the new functions to the "FunctionsToExport" array.

## Create your own Azure Function App functions

If you want to run your own functions in an Azure Function App you can do so by creating a new folder in the [function](../function/) folder. The folder name should be the name of the functionality you want to create. The folder must contain two files, as described above. You can copy an existing folder again and adjust the code to your needs.

To get an example, look at any of the existing Azure Function App functions.

## Update your Azure Function App functions

To upload your own functions to your Azure Function App you can use the prepared [build script](../scripts/Set-CAMLAzureFunctionFiles.ps1).
This script creates a .zip-File out of the "function" folder and all subfolders and (if ResourceGroupName and FunctionAppName provided) uploads it to the Azure Function.

If you want to upload the files to an Azure Function, the following modules are needed:

- Az.Accounts
- Az.Websites

Run the script while being logged in to Azure PowerShell and provide the "ResourceGroupName" and "FunctionAppName" parameters like this:

```PowerShell
<#
    .EXAMPLE
    Connect-AzAccount # Login to Azure
    Set-CAMLAzureFunctionFiles.ps1 -ResourceGroupName 'rg-CAML' -FunctionAppName 'func-CAML' # Update the Azure Function App with your own version of the CustomAzureMonitorLog module

    Creates a .zip-File out of the "function" folder and all subfolders and uploads it to the Azure Function App.
#>
```

After that, the Azure Function App should be updated with your own version of the "CustomAzureMonitorLog" module.

## Create additional custom log tables

To store data in a Log Analytics Workspace, you must have a custom log table.

If you want to deploy (but have not yet) using the [automated Deployment](./deployment/AzureResources/automatedDeployment.md), you can simply add a new custom log table array in the [CAML.Config.psd1](../deployment/CAML.Config.psd1) file, which contains the columns you need. Then run the deployment script to create all resources including your new custom log table.

If you already deployed the Azure resources or want to deploy them using the [manual Deployment](./deployment/AzureResources/manualDeployment.md) you can create a new custom log table using the [Azure Portal](https://portal.azure.com/). The step-by-step guide is already described in the manual deployment documentation in [Section 1: Prepare Log Analytics Workspace to store data](./deployment/AzureResources/manualDeployment.md#section-1-prepare-log-analytics-workspace-to-store-data) at "Add custom log table".

## Add environment variables to your Azure Function App

Lastly, you have to add environment variables to your Function App, if needed by your own functions. There will be at least one environment variable you must add, which is the name of your custom table. To learn more about the environment variables used in this project and how to add them check the [Section 5: Add environment variables to Function App](./deployment/AzureResources/manualDeployment.md#section-5-add-environment-variables-to-azure-function-app) of the manual deployment documentation.

## Connecting to other services than Microsoft Graph reporting api and Office 365 Reporting Web Service

If you want to connect to other service than the Office 365 Reporting web service or the Microsoft Graph reporting Api, you can create a new folder in the [functions](../function/modules/CustomAzureMonitorLog/functions) folder. The folder name should be the name of the service you want to connect to.
This is only a hint to keep the code structured. You can also create a new folder for each functionality you want to create.

The only other requirement is, to add the needed Api permission on your app registration. To see how that works checkout 'Section 2: Create and configure App registration' of the [manualDeployment.md](./deployment/AzureResources/manualDeployment.md) documentation.
