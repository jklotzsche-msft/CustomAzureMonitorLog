<#
	.SYNOPSIS
	Connect-CAMLClientCertificate

	.DESCRIPTION
	Connect to Azure AD as an application using a certificate.
	Therefore, the functionality "Connect-ClientCertificate" of Fred's module "Azure.Function.Tools" is used, to request a valid token. 

	.PARAMETER VaultCertificateName
	If you are using a Azure unattended, provide the name of the certificate stored in your Azure KeyVault.

	.PARAMETER VaultName
	If you are using a Azure unattended, provide the name of the Azure KeyVault, which holds your certificates.

	.PARAMETER ThumbPrint
	If you are using a windows machine interactively, provide the thumbprint of your certificate to authenticate.

	.PARAMETER CertStore
	If you are using a windows machine interactively, provide the certificate store in which your certificate is stored.

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
		certStore = 'CurrentUser'
		thumbprint = '111222333444555666777888999000AAABBBCCCD'
		clientId = 'abcdef12-abcd-abcd-abcd-abcdef123456'
		tenantId = 'abcdef12-1234-1234-1234-abcdef123456'
		scope = 'https://outlook.office365.com/.default'
	}
	$token = Connect-CAMLClientCertificate @tokenProperties

	Obtain a token using a certificate from your local certificate store.

	.EXAMPLE
	$tokenProperties = @{
		VaultCertificateName = 'myVaultCertificateName'
		VaultName = 'myVaultName'
		clientId = 'abcdef12-abcd-abcd-abcd-abcdef123456'
		tenantId = 'abcdef12-1234-1234-1234-abcdef123456'
		scope = 'https://outlook.office365.com/.default'
	}
	$token = Connect-CAMLClientCertificate @tokenProperties

	Obtain a token for Exchange Online using a certificate from your Azure KeyVault.

	.NOTES
	Documentation for the Azure.Functions.Tools module from Fred, which is reused here
	https://github.com/FriedrichWeinmann/Azure.Function.Tools

	.LINK
    https://github.com/jklotzsche-msft/CustomAzureMonitorLog
#>
function Connect-CAMLClientCertificate {
	[CmdletBinding(DefaultParameterSetName="Local")]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = "Azure")]
		[String]
		$VaultCertificateName,

		[Parameter(Mandatory = $true, ParameterSetName = "Azure")]
		[String]
		$VaultName,

		[String]
		[Parameter(Mandatory = $true, ParameterSetName = "Local")]
		$ThumbPrint,

		[ValidateSet('LocalMachine', 'CurrentUser')]
		[Parameter(ParameterSetName = "Local")]
		[String]
		$CertStore = 'CurrentUser',

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
		Write-Host "Function 'Connect-CAMLClientCertificate' has been triggered"
		$ErrorActionPreference = 'Stop'
	}
	process {
		if ($VaultCertificateName) {
			$certData = Get-AzKeyVaultCertificate -VaultName $VaultName -Name $VaultCertificateName
			$certBytes = Get-AzKeyVaultSecret -VaultName $VaultName -Name $certData.Name -AsPlainText
			$certBytesArray = [Convert]::FromBase64String($certBytes)
			$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(,$certBytesArray)
		}

		if ($ThumbPrint) { 
			$cert = Get-Item -Path "Cert:\$CertStore\My\$ThumbPrint"
		}

		Write-Host "Requesting token from $Scope using app registration $ClientId of tenant $TenantId and authenticating via certificate $($cert.Thumbprint)"
		Connect-ClientCertificate -ClientID $ClientId -TenantID $TenantId -Certificate $cert -Scope $Scope
	}
	end {
		Write-Host "Function 'Connect-CAMLClientCertificate' ended"
	}
}