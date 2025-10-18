param vm_name string = 'vm1'
param username string = 'Student'
@secure()
param password string = 'Test_1234567'
param location string = resourceGroup().location
param nic_name string = '${vm_name}-nic'
param ip_name string = '${vm_name}-ip'
param network_name string = 'my-network'
param subnet_name string = 'public'
param with_public_ip bool = true
param with_iis bool = false
param image object = {
  publisher: 'microsoftwindowsserver'
  offer:'WindowsServer'
  sku:'2025-datacenter'
  version:'latest'
  license: 'Windows_Server'
}
param nsg_name string = '${vm_name}-nsg'

module nsg 'nsg-rdp.bicep' = {
  name: nsg_name
  params: {
    nsg_name: nsg_name
    location: location
  }
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

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vm_name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: image.publisher
        offer: image.offer
        sku: image.sku
        version: image.version
      }
      osDisk: {
        osType: 'Windows'
        name: '${vm_name}-os-disk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 127
      }
    }
    osProfile: {
      computerName: vm_name
      adminUsername: username
      adminPassword: password
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Detach'
          }
        }
      ]
    }
    licenseType: image.license
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: nic_name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        id: resourceId('Microsoft.Network/networkInterfaces/ipConfigurations', nic_name, 'ipconfig1')
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: with_public_ip ? {
            id: ip.id
          }: null
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', network_name, subnet_name)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', nsg_name)
    }
  }
}

resource ipforward 'Microsoft.Compute/virtualMachines/runCommands@2024-11-01' = {
  name:'EnableIPForwarding'
  location:location
  parent:vm
  properties:{
    asyncExecution:false
    source:{
      script:'Set-NetIPInterface -Forwarding Enabled'
    }
  }
}

resource remoteaccess 'Microsoft.Compute/virtualMachines/runCommands@2024-11-01' = {
  name:'EnableRemoteAccess'
  location:location
  parent:vm
  properties:{
    asyncExecution:false
    source:{
      script:'Set-Service RemoteAccess -StartupType Automatic; Start-Service RemoteAccess'
    }
  }
}

resource ping 'Microsoft.Compute/virtualMachines/runCommands@2024-11-01' = {
  name:'EnableICMP'
  location:location
  parent:vm
  properties:{
    asyncExecution:false
    source:{
      script:'netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:8,any" dir=in action=allow'
    }
  }
}

resource iis2 'Microsoft.Compute/virtualMachines/runCommands@2024-11-01' = if(with_iis) {
  name:'install-iis'
  location:location
  parent:vm
  properties:{
    asyncExecution:false
    source:{
      script:'Install-WindowsFeature -name Web-Server -IncludeManagementTools'
    }
  }
}

output vmo object = vm
