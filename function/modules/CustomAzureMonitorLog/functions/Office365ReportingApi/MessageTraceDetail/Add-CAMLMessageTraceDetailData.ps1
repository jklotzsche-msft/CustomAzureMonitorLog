<#
    .SYNOPSIS
    Add-CAMLMessageTraceDetailData

    .DESCRIPTION
    Step 1:
    Based on the chosen parameters (VaultCertificateName or VaultSecretName), this cmdlet will connect to Azure AD as an application using a certificate or secret.
	Therefore, the either the cmdlet "Connect-CAMLClientCertificate" or "Connect-CAMLClientSecret" of Fred's module "Azure.Function.Tools" is used, to request a valid token.

    Alternatively, you can use the parameters ThumbPrint and CertStore to connect interactively to Azure AD using a certificate.
    
    Step 2:
   	Determine the value for "StartDate", to request a new set of data, e.g. message tracking logs.
	Therefore, the cmdlet "Get-CAMLCustomLogTable" is used.

    Step 3:
    Get Exchange Online Message Tracking Logs as JSON object.
    Therefore, the cmdlet "Get-CAMLMessageTrace" is used.

    Step 4:
    Get Exchange Online Message Tracking Log Details as JSON object.
    Therefore, the cmdlet "Get-CAMLMessageTraceDetail" is used and the needed messagetraceid data is provided by the data from step 3.

    Step 5:
    Sends the collected data as JSON to a custom table in LogAnalytics workspace.
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

	.PARAMETER MessageTraceDetailLawTable
	Provide a String containing the name of your custom table in your log analytics workspace. This string must include the "_CL" suffix.
	The string you provide will be used to concatenate the data collection endpoint url, combining the DceLogsIngestionUri, DcrImmutableId and MessageTraceDetailLawTable.
	
	You can find the name by navigating in the Azure portal (portal.azure.com) to your Log Analytics Workspace --> Tables --> Table name
	For more information check the Azure Monitor Log Analytics Api documentation at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

	.PARAMETER DceLogsIngestionUri
	Provide a String containing the URL of your data collection endpoint.
	The string you provide will be used to concatenate the data collection endpoint url, combining the DceLogsIngestionUri, DcrImmutableId and MessageTraceDetailLawTable.
	The data you provide will be sent to this endpoint, expecting it is a data collection endpoint of your LogAnalytics workspace.

	You can find the Uri by navigating in the Azure portal (portal.azure.com) to your Azure Monitor --> Data Collection Endpoints --> Overview --> JSON view.
	For more information check the Azure Monitor Log Analytics Api documentation at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

	.PARAMETER DcrImmutableId
	Provide a String containing the GUID of your data collection rule.
	The string you provide will be used to concatenate the data collection endpoint url, combining the DceLogsIngestionUri, DcrImmutableId and MessageTraceDetailLawTable.

	You can find the guid by navigating in the Azure portal (portal.azure.com) to your Azure Monitor --> Data Collection Rule --> Overview --> JSON view.
	For more information check the Azure Monitor Log Analytics Api documentation at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

    .EXAMPLE
    Add-CAMLMessageTraceDetailData -VaultCertificateName cert-CustomAzureMonitorLog -VaultName kv-CustomAzureMonitorLog -ClientId 00000000-0000-0000-0000-000000000000 -TenantId 00000000-0000-0000-0000-000000000000 -WorkspaceId 00000000-0000-0000-0000-000000000000 -MessageTraceDetailLawTable CAMLMessageTrace_CL -DceLogsIngestionUri https://mycustomtableendpoint.datacenter-1.ingest.monitor.azure.com -DcrImmutableId dcr-00000000000000000000000000000000
    
    Use a certificate from an Azure KeyVault to obtain the necessary tokens, determine the latest log in your log analytics workspace, gather message trace data from the date of the last existing entry in your log analytics workspace and send that data to your log analytics workspace custom table. 

    .EXAMPLE
    Add-CAMLMessageTraceDetailData -VaultSecretName secret-CustomAzureMonitorLog -VaultName kv-CustomAzureMonitorLog -ClientId 00000000-0000-0000-0000-000000000000 -TenantId 00000000-0000-0000-0000-000000000000 -WorkspaceId 00000000-0000-0000-0000-000000000000 -MessageTraceDetailLawTable CAMLMessageTrace_CL -DceLogsIngestionUri https://mycustomtableendpoint.datacenter-1.ingest.monitor.azure.com -DcrImmutableId dcr-00000000000000000000000000000000

    Use a secret from an Azure KeyVault to obtain the necessary tokens, determine the latest log in your log analytics workspace, gather message trace data from the date of the last existing entry in your log analytics workspace and send that data to your log analytics workspace custom table.

    .EXAMPLE
    Add-CAMLMessageTraceDetailData -ThumbPrint '0000000000000000000000000000000000000000' -CertStore 'CurrentUser' -ClientId '00000000-0000-0000-0000-000000000000' -TenantId '00000000-0000-0000-0000-000000000000' -WorkspaceId '00000000-0000-0000-0000-000000000000' -MessageTraceDetailLawTable 'CAMLMessageTrace_CL' -DceLogsIngestionUri 'https://mycustomtableendpoint.datacenter-1.ingest.monitor.azure.com' -DcrImmutableId 'dcr-00000000000000000000000000000000

    Use a certificate from the local certificate store to obtain the necessary tokens, determine the latest log in your log analytics workspace, gather message trace data from the date of the last existing entry in your log analytics workspace and send that data to your log analytics workspace custom table.

    .LINK
    https://github.com/jklotzsche-msft/CustomAzureMonitorLog
