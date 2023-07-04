# Manual removal of this solution

This chapter is planned for a future release.
Quick info: if you want to remove the solution manually and install it shortly after again:

- Delete the Log Analytics workspace through a hard delete using PowerShell. This will delete the workspace and all data in it. You can use the following PowerShell command to do so:

``` PowerShell
Remove-AzOperationalInsightsWorkspace -ResourceGroupName <resource group name> -Name <workspace name> -ForceDelete
```

- Delete the resource group using the Azure Portal
- Delete the application registration using the Azure Portal
- Purge the Azure KeyVault using the Azure Portal from the recycle bin
