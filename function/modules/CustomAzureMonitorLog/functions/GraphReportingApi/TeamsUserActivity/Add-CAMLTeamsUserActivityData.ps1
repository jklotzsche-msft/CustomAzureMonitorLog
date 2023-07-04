<#
    .SYNOPSIS
    Add-CAMLTeamsUserActivityData adds Teams user activity data to a custom log analytics workspace.

    .DESCRIPTION
    Step 1:
    Based on the chosen parameters (VaultCertificateName or VaultSecretName), this cmdlet will connect to Azure AD as an application using a certificate or secret.
	Therefore, the either the cmdlet "Connect-CAMLClientCertificate" or "Connect-CAMLClientSecret" of Fred's module "Azure.Function.Tools" is used, to request a valid token.

    Alternatively, you can use the parameters ThumbPrint and CertStore to connect interactively to Azure AD using a certificate. 
    
    Step 2:
    Get Teams User Activity Reports as JSON object.
	Therefore, the cmdlet "Get-CAMLTeamsUserActivity" is used.

    Step 3:
    Send the collected data as JSON to a custom table in LogAnalytics workspace.
    Therefore, the cmdlet "Add-CAMLDataToCustomLogTable" is used.

	.PARAMETER VaultCertificateName
	If you are using a Azure unattended, provide the name of the certificate stored in your Azure KeyVault.

	.PARAMETER VaultSecretName
	If you are using a Azure unattended, provide the name of the secret stored in your Azure KeyVault.

	.PARAMETER VaultName
	If you are using a Azure unattended, provide the name of the Azure KeyVault, which holds your certificates.

	.PARAMETER ThumbPrint
	If you are using a windows machine interactively, provide the thumbprint of your certificate to authenticate.

	.PARAMETER CertStore
	If you are using a windows machine interactively, provide the certificate store in which your certificate is stored.

	.PARAMETER ClientSecret
	If you are using a machine interactively, provide the client secret to authenticate.

	.PARAMETER ClientID
	The ClientID / ApplicationID of the application to connect as.

	.PARAMETER TenantID
    The Guid of the tenant to connect to.

	.PARAMETER WorkspaceId
	Provide the GUID of a log analytics workspace.
	This GUID will be used to define the identity of a log analytics workspace for requesting it's current content.
	
	You can find the Guid by navigating in the Azure portal (portal.azure.com) to your Log Analytics Workspace --> Overview --> Workspace ID
	For more information check the Azure Monitor Log Analytics Api documentation at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

	.PARAMETER LawTable
	Provide a String containing the name of your custom table in your log analytics workspace. This string must include the "_CL" suffix.
	The string you provide will be used to concatenate the data collection endpoint url, combining the DceLogsIngestionUri, DcrImmutableId and LawTable.
	
	You can find the name by navigating in the Azure portal (portal.azure.com) to your Log Analytics Workspace --> Tables --> Table name
	For more information check the Azure Monitor Log Analytics Api documentation at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

	.PARAMETER DceLogsIngestionUri
	Provide a String containing the URL of your data collection endpoint.
	The string you provide will be used to concatenate the data collection endpoint url, combining the DceLogsIngestionUri, DcrImmutableId and LawTable.
	The data you provide will be sent to this endpoint, expecting it is a data collection endpoint of your LogAnalytics workspace.

	You can find the Uri by navigating in the Azure portal (portal.azure.com) to your Azure Monitor --> Data Collection Endpoints --> Overview --> JSON view.
	For more information check the Azure Monitor Log Analytics Api documentation at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

	.PARAMETER DcrImmutableId
	Provide a String containing the GUID of your data collection rule.
	The string you provide will be used to concatenate the data collection endpoint url, combining the DceLogsIngestionUri, DcrImmutableId and LawTable.

	You can find the guid by navigating in the Azure portal (portal.azure.com) to your Azure Monitor --> Data Collection Rule --> Overview --> JSON view.
	For more information check the Azure Monitor Log Analytics Api documentation at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

    .EXAMPLE
    Add-CAMLTeamsUserActivityData -VaultCertificateName 'MyCertificate' -VaultName 'MyKeyVault' -ClientId '00000000-0000-0000-0000-000000000000' -TenantId '00000000-0000-0000-0000-000000000000' -WorkspaceId '00000000-0000-0000-0000-000000000000' -TeamsUserActivityLawTable 'MyCustomTable_CL' -DceLogsIngestionUri 'https://dc.services.visualstudio.com/api/logs' -DcrImmutableId '00000000-0000-0000-0000-000000000000'

    Use a certificate from an Azure KeyVault to obtain the necessary tokens, determine the latest log in your log analytics workspace, gather data from the date of the last existing entry in your log analytics workspace and send that data to your log analytics workspace custom table. 

    .EXAMPLE
    Add-CAMLTeamsUserActivityData -VaultSecretName 'MySecret' -VaultName 'MyKeyVault' -ClientId '00000000-0000-0000-0000-000000000000' -TenantId '00000000-0000-0000-0000-000000000000' -WorkspaceId '00000000-0000-0000-0000-000000000000' -TeamsUserActivityLawTable 'MyCustomTable_CL' -DceLogsIngestionUri 'https://dc.services.visualstudio.com/api/logs' -DcrImmutableId '00000000-0000-0000-0000-000000000000'

    Use a secret from an Azure KeyVault to obtain the necessary tokens, determine the latest log in your log analytics workspace, gather data from the date of the last existing entry in your log analytics workspace and send that data to your log analytics workspace custom table.

    .EXAMPLE
    Add-CAMLTeamsUserActivityData -ThumbPrint '0000000000000000000000000000000000000000' -CertStore 'CurrentUser' -ClientId '00000000-0000-0000-0000-000000000000' -TenantId '00000000-0000-0000-0000-000000000000' -WorkspaceId '00000000-0000-0000-0000-000000000000' -TeamsUserActivityLawTable 'MyCustomTable_CL' -DceLogsIngestionUri 'https://dc.services.visualstudio.com/api/logs' -DcrImmutableId '00000000-0000-0000-0000-000000000000'

    Use a certificate from the local certificate store to obtain the necessary tokens, determine the latest log in your log analytics workspace, gather data from the date of the last existing entry in your log analytics workspace and send that data to your log analytics workspace custom table.

    .LINK
    https://github.com/jklotzsche-msft/CustomAzureMonitorLog
