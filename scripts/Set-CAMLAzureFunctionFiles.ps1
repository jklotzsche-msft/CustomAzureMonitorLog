<#
	.SYNOPSIS
	Set-CAMLAzureFunctionFiles

	.DESCRIPTION
	Creates a .zip-File out of the "function" folder and all subfolders and (if ResourceGroupName and FunctionAppName provided) uploads it to the Azure Function.
	If you want to upload the files to an Azure Function, the following modules are needed:
	- Az.Accounts
	- Az.Websites

	.PARAMETER ResourceGroupName
	Provide a String containing the name of your Azure Resource Group.

	.PARAMETER AppName
	Provide a String containing the name of your Azure Function App.

	.EXAMPLE
	Set-CAMLAzureFunctionFiles.ps1 -ResourceGroupName 'rg-CAML' -FunctionAppName 'func-CAML'

	Creates a .zip-File out of the "function" folder and all subfolders and uploads it to the Azure Function App.

	.LINK
    https://github.com/jklotzsche-msft/CustomAzureMonitorLog
#>
[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $ResourceGroupName,
    
    [Parameter()]
    [String]
    $FunctionAppName
)

# Check, if PowerShell connection to Azure is established
if (($ResourceGroupName -and $FunctionAppName) -and ($null -eq (Get-AzContext))) {
	Write-Host 'Checking, if connection to Azure has been established...' -NoNewline
	$exception = [System.InvalidOperationException]::new('Not yet connected to the Azure Service. Use "Connect-AzAccount -TenantId <TenantId>" to establish a connection and select the correct subscription using "Set-AzContext"!')
	$errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, 'NotConnected', 'InvalidOperation', $null)
	
	$PSCmdlet.ThrowTerminatingError($errorRecord)
	Write-Host 'OK' -ForegroundColor Green
}

# Prepare working directory
$workingDirectory = Split-Path $PSScriptRoot

# Prepare output path and copy function folder to output path
$null = Remove-Item -Path "$workingDirectory/publish" -Recurse -Force -ErrorAction Ignore
$null = Remove-Item -Path "$workingDirectory/Function.zip" -Force -ErrorAction Ignore
$buildFolder = New-Item -Path $workingDirectory -Name 'publish' -ItemType Directory -Force -ErrorAction Stop
$null = Copy-Item -Path "$workingDirectory/function/*" -Destination $buildFolder.FullName -Recurse -Force

# Package & Cleanup
$null = Compress-Archive -Path "$($buildFolder.FullName)/*" -DestinationPath "$workingDirectory/Function.zip"
$null = Remove-Item -Path $buildFolder.FullName -Recurse -Force -ErrorAction Ignore

# Publish to Azure
if ($ResourceGroupName -and $FunctionAppName) {
    Write-Verbose "Publishing Function App to $ResourceGroupName/$FunctionAppName"
    Publish-AzWebApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ArchivePath "$workingDirectory/Function.zip" -Confirm:$false -Force
}