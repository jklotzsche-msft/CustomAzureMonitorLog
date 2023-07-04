# Modules Folder

This folder will be part of the $env:PSModulePath while the Azure Function is running.
You can add your own PowerShell modules to this folder as well, if you need additional cmdlets, while the function is running.

Otherwise, you could use the "managed dependencies" feature of the function to add additional modules to the function. More information about this feature can be found [here](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell?tabs=portal#dependency-management)

## CustomAzureMonitorLog module

This folder contains the PowerShell module [CustomAzureMonitorLog](./CustomAzureMonitorLog/), which is used by the Azure Function to write data to the Log Analytics workspace. The module is based on the [Azure Monitor REST API](https://docs.microsoft.com/en-us/rest/api/monitor/) and the [Azure Monitor Data Collector API](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-collector-api).

The benefit of using a module is, that you can use the same code in other PowerShell scripts as well. You can also use the module to write data to the Log Analytics workspace from your local machine. To do so you need to install the module on your local machine and then use the cmdlets of the module to write data to the Log Analytics workspace.

## CustomAzureMonitorLog.psd1

This file is the PowerShell module manifest for the [CustomAzureMonitorLog](./CustomAzureMonitorLog/) module. It is used by the Azure Function to import the module. The manifest contains the module name, version, author, description and the required PowerShell version. It also contains the list of all exported functions of the module.

## CustomAzureMonitorLog.psm1

This file contains a short code snippet, which imports all functions from the [CustomAzureMonitorLog](./CustomAzureMonitorLog/) module using dot-sourcing.

## Function Files

To learn more about each PowerShell function of this module check the comment-based help of each function. You can use the following PowerShell command to read the help of a function:

```PowerShell
Get-Help -Name <FunctionName> -Full
```
