<#
	.SYNOPSIS
	Get-CAMLMessageTrace

	.DESCRIPTION
	Get Exchange Online Message Tracking Logs as JSON object

	This cmdlet must have a valid token to authenticate at reports.office365.com and request message tracking log data.
	If message tracking log data of the provided timeframe is received, the data is converted to a JSON object and returned.

	.PARAMETER Token
	Provide a PSCustomObject containing token information for endpoint reports.office365.com
	You can use the cmdlet "Connect-CAMLClientCertificate" of this module to request a token.

	.PARAMETER StartDate
	Provide a String containing a UTC datetime. This datetime will be used to define the StartDate for requesting message tracking log data.
	For more information check the documented field "StartDate" at https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984335(v=office.15)

	The recommended datetime format is <year>-<month>-<day>T<hour>:<minute>:<second>Z
	For example: 2022-11-30T14:00:00Z

	.PARAMETER EndDate
	Provide a String containing a UTC datetime. This datetime will be used to define the EndDate for requesting message tracking log data.
	For more information check the documented field "EndDate" at https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984335(v=office.15)

	The recommended datetime format is <year>-<month>-<day>T<hour>:<minute>:<second>Z
	For example: 2022-11-30T14:15:00Z

	.PARAMETER ResultSize
	Provide an Integer to define the amount data rows you want to receive. Could be used, e.g. if you use this cmdlet interactively.

	.EXAMPLE
	$token = Connect-CAMLClientCertificate @tokenProperties
	PS > Get-CAMLMessageTrace -Token $token

	Request token for reports.office365.com Api and call Reporting Api to gather a all message tracking log data within an automatically calculated timeframe.
	In this example, StartDate will be the current time -75 minutes, EndDate will be the current time -60 minutes

	.EXAMPLE
	$token = Connect-CAMLClientCertificate @tokenProperties
	PS > Get-CAMLMessageTrace -Token $token -StartDate "2022-11-30T14:00:00Z" -EndDate "2022-11-30T14:15:00Z"

	Request token for reports.office365.com Api and call Reporting Api to gather a all message tracking log data within the provided timeframe.

	.EXAMPLE
	$token = Connect-CAMLClientCertificate @tokenProperties
	PS > Get-CAMLMessageTrace -Token $token -StartDate "2022-11-30T14:00:00Z" -EndDate "2022-11-30T14:15:00Z" -ResultSize 1 | Out-File -FilePath "C:\temp\MessageTrace_Sample.json"

	Request token for reports.office365.com Api and call Reporting Api to gather a sample message tracking log and export it to a .json file.
	StartDate and EndDate define, that the sample message tracking log should be within this time range.

	.NOTES
	Documentation for MessageTrace report of Exchange Online Reporting Api
	https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984335(v=office.15)	

	.LINK
    https://github.com/jklotzsche-msft/CustomAzureMonitorLog
#>
function Get-CAMLMessageTrace {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]
		$Token,

		[Parameter()]
		[String]
		$StartDate,

		[Parameter()]
		[String]
		$EndDate,

		[Parameter()]
		[Int]
		$ResultSize
	)
	
	begin {
		Write-Host "Function 'Get-CAMLMessageTrace' has been triggered"
		$ErrorActionPreference = 'Stop'
	}
	process {
		# build the header information including the access token
		$headers = @{
			'Authorization' = ('Bearer {0}' -f $token.access_token)
			'Content-Type'  = 'application/json; charset=utf-8'
		}

		# if no StartDate was provided, set startdate as (now - 1.25h), to be sure that the status of each message tracking log entry is ready
		if (-not $StartDate) {
			$StartDate = (Get-Date).ToUniversalTime().AddMinutes(-75).ToString("u").replace(" ","T")
		}

		# if no EndDate was provided, set enddate as (now - 1h), to be sure that the status of each message tracking log entry is ready
		if (-not $EndDate) {
			$EndDate = (Get-Date).ToUniversalTime().AddMinutes(-60).ToString("u").replace(" ","T")
		}

		if($StartDate -ge $EndDate) {
			# if StartDate is later than EndDate end this function
			Write-Output -InputObject "StartDate $StartDate is later than EndDate: $EndDate. Try again later."
			return
		}


		# Call the reports.office365.com rest api to query the message tracking log
		$uri = @'
https://reports.office365.com/ecp/reportingwebservice/reporting.svc/MessageTrace?$filter=StartDate eq datetime'{0}' and EndDate eq datetime'{1}'&$format=json
'@ -f $StartDate, $EndDate
	
		if ($ResultSize) {
			$uri += '&$top={0}' -f $ResultSize
		}
		
		Write-Host "Calling $uri to get message tracking log(s)"
		$MessagetraceResults = Invoke-RestMethod -Uri $uri -Headers $headers | Select-Object -ExpandProperty d
		
		# Differentiate between ResultSize and no ResultSize provided
		if (-not $ResultSize) {
			# If ResultSize was not provided, the result will be in property d
			$MessagetraceResults = $MessagetraceResults | Select-Object -ExpandProperty results
		}
		
		# If no entries are found we can end the script here, as there is nothing to send to our loganalytics workspace
		if ($MessagetraceResults.count -eq 0) {
			Write-Output "No entries in message tracking log found between StartDate $StartDate and EndDate $EndDate"
			return
		}

		# Convert the results to a JSON object as array and return it
		Write-Host "Returning $($MessagetraceResults.count) message tracking log entries"
		$resultArray = @()
		$resultArray += $MessagetraceResults | Select-Object -ExcludeProperty __metadata, index | ConvertTo-Json -AsArray
		
		# Our Data Collection Endpoint can only handle 1MB of data per request, so we need to split the result in two parts if the result is more than 1MB
		if(($resultArray[0].length * 2) -gt 1MB) {
			$chunkCount = [Math]::Ceiling($resultArray[0].length / 1MB) # calculate the amount of chunks we need to split the result into
			$chunkSize = [math]::Ceiling($MessagetraceResults.count / $chunkCount) # calculate the amount of entries per chunk
			$resultArrayChunks = $MessagetraceResults | Group-Object -Property {[math]::Floor($_.Index / ($chunkSize))} # split the result into chunks
			$resultArray = @()
			foreach($resultArrayChunk in $resultArrayChunks) {
				# convert each chunk to a JSON object as array and add it to the resultArray
				$resultArray += $resultArrayChunk.Group | Select-Object -ExcludeProperty __metadata, index | ConvertTo-Json -AsArray
			}
		}

		# return the result
		$resultArray
	}
	end {
		Write-Host "Function 'Get-CAMLMessageTrace' ended"
	}
}