<#
	.SYNOPSIS
	Add-CAMLDataToCustomLogTable

	.DESCRIPTION
	Sends the collected data as JSON to a custom table in LogAnalytics workspace.

	This cmdlet must have a valid token to authenticate at your custom data collection endpoint of your LogAnalytics workspace.
	
	.PARAMETER Token
	Provide a PSCustomObject containing token information for your data collection endpoint uri.
	You can use the cmdlet "Connect-CAMLClientCertificate" of this module to request a token.

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

	.PARAMETER LawTable
	Provide a String containing the name of your custom table in your log analytics workspace. This string must include the "_CL" suffix.
	The string you provide will be used to concatenate the data collection endpoint url, combining the DceLogsIngestionUri, DcrImmutableId and LawTable.
	
	You can find the name by navigating in the Azure portal (portal.azure.com) to your Log Analytics Workspace --> Tables --> Table name
	For more information check the Azure Monitor Log Analytics Api documentation at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

	.PARAMETER Body
	Provide a String containing a JSON Array of the data, which you want to send to your custom Azure Monitor table.
	
	.INPUTS
	None

	.OUTPUTS
	None

	.EXAMPLE
	$token = Connect-CAMLClientCertificate @tokenProperties
	$dceLogsIngestionUri = 'https://mycustomtableendpoint.datacenter-1.ingest.monitor.azure.com'
	$dcrImmutableId = 'dcr-0123456789abcdef0123456789abcdef'
	$lawTable = 'MyCustomTable_CL'
	$body = '{"Property1": "Value1","Property2": "Value2"}'
	PS > Add-CAMLDataToCustomLogTable -Token $token -DceLogsIngestionUri $dceLogsIngestionUri -DcrImmutableId $dcrImmutableId -LawTable $lawTable -Body $body 

	Request token for your data collection endpoint and call this endpoint to send the current data to your custom table.

	.NOTES
	Azure Monitor Log Analytics Api documentation
	https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

	.LINK
    https://github.com/jklotzsche-msft/CustomAzureMonitorLog
#>

function Add-CAMLDataToCustomLogTable {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]
		$Token,

		[Parameter(Mandatory = $true)]
		[String]
		$DceLogsIngestionUri,

		[Parameter(Mandatory = $true)]
		[String]
		$DcrImmutableId,

		[Parameter(Mandatory = $true)]
		[String]
		$LawTable,

		[Parameter(Mandatory = $true)]
		[String]
		$Body
	)
	
	begin {
		Write-Host "Function 'Add-CAMLDataToCustomLogTable' has been triggered"
		$ErrorActionPreference = 'Stop'
	}
	process {
		$headers = @{
			'Authorization' = ('Bearer {0}' -f $Token.access_token)
			'Content-Type'  = 'application/json; charset=utf-8-sig'
		}
		$uri = '{0}/dataCollectionRules/{1}/streams/Custom-{2}?api-version=2021-11-01-preview' -f $DceLogsIngestionUri, $DcrImmutableId, $LawTable

		Write-Host "Calling $uri to store data to log analytics workspace."
		Invoke-RestMethod -Uri $uri -Method 'Post' -Body $Body -Headers $headers
	}
	end {
		Write-Host "Function 'Add-CAMLDataToCustomLogTable' ended"
	}
}