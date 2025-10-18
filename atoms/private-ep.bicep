param private_ep_name string = 'videos-pip'
param resource_external_name string = 'ps-videos'
param network_name string = 'network-1'
param subnet_name string = 'public'
param location string = resourceGroup().location

var network_id = resourceId('Microsoft.Network/virtualNetworks', network_name)
var subnet_id = resourceId('Microsoft.Network/virtualNetworks/subnets', network_name, subnet_name)
var webapp_id = resourceId('Microsoft.Web/sites', resource_external_name)  
var private_dns_name string = 'privatelink.azurewebsites.net'

resource private_ep_resource 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: private_ep_name
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${private_ep_name}-connection'
        properties: {
          privateLinkServiceId: webapp_id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
    subnet: {
      id: subnet_id
    }

  }
}
resource private_dns_zones 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: private_dns_name
  location: 'global'
}

resource private_dns_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: private_dns_zones
  name: '${private_dns_zones.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: network_id
    }
  }
}
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = {
  parent: private_ep_resource
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: private_dns_zones.id
        }
      }
    ]
  }
}
