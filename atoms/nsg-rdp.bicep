param location string = resourceGroup().location
param nsg_name string = 'nsg1'

resource nsg_name_resource 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: nsg_name
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        id: resourceId('Microsoft.Network/networkSecurityGroups/securityRules', nsg_name, 'RDP')
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
    ]
  }
}