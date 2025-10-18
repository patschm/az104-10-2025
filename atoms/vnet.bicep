param network_name string = 'network-1'
param address_prefix string = '192.168.0.0/16'
param location string = resourceGroup().location
param subnets array = [
  {
    name: 'public'
    addressPrefix: '192.168.10.0/25'
  }
  {
    name: 'private'
    addressPrefix: '192.168.50.0/25'
  }
  {
    name: 'DMZ'
    addressPrefix: '192.168.100.0/25'
  }
  {
    name: 'AzureFirewallSubnet'
    addressPrefix: '192.168.200.0/25'
  }
]


var subnetloop = [for item in subnets: {
  name: item.name
  id: resourceId('Microsoft.Network/virtualNetworks/subnets', network_name, item.name)
  properties: {
    addressPrefix: item.addressPrefix
  }
  type: 'Microsoft.Network/virtualNetworks/subnets'
}]

resource network_name_resource 'Microsoft.Network/virtualNetworks@2024-10-01' = {
  name: network_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        address_prefix
      ]
    }
    subnets: subnetloop
  }
}

output network object = {
  network_name: network_name_resource.name
  subnets: network_name_resource.properties.subnets
} 
