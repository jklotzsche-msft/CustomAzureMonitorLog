<#
	.SYNOPSIS
	Get-CAMLMessageTraceDetail

	.DESCRIPTION
	Get-CAMLMessageTraceDetail returns message trace detail data as JSON object

	This cmdlet must have a valid token to authenticate at reports.office365.com and request message tracking log data.
	If message tracking log data of the provided timeframe is received, the data is converted to a JSON object and returned.

	.PARAMETER Token
	Provide a PSCustomObject containing token information for endpoint reports.office365.com
	You can use the cmdlet "Connect-CAMLClientCertificate" of this module to request a token.

	.PARAMETER MessageTrace
	Provide a PSCustomObject containing message trace data. This data is required to request message trace detail data.
	You can use the cmdlet "Get-CAMLMessageTrace" of this module to request message trace data.

	.EXAMPLE
	$token = Connect-CAMLClientCertificate @tokenProperties
	PS > $MessageTrace = Get-CAMLMessageTrace -Token $token
	PS > $MessageTraceDetail = Get-CAMLMessageTraceDetail -Token $token -MessageTrace $MessageTrace
	
	This example shows how to request message trace detail data for the message trace data received by the cmdlet "Get-CAMLMessageTrace".
	
	.EXAMPLE
	$token = Connect-CAMLClientCertificate @tokenProperties
	PS > $MessageTrace = Get-CAMLMessageTrace -Token $token
	PS > $MessageTraceDetail = Get-CAMLMessageTraceDetail -Token $token -MessageTrace $MessageTrace | ConvertTo-Json -Depth 3

	This example shows how to request message trace detail data for the message trace data received by the cmdlet "Get-CAMLMessageTrace" and convert the result to a JSON object.

	.NOTES
	Documentation for MessageTrace report of Exchange Online Reporting Api
	https://learn.microsoft.com/en-us/previous-versions/office/developer/o365-enterprise-developers/jj984335(v=office.15)	

	.LINK
    https://github.com/jklotzsche-msft/CustomAzureMonitorLog
#>
function Get-CAMLMessageTraceDetail {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject]
		$Token,

		[Parameter(Mandatory = $true)]
		[PSCustomObject[]]
		$MessageTrace
	)
	
	begin {
		Write-Host "Function 'Get-CAMLMessageTraceDetail' has been triggered"
		$ErrorActionPreference = 'Stop'
	}
	process {
		# build the header information including the access token
		$headers = @{
			'Authorization' = ('Bearer {0}' -f $token.access_token)
			'Content-Type'  = 'application/json'
		}

		# Create a list to store the results
		$MessageTraceDetail = [System.Collections.Generic.List[object]]::new()

		# Loop through the message trace data and request the message trace details for each message trace
		foreach($messageTraceEntry in $MessageTrace) {
			# Call the reports.office365.com rest api to query the message trace details
			$uri = @'
https://reports.office365.com/ecp/reportingwebservice/reporting.svc/MessageTraceDetail?$filter=MessageTraceId eq guid'{0}' and RecipientAddress eq '{1}' and SenderAddress eq '{2}' and StartDate eq datetime'{3}' and EndDate eq datetime'{4}'&$format=json
'@ -f $messageTraceEntry.MessageTraceId, $messageTraceEntry.RecipientAddress, $messageTraceEntry.SenderAddress, $messageTraceEntry.StartDate.ToString("u").replace(" ","T"), $messageTraceEntry.EndDate.ToString("u").replace(" ","T")
		
			Write-Host "Calling $uri to get message tracking log(s)"
			$resultMessageTraceDetail = Invoke-RestMethod -Uri $uri -Headers $headers

			# Add the StartDate and EndDate to each message trace detail entry, as this information is not provided by the api
			foreach($resultMessageTraceDetailEntry in ($resultMessageTraceDetail.d.results | Select-Object -ExcludeProperty __metadata, index)) {
				$resultMessageTraceDetailEntry.StartDate = $messageTraceEntry.StartDate
				$resultMessageTraceDetailEntry.EndDate = $messageTraceEntry.EndDate
				$MessageTraceDetail.Add($resultMessageTraceDetailEntry)
			}
		}

		# Convert the results to a JSON object as array and return it
		Write-Host "Returning $($MessageTraceDetail.count) message tracking log detail entries"
		$resultArray = @()
		$resultArray += $MessageTraceDetail | ConvertTo-Json -AsArray
		
		# Our Data Collection Endpoint can only handle 1MB of data per request, so we need to split the result in two parts if the result is more than 1MB
		if(($resultArray[0].length * 2) -gt 1MB) {
			$chunkCount = [Math]::Ceiling($resultArray[0].length / 1MB) # calculate the amount of chunks we need to split the result into
			$chunkSize = [math]::Ceiling($MessageTraceDetail.count / $chunkCount) # calculate the amount of entries per chunk
			$resultArrayChunks = $MessageTraceDetail | Group-Object -Property {[math]::Floor($_.Index / ($chunkSize))} # split the result into chunks
			$resultArray = @()
			foreach($resultArrayChunk in $resultArrayChunks) {
				# convert each chunk to a JSON object as array and add it to the resultArray
				$resultArray += $resultArrayChunk.Group | ConvertTo-Json -AsArray
			}
		}

		# return the result
		$resultArray
	}
	end {
		Write-Host "Function 'Get-CAMLMessageTraceDetail' ended"
	}
}