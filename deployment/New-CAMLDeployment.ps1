<#
    .SYNOPSIS
        Deploys the Custom Azure Monitor Log solution to an Azure subscription.

    .DESCRIPTION
        Deploys the Custom Azure Monitor Log solution to an Azure subscription.

    .PARAMETER LogEnabled
        Enables logging of the deployment process to a file.
    
    .PARAMETER LogPath
        Specifies the path where the log file should be stored. This parameter has a default value of "$env:TEMP".
    
    .PARAMETER ConfigPath
        Specifies the path to the configuration file. This parameter has a default value of "$PSScriptRoot\MessageTrace\CAML.Deployment.psd1".

    .PARAMETER PfxFilePath
        Specifies the path to the PFX certificate file. This parameter is mandatory. The PFX certificate file must be created before running this script.

    .PARAMETER PfxPassword
        Specifies the password for the PFX certificate file. This parameter is mandatory.
    
    .EXAMPLE
        .\New-CAMLDeployment.ps1 -PfxFilePath "C:\myFolder\myCert.pfx" -PfxPassword (Read-Host -Prompt "Enter Password for PFX-File" -AsSecureString)

        Deploys the Custom Azure Monitor Log solution to an Azure subscription according to the configuration at "$PSScriptRoot\CAML.Deployment.psd1".
    
    .EXAMPLE
        .\New-CAMLDeployment.ps1 -LogEnabled -PfxFilePath "C:\myFolder\myCert.pfx" -PfxPassword (Read-Host -Prompt "Enter Password for PFX-File" -AsSecureString)

        Deploys the Custom Azure Monitor Log solution to an Azure subscription according to the configuration at "$PSScriptRoot\CAML.Deployment.psd1" and
        logs the deployment process to a log file at "$env:TEMP".
    
    .EXAMPLE
        .\New-CAMLDeployment.ps1 -LogEnabled -LogPath "C:\Temp" -PfxFilePath "C:\myFolder\myCert.pfx" -PfxPassword (Read-Host -Prompt "Enter Password for PFX-File" -AsSecureString)

        Deploys the Custom Azure Monitor Log solution to an Azure subscription according to the configuration at "$PSScriptRoot\CAML.Deployment.psd1" and
        logs the deployment process to a log file at "C:\Temp".
    
    .EXAMPLE
        .\New-CAMLDeployment.ps1 -LogEnabled -LogPath "C:\Temp" -ConfigPath "C:\myFolder\myOwnConfiguration.psd1" -PfxFilePath "C:\myFolder\myCert.pfx" -PfxPassword (Read-Host -Prompt "Enter Password for PFX-File" -AsSecureString)

        Deploys the Custom Azure Monitor Log solution to an Azure subscription according to the configuration at "C:\myFolder\myOwnConfiguration.psd1" and
        logs the deployment process to a log file at "C:\Temp".
    
    .LINK
        https://github.com/jklotzsche-msft/CustomAzureMonitorLog        
#>

#region Parameter

[CmdletBinding(SupportsShouldProcess)]
Param (
    [Parameter()]
    [Switch]
    $LogEnabled,

    [Parameter()]
    [String]
    $LogPath = $env:TEMP,

    [Parameter()]
    [String]
    $ConfigPath = "$PSScriptRoot\CAML.Config.psd1",

    [Parameter(Mandatory = $true)]
    [String]
    $PfxFilePath,

    [Parameter(Mandatory = $true)]
    [SecureString]
    $PfxPassword
)

#endregion Parameter

#region Execution

# If any error occurs, run the trap command to stop the transcript and throw the error
$ErrorActionPreference = 'Stop'
trap {
    if (($LogEnabled) -and ($WhatIfPreference -eq $false)) {
        Stop-Transcript -ErrorAction SilentlyContinue
    }

    throw $_
}

Write-Host @'
-------------------------------------------------------------
              ,,__ 
    ..  ..   / o._)                    .---.
    /--'/--\  \-'||        .----.    .'     '.
  /        \_/ / |      .'       '..'         '-.
