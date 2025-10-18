param storage_name string = 'psstooring'
param location string = resourceGroup().location

resource storageAccounts 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storage_name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource storageAccounts_default 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccounts
  name: 'default'
}

resource storageAccounts_fileServices 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  parent: storageAccounts
  name: 'default'
}

resource storageAccounts_queueServices 'Microsoft.Storage/storageAccounts/queueServices@2022-09-01' = {
  parent: storageAccounts
  name: 'default'
}

resource storageAccounts_tableServices 'Microsoft.Storage/storageAccounts/tableServices@2022-09-01' = {
  parent: storageAccounts
  name: 'default'
}
