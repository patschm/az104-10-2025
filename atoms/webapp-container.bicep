param app_name string = 'ps-videos'
param location string = resourceGroup().location
param repository string = 'psrepo.azurecr.io'
param image_name string = 'videoservice:latest'
param managed_identity string = 'psrepo-access' 
//param network_name string = 'network-1'
//param subnet_name string = 'private'
param public_access bool = true

var var_app_plan = '${app_name}-plan'
//var subnet_id = resourceId('Microsoft.Network/virtualNetworks/subnets', network_name, subnet_name)

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: managed_identity
  scope: resourceGroup('Dapr')
}
resource app_plan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: var_app_plan
  location: location
  sku: {
    name: 'P0v3'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource app 'Microsoft.Web/sites@2024-11-01' = {
  name: app_name
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    serverFarmId: app_plan.id
    reserved: true
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'DOCKER|${repository}/${image_name}'
      acrUseManagedIdentityCreds: true
      alwaysOn: true
    }
    publicNetworkAccess: public_access ? 'Enabled' : 'Disabled'
    // virtualNetworkSubnetId: subnet_id
  }
}

resource sites_ps_wep_name_web 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: app
  name: 'web'
  properties: {
    linuxFxVersion: 'DOCKER|${repository}/${image_name}'
    acrUseManagedIdentityCreds: true
    acrUserManagedIdentityID: identity.properties.clientId
  }
}

output app_service object = {
  app_name: app.name
  app_id: app.id
}
