<#
	.SYNOPSIS
	Connect-CAMLClientSecret

	.DESCRIPTION
	Connects to AzureAD using a client secret.
	Therefore, the functionality "Connect-ClientCertificate" of Fred's module "Azure.Function.Tools" is used, to request a valid token. 

	.PARAMETER VaultSecretName
	If you are using a Azure unattended, provide the name of the secret stored in your Azure KeyVault.

	.PARAMETER VaultName
	If you are using a Azure unattended, provide the name of the Azure KeyVault, which holds your secret.

	.PARAMETER ClientSecret
	If you are using a machine interactively, provide the client secret to authenticate.

	.PARAMETER ClientID
	The ClientID / ApplicationID of the application to connect as.

	.PARAMETER TenantID
    The Guid of the tenant to connect to.

	.PARAMETER Scope
    The scope to request.
    Used to identify the service authenticating to.
    Examples:
		Microsoft Graph Api: 'https://graph.microsoft.com/.default'
		Office365ReportingApi = 'https://outlook.office365.com/.default'
		AzureMonitorDataCollectionEndpoint = 'https://monitor.azure.com/.default'
		LogAnalyticsApi = 'https://api.loganalytics.io/.default'
			ADDITIONAL INFORMATION about LogAnalyticsApi:
			The api.loganalytics.io endpoint is being replaced by api.loganalytics.azure.com.
			api.loganalytics.io will continue to be be supported for the forseeable future.
			More information at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

	.EXAMPLE
	$tokenProperties = @{
		VaultSecretName = 'myVaultSecret'
		VaultName = 'myVault'
		clientId = 'abcdef12-abcd-abcd-abcd-abcdef123456'
		tenantId = 'abcdef12-1234-1234-1234-abcdef123456'
		scope = 'https://outlook.office365.com/.default'
	}
	$token = Connect-CAMLClientSecret @tokenProperties

	Obtain a token using a client secret from your Azure KeyVault.

	.EXAMPLE
	$tokenProperties = @{
		ClientSecret = '111222333444555666777888999000AAABBBCCCD'
		clientId = 'abcdef12-abcd-abcd-abcd-abcdef123456'
		tenantId = 'abcdef12-1234-1234-1234-abcdef123456'
		scope = 'https://outlook.office365.com/.default'
	}
	$token = Connect-CAMLClientSecret @tokenProperties

	Obtain a token using a client secret from e.g. your clipboard.

	.NOTES
	Documentation for the Azure.Functions.Tools module from Fred, which is reused here
	https://github.com/FriedrichWeinmann/Azure.Function.Tools

	.LINK
    https://github.com/jklotzsche-msft/CustomAzureMonitorLog
#>
function Connect-CAMLClientSecret {
	[CmdletBinding(DefaultParameterSetName="Local")]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = "Azure")]
		[String]
		$VaultSecretName,

		[Parameter(Mandatory = $true, ParameterSetName = "Azure")]
		[String]
		$VaultName,

		[String]
		[Parameter(Mandatory = $true, ParameterSetName = "Local")]
		$ClientSecret,

		[Guid]
		[Parameter(Mandatory = $true)]
		$ClientId,
        
		[Guid]
		[Parameter(Mandatory = $true)]
		$TenantId,

		# [ValidateSet('LogAnalyticsApi', 'Office365ReportingApi', 'AzureMonitorDataCollectionEndpoint')]
		[ValidatePattern('https://[a-z0-9.-]+/.default')]
		[Parameter(Mandatory = $true)]
		[String]
		$Scope
	)
	
	begin {
		Write-Host "Function 'Connect-CAMLClientSecret' has been triggered"
		$ErrorActionPreference = 'Stop'
	}
	process {
		if ($VaultSecretName) {
			$secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $VaultSecretName -AsPlainText | ConvertTo-SecureString -Force -AsPlainText
		}

		if ($ClientSecret) { 
			$secret = $ClientSecret | ConvertTo-SecureString -Force -AsPlainText
		}

		Write-Host "Requesting token from $Scope using app registration $ClientId of tenant $TenantId and authenticating via secret."
		Connect-ClientSecret -ClientID $ClientId -TenantID $TenantId -ClientSecret $secret -Resource $Scope
	}
	end {
		Write-Host "Function 'Connect-CAMLClientSecret' ended"
	}
}