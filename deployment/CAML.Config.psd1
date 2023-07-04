# Please make sure, that all provided names are in line with the Azure resource name rules at
# https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
@{
    General                = @{
        TenantId              = '00000000-0000-0000-0000-000000000000' # Azure AD tenant id
        SubscriptionId        = '00000000-0000-0000-0000-000000000000' # Azure subscription id
        Location              = 'westeurope' # Azure region, for example 'westeurope' or 'eastus'
        AppId                 = '00000000-0000-0000-0000-000000000000' # Azure AD application registration identifier. Must be created before deployment. Permissions must be assigned manually after the deployment.
        CertificateName       = 'myCertName' # Name of your certificate as it will be named in Azure Key Vault
        CertificateThumbprint = '0000000000000000000000000000000000000000' # Certificate Thumbprint
    }
    ResourceGroup          = @{
        Name = 'rg-CAML' # Azure resource group name
    }
    LogAnalyticsWorkspace  = @{
        Name            = 'log-CAML' # Azure Log Analytics workspace name
        RetentionInDays = '730' # Allowed values are: '30', '60', '90', '120', '150', '180', '270', '365', '550', '730', '1827', '3650'
        Sku             = 'pergb2018' # Allowed values are: 'Free', 'PerGB2018', 'Standalone', 'PerNode'
        Table           = @( # Columns must not have special characters or spaces
            @{
                Name         = 'CAMLMessageTrace_CL' # Log Analytics custom log table name. _CL must be appended to the name!
                Plan         = 'Analytics' # Allowed values are: 'CapacityReservation', 'Analytics'
                TransformKql = 'source | extend TimeGenerated = todatetime(now())'
                Columns      = @( # the following columns are needed for storing message trace data in a custom log table
                    @{
                        name = 'Status'
                        type = 'string'
                    }
                    @{
                        name = 'StartDate'
                        type = 'datetime'
                    }
                    @{
                        name = 'ToIP'
                        type = 'dynamic'
                    }
                    @{
                        name = 'Size'
                        type = 'int'
                    }
                    @{
                        name = 'FromIP'
                        type = 'string'
                    }
                    @{
                        name = 'SenderAddress'
                        type = 'string'
                    }
                    @{
                        name = 'Organization'
                        type = 'string'
                    }
                    @{
                        name = 'MessageId'
                        type = 'string'
                    }
                    @{
                        name = 'Subject'
                        type = 'string'
                    }
                    @{
                        name = 'EndDate'
                        type = 'datetime'
                    }
                    @{
                        name = 'MessageTraceId'
                        type = 'string'
                    }
                    @{
                        name = 'RecipientAddress'
                        type = 'string'
                    }
                    @{
                        name = 'Received'
                        type = 'datetime'
                    }
                    @{
                        name = 'TimeGenerated'
                        type = 'datetime'
                    }
                )
            },
            @{
                Name         = 'CAMLMessageTraceDetail_CL' # Log Analytics custom log table name
                Plan         = 'Analytics' # Allowed values are: 'CapacityReservation', 'Analytics'
                TransformKql = 'source | extend TimeGenerated = todatetime(now())'
                Columns      = @( # the following columns are needed for storing message trace detail data in a custom log table. Special info: Date is a reserved column name in Log Analytics workspaces and cannot be used, although it is provided by the message trace API. If needed, please uncomment the following lines, use a different column name and add the value of the date field to your column. Do so in the Get-CAMLMessageTraceDetail function in the CAML.psm1 file.
                    @{
                        name = 'Action'
                        type = 'string'
                    }
                    @{
                        name = 'Data'
                        type = 'string'
                    }
                    @{
                        name = 'Detail'
                        type = 'string'
                    }
                    @{
                        name = 'EndDate'
                        type = 'datetime'
                    }
                    @{
                        name = 'Event'
                        type = 'string'
                    }
                    @{
                        name = 'MessageId'
                        type = 'string'
                    }
                    @{
                        name = 'MessageTraceId'
                        type = 'string'
                    }
                    @{
                        name = 'Organization'
                        type = 'string'
                    }
                    @{
                        name = 'RecipientAddress'
                        type = 'string'
                    }
                    @{
                        name = 'SenderAddress'
                        type = 'string'
                    }
                    @{
                        name = 'StartDate'
                        type = 'datetime'
                    }
                    @{
                        name = 'TimeGenerated'
                        type = 'datetime'
                    }
                )
            },
            @{
                Name            = 'CAMLTeamsUserActivity_CL' # Log Analytics custom log table name
                Plan            = 'Analytics' # Allowed values are: 'CapacityReservation', 'Analytics'
                TransformKql    = 'source | extend TimeGenerated = todatetime(now())'
                RetentionInDays = 7
                Columns         = @( # the following columns are needed for storing Teams User Activity data in a custom log table
                    @{
                        name = 'AdHocMeetingsAttendedCount'
                        type = 'string'
                    }
                    @{
                        name = 'AdHocMeetingsOrganizedCount'
                        type = 'string'
                    }
                    @{
                        name = 'AssignedProducts'
                        type = 'string'
                    }
                    @{
                        name = 'AudioDuration'
                        type = 'string'
                    }
                    @{
                        name = 'AudioDurationInSeconds'
                        type = 'string'
                    }
                    @{
                        name = 'CallCount'
                        type = 'string'
                    }
                    @{
                        name = 'DeletedDate'
                        type = 'string'
                    }
                    @{
                        name = 'HasOtherAction'
                        type = 'string'
                    }
                    @{
                        name = 'IsDeleted'
                        type = 'string'
                    }
                    @{
                        name = 'IsLicensed'
                        type = 'string'
                    }
                    @{
                        name = 'LastActivityDate'
                        type = 'string'
                    }
                    @{
                        name = 'MeetingCount'
                        type = 'string'
                    }
                    @{
                        name = 'MeetingsAttendedCount'
                        type = 'string'
                    }
                    @{
                        name = 'MeetingsOrganizedCount'
                        type = 'string'
                    }
                    @{
                        name = 'PostMessages'
                        type = 'string'
                    }
                    @{
                        name = 'PrivateChatMessageCount'
                        type = 'string'
                    }
                    @{
                        name = 'ReplyMessages'
                        type = 'string'
                    }
                    @{
                        name = 'ReportPeriod'
                        type = 'string'
                    }
                    @{
                        name = 'ScheduledOnetimeMeetingsAttendedCount'
                        type = 'string'
                    }
                    @{
                        name = 'ScheduledOnetimeMeetingsOrganizedCount'
                        type = 'string'
                    }
                    @{
                        name = 'ScheduledRecurringMeetingsAttendedCount'
                        type = 'string'
                    }
                    @{
                        name = 'ScheduledRecurringMeetingsOrganizedCount'
                        type = 'string'
                    }
                    @{
                        name = 'ScreenShareDuration'
                        type = 'string'
                    }
                    @{
                        name = 'ScreenShareDurationInSeconds'
                        type = 'string'
                    }
                    @{
                        name = 'SharedChannelTenantDisplayNames'
                        type = 'string'
                    }
                    @{
                        name = 'TeamChatMessageCount'
                        type = 'string'
                    }
                    @{
                        name = 'TenantDisplayName'
                        type = 'string'
                    }
                    @{
                        name = 'UrgentMessages'
                        type = 'string'
                    }
                    @{
                        name = 'UserId'
                        type = 'string'
                    }
                    @{
                        name = 'UserPrincipalName'
                        type = 'string'
                    }
                    @{
                        name = 'VideoDuration'
                        type = 'string'
                    }
                    @{
                        name = 'VideoDurationInSeconds'
                        type = 'string'
                    }
                    @{
                        name = 'ReportRefreshDate'
                        type = 'string'
                    }
                    @{
                        name = 'TimeGenerated'
                        type = 'datetime'
                    }
                )
            },
            @{
                Name            = 'CAMLTeamsDeviceUsage_CL' # Log Analytics custom log table name
                Plan            = 'Analytics' # Allowed values are: 'CapacityReservation', 'Analytics'
                TransformKql    = 'source | extend TimeGenerated = todatetime(now())'
                RetentionInDays = 7
                Columns         = @( # the following columns are needed for storing Teams Device Usage data data in a custom log table
                    @{
                        name = 'DeletedDate'
                        type = 'string'
                    }
                    @{
                        name = 'IsDeleted'
                        type = 'string'
                    }
                    @{
                        name = 'IsLicensed'
                        type = 'string'
                    }
                    @{
                        name = 'LastActivityDate'
                        type = 'string'
                    }
                    @{
                        name = 'ReportPeriod'
                        type = 'string'
                    }
                    @{
                        name = 'UsedChromeOS'
                        type = 'string'
                    }
                    @{
                        name = 'UsedAndroidPhone'
                        type = 'string'
                    }
                    @{
                        name = 'UsediOS'
                        type = 'string'
                    }
                    @{
                        name = 'UsedLinux'
                        type = 'string'
                    }
                    @{
                        name = 'UsedMac'
                        type = 'string'
                    }
                    @{
                        name = 'UsedWeb'
                        type = 'string'
                    }
                    @{
                        name = 'UsedWindows'
                        type = 'string'
                    }
                    @{
                        name = 'UsedWindowsPhone'
                        type = 'string'
                    }
                    @{
                        name = 'UserId'
                        type = 'string'
                    }
                    @{
                        name = 'UserPrincipalName'
                        type = 'string'
                    }
                    @{
                        name = 'ReportRefreshDate'
                        type = 'string'
                    }
                    @{
                        name = 'TimeGenerated'
                        type = 'datetime'
                    }
                )
            }
        )
    }
    DataCollectionEndpoint = @{
        Name                = 'dce-CAML' # Azure Data Collection Endpoint name
        PublicNetworkAccess = 'Enabled' # Allowed values are: 'Enabled' or 'Disabled', although this solution has not been tested using 'Disabled' 
    }
    DataCollectionRule     = @{
        Name        = 'dcr-CAML' # Azure Data Collection Rule name, one rule per custom log table will be created with a suffix of the custom log table name (e.g.: dcr-CAML-CAMLMessageTrace_CL)
        Description = 'Custom Log Table Data Collection Rule'
    }
    FunctionApp            = @{
        Name               = 'func-CAML' # Azure Function App name. Default value: 'func-CAML'. This name must be unique across all of Azure. If you use the default name a random suffix will be added.
        StorageAccountType = 'Standard_LRS' # Allowed values are: 'Standard_LRS', 'Standard_GRS', 'Standard_RAGRS'
    }
    KeyVault               = @{
        Name = 'kv-CAML' # Azure Key Vault name, must be between 3-24 alphanumeric characters. The name must begin with a letter, end with a letter or digit, and not contain consecutive hyphens. Default value: 'kv-CAML'. This name must be unique across all of Azure. If you use the default name a random suffix will be added.
        Sku  = 'Standard' # Allowed values are: 'Standard' or 'Premium'
    }
}