#>
function Add-CAMLTeamsUserActivityData {
    [CmdletBinding(DefaultParameterSetName = 'AzureCertificate')]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'AzureCertificate')]
        [String]
        $VaultCertificateName,

        [Parameter(Mandatory = $true, ParameterSetName = 'AzureSecret')]
        [String]
        $VaultSecretName,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'AzureCertificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AzureSecret')]
        [String]
        $VaultName,
  
        [Parameter(Mandatory = $true, ParameterSetName = 'LocalCertificate')]
        [String]
        $ThumbPrint,
        
        [ValidateSet('LocalMachine', 'CurrentUser')]
        [Parameter(ParameterSetName = 'LocalCertificate')]
        [String]
        $CertStore = 'CurrentUser',
        
        [Parameter(Mandatory = $true, ParameterSetName = 'LocalSecret')]
        [String]
        $ClientSecret,

        [Parameter(Mandatory = $true)]
        [Guid]
        $ClientId,
        
        [Parameter(Mandatory = $true)]
        [Guid]
        $TenantId,

        [Parameter(Mandatory = $true)]
        [String]
        $WorkspaceId,

        [Parameter(Mandatory = $true)]
        [String]
        $TeamsUserActivityLawTable,

        [Parameter(Mandatory = $true)]
        [String]
        $DceLogsIngestionUri,

        [Parameter(Mandatory = $true)]
        [String]
        $DcrImmutableId,

		[ValidateSet('D7', 'D30', 'D90', 'D180')]
		[Parameter()]
		[String]
		$Period = 'D7'
    )
    begin {
        Write-Host "Function 'Add-CAMLTeamsUserActivityData' has been triggered"
        $ErrorActionPreference = 'Stop'

        # Define urls of needed scopes
        $reportingScope = 'https://graph.microsoft.com/.default'
        $monitorScope = 'https://monitor.azure.com/.default'
    }
    process {
        # Step 1: Request a token for accessing Microsoft Graph Reporting API
        if($VaultCertificateName) {
            # Using certificate from Azure KeyVault
            $reportingToken = Connect-CAMLClientCertificate -VaultCertificateName $VaultCertificateName -VaultName $VaultName -ClientId $ClientId -TenantId $TenantId -Scope $reportingScope
        }
        if($VaultSecretName) {
            # Using secret from Azure KeyVault
            $reportingToken = Connect-CAMLClientSecret -VaultSecretName $VaultSecretName -VaultName $VaultName -ClientId $ClientId -TenantId $TenantId -Scope $reportingScope
        }
        if($ThumbPrint) {
            # Using certificate from local certificate store
            $reportingToken = Connect-CAMLClientCertificate -ThumbPrint $ThumbPrint -CertStore $CertStore -ClientId $ClientId -TenantId $TenantId -Scope $reportingScope
        }
        if($ClientSecret) {
            # Using secret from string
            $reportingToken = Connect-CAMLClientSecret -ClientSecret $ClientSecret -ClientId $ClientId -TenantId $TenantId -Scope $reportingScope
        }

        # Step 4: Collect Teams Device Usage data from yesterday
        $resultTeamsUserActivity = Get-CAMLTeamsUserActivity -Token $reportingToken -Period $Period

        # Step 5: Request a token for accessing Azure data collection endpoint
        if($VaultCertificateName) {
            # Using certificate from Azure KeyVault
            $monitorToken = Connect-CAMLClientCertificate -VaultCertificateName $VaultCertificateName -VaultName $VaultName -ClientId $ClientId -TenantId $TenantId -Scope $monitorScope
        }
        if($VaultSecretName) {
            # Using secret from Azure KeyVault
            $monitorToken = Connect-CAMLClientSecret -VaultSecretName $VaultSecretName -VaultName $VaultName -ClientId $ClientId -TenantId $TenantId -Scope $monitorScope
        }
        if($ThumbPrint) {
            # Using certificate from local certificate store
            $monitorToken = Connect-CAMLClientCertificate -ThumbPrint $ThumbPrint -CertStore $CertStore -ClientId $ClientId -TenantId $TenantId -Scope $monitorScope
        }
        if($ClientSecret) {
            # Using secret from string
            $monitorToken = Connect-CAMLClientSecret -ClientSecret $ClientSecret -ClientId $ClientId -TenantId $TenantId -Scope $monitorScope
        }

        # Step 6: Send data to your Azure data collection endpoint aka Azure Log Analytics
        foreach($teamsUserActivity in $resultTeamsUserActivity) {
            Write-Host "Chunk $($resultTeamsUserActivity.IndexOf($teamsUserActivity) + 1) / $($resultTeamsUserActivity.count) - Add-CAMLDataToCustomLogTable"
            Add-CAMLDataToCustomLogTable -Body $teamsUserActivity -Token $monitorToken -DceLogsIngestionUri $DceLogsIngestionUri -DcrImmutableId $DcrImmutableId -LawTable $TeamsUserActivityLawTable
        }
    }
    end {
        Write-Host "Function 'Add-CAMLTeamsUserActivityData' ended"
    }
}