#>
    function Add-CAMLMessageTraceDetailData {
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
        $MessageTraceDetailLawTable,

        [Parameter(Mandatory = $true)]
        [String]
        $DceLogsIngestionUri,

        [Parameter(Mandatory = $true)]
        [String]
        $DcrImmutableId
    )
    begin {
        Write-Host "Function 'Add-CAMLMessageTraceDetailData' has been triggered"
        $ErrorActionPreference = 'Stop'

        # Define urls of needed scopes
        $logAnalyticsScope = 'https://api.loganalytics.io/.default'
        $reportingScope = 'https://outlook.office365.com/.default'
        $monitorScope = 'https://monitor.azure.com/.default'
    }
    process {
        # Step 1: Request a token for accessing Azure data collection endpoint
        if($VaultCertificateName) {
            # Using certificate from Azure KeyVault
            $logAnalyticsToken = Connect-CAMLClientCertificate -VaultCertificateName $VaultCertificateName -VaultName $VaultName -ClientId $ClientId -TenantId $TenantId -Scope $logAnalyticsScope
        }
        if($VaultSecretName) {
            # Using secret from Azure KeyVault
            $logAnalyticsToken = Connect-CAMLClientSecret -VaultSecretName $VaultSecretName -VaultName $VaultName -ClientId $ClientId -TenantId $TenantId -Scope $logAnalyticsScope
        }
        if($ThumbPrint) {
            # Using certificate from local certificate store
            $logAnalyticsToken = Connect-CAMLClientCertificate -ThumbPrint $ThumbPrint -CertStore $CertStore -ClientId $ClientId -TenantId $TenantId -Scope $logAnalyticsScope
        }
        if($ClientSecret) {
            # Using secret from string
            $logAnalyticsToken = Connect-CAMLClientSecret -ClientSecret $ClientSecret -ClientId $ClientId -TenantId $TenantId -Scope $logAnalyticsScope
        }

        # Step 2: Determine StartDate for following cmdlet. StartDate should be the date of the newest entry in our custom table, ideally.
        $resultStartDate = Get-CAMLCustomLogTable -Token $logAnalyticsToken -WorkspaceId $WorkspaceId -LawTable $MessageTraceDetailLawTable -ResultSize 1 -SortProperty 'EndDate' -ReturnProperty 'EndDate'

        # Step 3: Request a token for accessing Office 365 Reporting API Message Tracking Log
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

        # Step 4: Collect message tracking log data from last run time until now from log analytics workspace
        $resultMessageTrace = Get-CAMLMessageTrace -Token $reportingToken -StartDate $resultStartDate

        # end this function, if StartDate was later than calculated EndDate in 'Get-CAMLMessageTrace' or if no message tracking logs were found in 'Get-CAMLMessageTrace'
        if ($resultMessageTrace -like "*is later than*" -or $resultMessageTrace -like "No entries*") {
            Write-Host -Object $resultMessageTrace
            return
        }

        # Step 5: Get message trace detail data from message tracking log data
        ## If you want to use the non-parallel version, comment out the following line and uncomment the line after that
        $resultMessageTraceDetails = Get-CAMLMessageTraceDetail -Token $reportingToken -MessageTrace ($resultMessageTrace | ConvertFrom-Json)
        ## If you want to use the parallel version, comment out the line above and uncomment the following line
        ## Note: Please be aware that the parallel version is not supported in PowerShell 5.1 and may exceed limits documented at https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984332(v=office.15)#uncontrollable-events
        #$resultMessageTraceDetails = $resultMessageTrace | ConvertFrom-Json | ForEach-Object -Parallel {
        #    Get-CAMLMessageTraceDetail -Token $using:reportingToken -MessageTrace $_
        #} -ThrottleLimit 10

        # Step 6: Request a token for accessing Azure data collection endpoint
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

        # Step 7: Send message tracking log data to your Azure data collection endpoint aka Azure Log Analytics
        foreach($messageTraceDetail in $resultMessageTraceDetails) {
            Write-Host "Chunk $($resultMessageTraceDetails.IndexOf($messageTraceDetail) + 1) / $($resultMessageTraceDetails.count) - Add-CAMLDataToCustomLogTable"
            Add-CAMLDataToCustomLogTable -Body $messageTraceDetail -Token $monitorToken -DceLogsIngestionUri $DceLogsIngestionUri -DcrImmutableId $DcrImmutableId -LawTable $MessageTraceDetailLawTable
        }    
    }
    end {
        Write-Host "Function 'Add-CAMLMessageTraceDetailData' ended"
    }
}