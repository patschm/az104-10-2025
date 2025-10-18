param vm_name string = 'ps-ubuntu'
param location string = resourceGroup().location
param username string = 'Student'
@secure()
param password string = 'Test_1234567'
param nic_name string = '${vm_name}-nic'
param ip_name string = '${vm_name}-ip'
param network_name string = 'network-1'
param nsg_name string = '${vm_name}-nsg'
param subnet_name string = 'public'
param with_public_ip bool = true
@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2204'
@allowed([
  'nginx'
  'apache'
])
param webServerVersion string = 'nginx'

var webServerReference = {
  nginx:{
    command:'az vm run-command invoke -g ${resourceGroup().name} --name ${vm_name} --command-id RunShellScript --scripts "sudo apt-get update && sudo apt-get install -y nginx"'
  } 
  apache: {
    command:'az vm run-command invoke -g ${resourceGroup().name} --name ${vm_name} --command-id RunShellScript --scripts "sudo apt update; sudo apt install -y apache2"'
  }
}

var imageReference = {
  'Ubuntu-1804': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2004': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}

module nsg 'nsg-linux-web.bicep' = {
  name: nsg_name
  params: {
    nsg_name: nsg_name
    location: location
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: nic_name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: with_public_ip ? {
            id: ip.id
          } : null
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', network_name, subnet_name)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.outputs.nsg_id
    }
  }
  dependsOn: [ nsg ]
}

resource ip 'Microsoft.Network/publicIPAddresses@2022-07-01' = if (with_public_ip) {
  name: ip_name
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

resource vm_ubuntu_web 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: vm_name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: imageReference[ubuntuOSVersion]
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: []
    }
    osProfile: {
      computerName: vm_name
      adminUsername: username
      adminPassword: password
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output clicmd string = webServerVersion == 'nginx' ? webServerReference[webServerVersion].command:webServerReference.apache.command
