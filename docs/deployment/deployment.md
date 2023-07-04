# Deployment

## Prerequisites

This script must be used on a Windows machine (MacOS and Linux support coming soon) with [PowerShell 7.3](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3) or later installed. You can use the script on your local machine or in an Azure Function. If you want to use it in an Azure Function, you have to deploy the solution to your Azure tenant.

In both cases you need at least the following:

- [PowerShell 7.3](https://learn.microsoft.com/de-de/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3) or higher
- PowerShell Module [Az.Accounts](https://www.powershellgallery.com/packages/Az.Accounts/)
- PowerShell Module [Azure.Function.Tools](https://www.powershellgallery.com/packages/Azure.Function.Tools/)

## Option 1: Install the solution as a service in your Azure tenant

You deploy the whole solution to your Azure tenant and use it as a service. If you want to deploy it to Azure you again have two options:

### Option 1.1: Deploy the solution automatically

You deploy the solution automatically using the prepared PowerShell and Bicep scripts explained in detail in the [automated Deployment guide](./AzureResources/automatedDeployment.md). This process should be preferred, if you

- want to deploy the solution as fast as possible
- want to automatically deploy the Azure resources based on a small config file

This process may take about 20 minutes, depending on your internet connection and your experience with Azure and PowerShell.

### Option 1.2: Deploy the solution manually

You deploy the solution manually according to the description in the [manual Deployment guide](./AzureResources/manualDeployment.md). The manual process should be preferred, if you

- want to understand the solution and the deployment process in detail
- want to customize the solution to your needs, extending the current possibilities of the config file of the automated solution

This process may take about to 1.5 hours, depending on your experience with Azure and PowerShell.

## Option 2: Use the PowerShell module interactively on your local machine

You import the PowerShell module [CustomAzureMonitorLog](../../function/modules/CustomAzureMonitorLog/) in your own PowerShell scripts and use the functions from this module interactively. If you want to use it interactively, you at least have to create the app registration manually to be able to obtain the needed tokens. You can find a detailed description of the manual creation process for the app registration in the [Create App Registration guide](./AppRegistrationAndPermissions/createAppRegistration.md), as well as a description of granting permissions to the app registration in the [Grant Permissions guide](./AppRegistrationAndPermissions/grantPermissionsToAppRegistration.md).
