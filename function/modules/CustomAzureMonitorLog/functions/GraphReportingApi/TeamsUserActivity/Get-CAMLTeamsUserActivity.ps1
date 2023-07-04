<#
	.SYNOPSIS
	Get-CAMLTeamsUserActivity returns Teams user activity data as JSON object

	.DESCRIPTION
	The data is comparable to the "Get-CsTeamsUserActivityUserDetail" cmdlet of the Skype for Business Online Connector module.

	.PARAMETER Token
	Provide a PSCustomObject containing token information for endpoint "https://graph.microsoft.com".
	You can use the cmdlet "Connect-CAMLClientCertificate" of this module to request a token.

	.PARAMETER Period
	Provide a String containing a period of time. This period will be used to define the timeframe for requesting Teams user activity data.

	.PARAMETER Date
	Provide a String containing a date. This date will be used to define the timeframe for requesting Teams user activity data.

	.EXAMPLE
	Get-CAMLTeamsUserActivity -Token $token -Period D7

	This example shows how to request Teams user activity data for the last 7 days.

	.EXAMPLE
	Get-CAMLTeamsUserActivity -Token $token -Date '2020-01-01'

	This example shows how to request Teams user activity data for a specific date.

	.LINK
    https://github.com/jklotzsche-msft/CustomAzureMonitorLog
#>
function Get-CAMLTeamsUserActivity {
	[CmdletBinding(DefaultParameterSetName = 'Period')]
	Param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]
		$Token,

		[ValidateSet('D7', 'D30', 'D90', 'D180')]
		[Parameter(ParameterSetName = 'Period', Mandatory = $true)]
		[String]
		$Period,

		[ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
		[ValidateScript({
			if(([DateTime]::ParseExact($_, 'yyyy-MM-dd', $null)) -lt ((Get-Date).AddDays(-30))) {
				throw "Date must be within the last 28 days"
			}
			return $true
			
		})]
		[Parameter(ParameterSetName = 'Date', Mandatory = $true)]
		[String]
		$Date
	)
	
	begin {
		Write-Host "Function 'Get-CAMLTeamsUserActivity' has been triggered"
		$ErrorActionPreference = 'Stop'
	}
	process {
		# build the header information including the access token
		$headers = @{
			'Authorization' = ('Bearer {0}' -f $token.access_token)
			'Content-Type'  = 'application/json; charset=utf-8'
		}

		# Call the Microsoft Graph api to get the Teams User Activity report
		$uri = 'https://graph.microsoft.com/v1.0/reports/getTeamsUserActivityUserDetail'
	
		if ($Period) {
			$uri += "(period='$Period')"
		}

		if ($Date) {
			$uri += "(date='$Date')"
		}
		
		Write-Host "Calling $uri to get Teams Device Usage report"
		$teamsUserActivity = Invoke-RestMethod -Uri $uri -Headers $headers | ConvertFrom-Csv

		# Convert the received report to a JSON object and return it to the caller
		Write-Host "Returning data about $($teamsUserActivity.count) devices."
		$resultArray = @()
		$resultArray += ($teamsUserActivity | ConvertTo-Json -AsArray).replace(' ','').replace('ï»¿','') # remove spaces and BOM
		
		# Our Data Collection Endpoint can only handle 1MB of data per request, so we need to split the result in two parts if the result is more than 1MB
		if(($resultArray[0].length * 2) -gt 1MB) {
			$chunkCount = [Math]::Ceiling($resultArray[0].length / 1MB) # calculate the amount of chunks we need to split the result into
			$chunkSize = [math]::Ceiling($teamsUserActivity.count / $chunkCount) # calculate the amount of entries per chunk
			$resultArrayChunks = $teamsUserActivity | Group-Object -Property {[math]::Floor($teamsUserActivity.IndexOf($_) / $chunkSize)} # split the result into chunks
			$resultArray = @()
			foreach($resultArrayChunk in $resultArrayChunks) {
				# convert each chunk to a JSON object as array and add it to the resultArray
				$resultArray += ($resultArrayChunk.Group | ConvertTo-Json -AsArray).replace(' ','').replace('ï»¿','')
			}
		}

		# return the result
		$resultArray
	}
	end {
		Write-Host "Function 'Get-CAMLTeamsUserActivity' ended"
	}
}