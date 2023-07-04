@description('Provide the configuration of your CustomAzureMonitorLog.Config.psd1 file.')
param camlConfig object
param keyVaultImportPermissionsUserId string

var tableCount = length(camlConfig.LogAnalyticsWorkspace.Table)
// Workaround to create stream declerations
var streamDeclerationsArray = [for i in range(0, tableCount): {
    name: 'Custom-${camlConfig.LogAnalyticsWorkspace.Table[i].Name}'
    properties: {
      columns: camlConfig.LogAnalyticsWorkspace.Table[i].Columns
    }
  }]
var streamDeclerationsObject = toObject(streamDeclerationsArray, entry => entry.name, entry => entry.properties)
// /Workaround to create stream declerations

// Create log analytics workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: camlConfig.LogAnalyticsWorkspace.Name
  location: camlConfig.General.Location
  properties: {
    sku: {
      name: camlConfig.LogAnalyticsWorkspace.Sku
    }
    retentionInDays: camlConfig.LogAnalyticsWorkspace.RetentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Create log analytics workspace tables specified in config file
resource logAnalyticsWorkspaceTable 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = [for i in range(0, tableCount): {
  parent: logAnalyticsWorkspace
  name: camlConfig.LogAnalyticsWorkspace.Table[i].Name
  properties: {
    plan: camlConfig.LogAnalyticsWorkspace.Table[i].Plan
    schema: {
      name: camlConfig.LogAnalyticsWorkspace.Table[i].Name
      columns: camlConfig.LogAnalyticsWorkspace.Table[i].Columns
    }
  }
}]

// Create data collection endpoint
resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2021-09-01-preview' = {
  name: camlConfig.DataCollectionEndpoint.Name
  location: camlConfig.General.Location
  properties: {
    networkAcls: {
      publicNetworkAccess: camlConfig.DataCollectionEndpoint.PublicNetworkAccess
    }
  }
}

// Create data collection rule
resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2021-09-01-preview' = {
  name: camlConfig.DataCollectionRule.Name
  location: camlConfig.General.Location
  dependsOn: [
    logAnalyticsWorkspaceTable
  ]
  properties: {
    description: camlConfig.DataCollectionRule.Description
    dataCollectionEndpointId: dataCollectionEndpoint.id
    streamDeclarations: streamDeclerationsObject
    dataSources: {
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: logAnalyticsWorkspace.id
          name: replace(logAnalyticsWorkspace.properties.customerId, '-', '')
        }
      ]
    }
    dataFlows: [for j in range(0, tableCount): {
        streams: [
          'Custom-${camlConfig.LogAnalyticsWorkspace.Table[j].Name}'
        ]
        destinations: [
          replace(logAnalyticsWorkspace.properties.customerId, '-', '')
        ]
        transformKql: camlConfig.logAnalyticsWorkspace.Table[j].TransformKql
        outputStream: 'Custom-${camlConfig.LogAnalyticsWorkspace.Table[j].Name}'
    }]
  }
}

// Create a storage account for the function app
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'caml${uniqueString(resourceGroup().id)}'
  location: camlConfig.General.Location
  sku: {
    name: camlConfig.FunctionApp.StorageAccountType
  }
  kind: 'Storage'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

// Create a hosting plan for the function app
resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: camlConfig.FunctionApp.Name
  location: camlConfig.General.Location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  kind: 'functionapp'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

// Create the function app with the storage account and hosting plan and
// configure the app settings according to the configuration file
resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: camlConfig.FunctionApp.Name
  location: camlConfig.General.Location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(camlConfig.FunctionApp.Name)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'CAML_WorkspaceId'
          value: logAnalyticsWorkspace.properties.customerId
        }
        {
          name: 'CAML_MessageTraceLawTable'
          value: camlConfig.LogAnalyticsWorkspace.Table[0].Name
        }
        {
          name: 'CAML_MessageTraceDetailLawTable'
          value: camlConfig.LogAnalyticsWorkspace.Table[1].Name
        }
        {
          name: 'CAML_TeamsUserActivityLawTable'
          value: camlConfig.LogAnalyticsWorkspace.Table[2].Name
        }
        {
          name: 'CAML_TeamsDeviceUsageLawTable'
          value: camlConfig.LogAnalyticsWorkspace.Table[3].Name
        }
        {
          name: 'CAML_DceLogsIngestionUri'
          value: dataCollectionEndpoint.properties.logsIngestion.endpoint
        }
        {
          name: 'CAML_DcrImmutableId'
          value: dataCollectionRule.properties.immutableId
        }
        {
          name: 'CAML_ClientId'
          value: camlConfig.General.AppId
        }
        {
          name: 'CAML_TenantId'
          value: camlConfig.General.TenantId
        }
        {
          name: 'CAML_VaultName'
          value: camlConfig.KeyVault.Name
        }
        {
          name: 'CAML_VaultCertificateName'
          value: camlConfig.General.CertificateName
        }
        {
          name: 'WEBSITE_LOAD_CERTIFICATES'
          value: camlConfig.General.CertificateThumbprint
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

// Create the application insights resource
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: camlConfig.FunctionApp.Name
  location: camlConfig.General.Location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'IbizaWebAppExtensionCreate'
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Create the key vault resource
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: camlConfig.KeyVault.Name
  location: camlConfig.General.Location
  properties: {
    accessPolicies: [
      {
        objectId: functionApp.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
          certificates: [
            'get'
          ]
        }
        tenantId: camlConfig.General.TenantId
      }
      {
        objectId: keyVaultImportPermissionsUserId
        permissions: {
          certificates: [
            'import'
            'list'
          ]
        }
        tenantId: camlConfig.General.TenantId
      }
    ]
    sku: {
      family: 'A'
      name: camlConfig.KeyVault.Sku
    }
    tenantId: camlConfig.General.TenantId
  }
}
