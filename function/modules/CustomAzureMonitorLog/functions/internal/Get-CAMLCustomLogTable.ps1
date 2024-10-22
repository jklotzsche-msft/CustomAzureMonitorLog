<#
	.SYNOPSIS
	Get-CAMLCustomLogTable

	.DESCRIPTION
	Determine the value for "StartDate", to request a new set of data, e.g. message tracking logs.

	This cmdlet must have a valid token to authenticate at api.loganalytics.io and request the contents of your custom table.
	If the custom table already contains data, the latest entry is selected and the value of the "EndDate" column of this entry is selected as new "StartDate".
	If the custom table is empty (e.g. because it was created recently) it uses the current Date as the new StartDate

	.PARAMETER Token
	Provide a PSCustomObject containing token information for endpoint api.loganalytics.io
	You can use the cmdlet "Get-CAMLCustomLogTable" of this module to request a token.

	.PARAMETER WorkspaceId
	Provide the GUID of a log analytics workspace.
	This GUID will be used to define the identity of a log analytics workspace for requesting it's current content.
	
	You can find the Guid by navigating in the Azure portal (portal.azure.com) to your Log Analytics Workspace --> Overview --> Workspace ID
	For more information check the Azure Monitor Log Analytics Api documentation at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

	.PARAMETER LawTable
	Provide a String containing the name of your custom table in your log analytics workspace. This string must include the "_CL" suffix.
	This name will be used to define the identity of your custom table in your log analytics workspace for requesting it's current content.
	
	You can find the name by navigating in the Azure portal (portal.azure.com) to your Log Analytics Workspace --> Tables --> Table name
	For more information check the Azure Monitor Log Analytics Api documentation at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

	.PARAMETER SortProperty
	Provide a string containing the property, which you want to use to sort the custom table of your Log Analytics Workspace.
	This parameter defaults to 'Received', as this property is used by the MessageTrace use case if this module.

	.PARAMETER ReturnProperty
	Provide a string containing the property, of which you want to return the value as the new startdate.
	This parameter defaults to 'EndDate', as this property is used by the MessageTrace use case if this module.

	.INPUTS
	None

	.OUTPUTS
	None

	.EXAMPLE
	$token = Get-CAMLCustomLogTable @tokenProperties
	PS > Get-CAMLCustomLogTable -Token $token -WorkspaceId 'abcdef12-abcd-abcd-abcd-abcdef123456' -LawTable 'MyCustomTable_CL'

	Request token for api.loganalytics.io Api and call LogAnalytics Api to get the latest entry of the custom table.
	Then, the "EndDate" attribute of this latest entry is reformated to the pattern yyyy-MM-ddThh:mm:ssZ (e.g. 2022-12-06T17:20:00Z) and returned.
	If the custom table is empty the current datetime will be reformated and returned.

	.EXAMPLE
	$token = Get-CAMLCustomLogTable @tokenProperties
	PS > Get-CAMLCustomLogTable -Token $logAnalyticsToken -WorkspaceId $WorkspaceId -LawTable $LawTable -ResultSize 1 -SortProperty 'Received' -ReturnProperty 'EndDate'

	Determine last entry of message tracking logs in custom table.
	Then, the "EndDate" attribute of this latest entry is reformated to the pattern yyyy-MM-ddThh:mm:ssZ (e.g. 2022-12-06T17:20:00Z) and returned.

	.NOTES
	Azure Monitor Log Analytics Api documentation
	https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api

	.LINK
    https://github.com/jklotzsche-msft/CustomAzureMonitorLog
#>
function Get-CAMLCustomLogTable {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]
		$Token,

		[Parameter(Mandatory = $true)]
		[Guid]
		$WorkspaceId,

		[Parameter(Mandatory = $true)]
		[String]
		$LawTable,

		[Parameter()]
		[String]
		$ResultSize,

		[Parameter()]
		[String]
		$SortProperty,

		[Parameter()]
		[String]
		$ReturnProperty
	)
	
	begin {
		Write-Host "Function 'Get-CAMLCustomLogTable' has been triggered"
		$ErrorActionPreference = 'Stop'
	}
	process {
		# build the header information including the access token
		$headers = @{
			'Authorization' = ('Bearer {0}' -f $Token.access_token)
			'Content-Type'  = 'application/json'
		}
		
		<#
			The api.loganalytics.io endpoint is being replaced by api.loganalytics.azure.com.
			api.loganalytics.io will continue to be be supported for the forseeable future.

			More information at https://learn.microsoft.com/en-us/azure/azure-monitor/logs/api/access-api
		#>
		# Call the api.loganalytics.io rest api to query the custom table
		$uri = 'https://api.loganalytics.io/v1/workspaces/{0}/query?query={1}' -f $WorkspaceId, $LawTable

		if($ResultSize -or $SortProperty) {
			$uri += ' |'

			if($ResultSize) {
				$uri += ' top {0}' -f $ResultSize
			}
			
			if($SortProperty) {
				$uri += ' by {0} desc' -f $SortProperty
			}
		}

		Write-Host "Calling '$uri' to get latest entry of table $LawTable from workspace $WorkspaceId"
		$customTableContent = Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction SilentlyContinue

		# If the custom table in log analytics workspace is empty (e.g. because it was created recently) use the current Date -> 75 min ago as the new StartDate
		if($customTableContent.tables.rows.count -eq 0) {
			$newStartDate = (Get-Date).ToUniversalTime().AddMinutes(-75).ToString("u").replace(" ","T")
			Write-Host ("Returning {0} because no entry was found in custom table. This can be used as StartDate for requesting new data." -f $newStartDate)
			$newStartDate
			return
		}

		# create PSCustomObject based on newest entry in custom table
		$returnValue = [PSCustomObject]@{}
		for ($index = 0; $index -le ($customTableContent.tables.columns.name.count - 1); $index++) {
			$returnValue | Add-Member -MemberType NoteProperty -Name $customTableContent.tables.columns.name[$index] -Value $customTableContent.tables.rows[$index]
		}

		# if returnProperty provided, return the determined property as a string
		if($ReturnProperty) {
			$returnValue = $returnValue.$ReturnProperty
			# if the returnProperty value endswith 'Date' or startswith 'Time', reformat it to the pattern yyyy-MM-ddThh:mm:ssZ (e.g. 2022-12-06T17:20:00Z)
			if($ReturnProperty -like "*Date" -or $ReturnProperty -like "Time*") {
				$returnValue = $returnValue.ToString("u").replace(" ","T")
			}
		}
		Write-Host ("Returning {0} value(s) custom table." -f $ResultSize)
		Write-Output $returnValue
	}
	end {
		Write-Host "Function 'Get-CAMLCustomLogTable' ended"
	}
}