.'\  \__\  __.'.'     .'           “-._
  )\ |  )\ |      _.'
 // \ //  \\
||_  \|_   \\_
'--' '--''  '--' 
-------------------------------------------------------------
╔═╗┬ ┬┌─┐┌┬┐┌─┐┌┬┐╔═╗┌─┐┬ ┬┬─┐┌─┐╔╦╗┌─┐┌┐┌┬┌┬┐┌─┐┬─┐╦  ┌─┐┌─┐
║  │ │└─┐ │ │ ││││╠═╣┌─┘│ │├┬┘├┤ ║║║│ │││││ │ │ │├┬┘║  │ ││ ┬
╚═╝└─┘└─┘ ┴ └─┘┴ ┴╩ ╩└─┘└─┘┴└─└─┘╩ ╩└─┘┘└┘┴ ┴ └─┘┴└─╩═╝└─┘└─┘
-------------------------------------------------------------
'@ -ForegroundColor Yellow

if ($LogEnabled) {
    $logFilePath = Join-Path -Path $LogPath -ChildPath "CAMLDeployment_$(Get-Date -Format yyyyMMddhhmmss).log"
    Start-Transcript -Path $logFilePath -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference
}

#region Preparation

# Importing config
Write-Host -Object "Importing PowerShellDataFile at $ConfigPath..." -NoNewline
try {
    $camlConfig = Import-PowerShellDataFile -Path $ConfigPath
}
catch {
    throw ('Configuration could not be imported from {0}' -f $ConfigPath)
}
Write-Host -Object "OK" -ForegroundColor Green

# Validate config
if($camlConfig.General.TenantId -eq '00000000-0000-0000-0000-000000000000') {
    throw ('Please specify the TenantId in the configuration file {0}.' -f $ConfigPath)
}
if($camlConfig.General.SubscriptionId -eq '00000000-0000-0000-0000-000000000000') {
    throw ('Please specify the SubscriptionId in the configuration file {0}.' -f $ConfigPath)
}
if($camlConfig.General.AppId -eq '00000000-0000-0000-0000-000000000000') {
    throw ('Please specify the AppId in the configuration file {0}.' -f $ConfigPath)
}
if($camlConfig.General.CertificateThumbprint -eq '00000000-0000-0000-0000-000000000000') {
    throw ('Please specify the CertificateThumbprint in the configuration file {0}.' -f $ConfigPath)
}

# Adjust config file if needed
if ($camlConfig.FunctionApp.Name -eq 'func-CAML') {
    $camlConfig.FunctionApp.Name = 'func-CAML-' + ((New-Guid).Guid[0..7] -join "")
    $null = (Get-Content -Path $ConfigPath).Replace("Name = 'func-CAML'", "Name = '$($camlConfig.FunctionApp.Name)'") | Set-Content -Path $ConfigPath
    Write-Warning -Message "The name of the Function App has been changed to $($camlConfig.FunctionApp.Name), because it must be unique across all of Azure."
}
if ($camlConfig.KeyVault.Name -eq 'kv-CAML') {
    $camlConfig.KeyVault.Name = 'kv-CAML-' + ((New-Guid).Guid[0..7] -join "")
    $null = (Get-Content -Path $ConfigPath).Replace("Name = 'kv-CAML'", "Name = '$($camlConfig.KeyVault.Name)'") | Set-Content -Path $ConfigPath
    Write-Warning -Message "The name of the Key Vault has been changed to $($camlConfig.KeyVault.Name), because it must be unique across all of Azure."
}

# Check, if bicep is installed
Write-Verbose "Checking if bicep is installed."
$bicep = bicep --version

if ($null -eq $bicep) {
    throw 'Bicep not found. Please install bicep on your system according to https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install.'
}

# Check if needed PowerShell modules are installed
Write-Verbose "Checking if needed PowerShell modules are installed."
$neededModules = @(
    'Azure.Function.Tools',
    'Az.Accounts',
    'Az.Resources',
    'Az.KeyVault',
    'Az.Websites'
)
$missingModules = @()
foreach($neededModule in $neededModules) {
    if ($null -eq (Get-Module -Name $neededModule -ListAvailable -ErrorAction SilentlyContinue)) {
        $missingModules += $neededModule
    }
}
if ($missingModules.Count -gt 0) {
    throw @"
The following modules are missing: '{0}'. Please install them using "Install-Module -Name '{0}'
"@ -f ($missingModules -join "', '")
}

