<#
.SYNOPSIS
	This function adds message trace data to a custom log analytics workspace.
	
.DESCRIPTION
	This function adds message trace data to a custom log analytics workspace.
	The data is comparable to the "Get-MessageTrace" cmdlet of the ExchangeOnlineManagement module.
	The function is intended to be used as a timer function in a Azure Function App.
#>

param($Timer)

# Set ErrorActionPreference, so this Function stops if any cmdlet fails
$global:ErrorActionPreference = 1

# Prepare the command execution object
$commandExecution = @{}

# Add the command execution properties, which are prefixed with 'CAML_' in the environment variables
$commandExecutionProps = Get-ChildItem env: | Where-Object {$_.Name -like 'CAML_*'}

# Add the command execution properties to the command execution object if the property name is a valid parameter name
foreach($commandExecutionProp in $commandExecutionProps) {
	$commandExecutionKey = $commandExecutionProp.Name.replace('CAML_','')
	if($commandExecutionKey -in (Get-Command Add-CAMLMessageTraceData).Parameters.Keys){
		$commandExecution.Add($commandExecutionKey, $commandExecutionProp.Value)
	}
}

# Execute the command
Add-CAMLMessageTraceData @commandExecution