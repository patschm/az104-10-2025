param app_name string = 'ps-wep'
param location string = resourceGroup().location
param nr_of_sites int = 1

var var_app_plan = '${app_name}-plan'

resource app_plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: var_app_plan
  location: location
  sku: {
    name: 'P1V3'
  }
}

resource app 'Microsoft.Web/sites@2022-03-01' = [for nr in range(0, nr_of_sites): {
  name: '${app_name}${nr}'
  location: location
  properties: {
    serverFarmId: app_plan.id
  }
}]