# Check connection to Azure
Write-Verbose "Checking connection to Azure subscription according to config file."
$azContext = Get-AzContext -ErrorAction SilentlyContinue

# Check if the connection to Azure is established
if ($null -eq $azContext) {
    $null = Connect-AzAccount -TenantId $camlConfig.General.TenantId -SubscriptionId $camlConfig.General.SubscriptionId
}

# Check if the tenantId of connection is correct
if ($azContext.Tenant.Id -ne $camlConfig.General.TenantId) {
    $null = Get-AzContext | Disconnect-AzAccount
    $null = Connect-AzAccount -TenantId $camlConfig.General.TenantId -SubscriptionId $camlConfig.General.SubscriptionId
}

# Check if the subscriptionId of connection is correct
if ($azContext.Subscription.Id -ne $camlConfig.General.SubscriptionId) {
    $null = Set-AzContext -Subscription $camlConfig.General.SubscriptionId
}

#endregion Preparation

#region Deployment

# Create resource group, if it doesn't exist already
if ($null -eq (Get-AzResourceGroup -Name $camlconfig.ResourceGroup.Name -ErrorAction SilentlyContinue)) {
    Write-Host -Object "Creating Azure resource group $($camlConfig.ResourceGroup.Name)..." -NoNewline
    $null = New-AzResourceGroup -Name $camlconfig.ResourceGroup.Name -Location $camlconfig.General.Location
    Write-Host -Object "OK" -ForegroundColor Green
}

# Set default resource group for future cmdlets in this powershell session
$null = Set-AzDefault -ResourceGroupName $camlConfig.ResourceGroup.Name

# Get user id of current user for Key Vault import permission
Write-Verbose "Getting user id of current user for Key Vault import permission."
$keyVaultImportPermissionsUserId = (Get-AzADUser -Filter "userPrincipalName eq '$((Get-AzContext).Account.Id)'").Id
if($null -eq $keyVaultImportPermissionsUserId) {
    throw ('Could not find user with userPrincipalName {0} in Azure AD.' -f (Get-AzContext).Account.Id)
}

# Deploy Azure resources in resource group
Write-Host "Creating Azure resources for Custom Azure Monitor Log solution. This may take a few minutes..." -NoNewline
$null = New-AzResourceGroupDeployment -TemplateFile "$PSScriptRoot\CAML.Deployment.bicep" -camlConfig $camlConfig -keyVaultImportPermissionsUserId $keyVaultImportPermissionsUserId -WarningAction SilentlyContinue
Write-Host -Object "OK" -ForegroundColor Green

# Upload certificate to Key Vault
Write-Host -Object "Upload certificate $($camlConfig.General.CertificateName) to Azure KeyVault $($camlConfig.KeyVault.Name)..." -NoNewline
$azKeyVaultCertificate = @{
    VaultName = $camlConfig.KeyVault.Name
    Name = $camlConfig.General.CertificateName
    FilePath = $PfxFilePath
    Password = $PfxPassword
}
$null = Import-AzKeyVaultCertificate @azKeyVaultCertificate
Write-Host -Object "OK" -ForegroundColor Green

# Upload PowerShell code to Azure Function App
Write-Host -Object "Upload PowerShell code to Azure Function App $($camlConfig.FunctionApp.Name)..." -NoNewline
$null = & "$(Join-Path -Path (Split-Path -Path $PSScriptRoot) -ChildPath "scripts\Set-CAMLAzureFunctionFiles.ps1")" -ResourceGroupName $camlConfig.ResourceGroup.Name -FunctionAppName $camlConfig.FunctionApp.Name
Write-Host -Object "OK" -ForegroundColor Green

#endregion Deployment

if ($LogEnabled) {
    Stop-Transcript
}

#endregion Execution