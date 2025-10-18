param networks array = [{
  name:'network-WEU'
  location: 'westeurope'
  address:'10.200.0.0/16'
  subnets:[
    {
      name: 'spoke-WEU-1'
      addressPrefix: '10.200.0.0/24'
    }
    {
      name: 'spoke-WEU-2'
      addressPrefix: '10.200.100.0/24'
    }]
  }
  {
    name:'network-NEU'
    location: 'northeurope'
    address:'10.100.0.0/16'
    subnets:[
      {
        name: 'spoke-NEU-1'
        addressPrefix: '10.100.0.0/24'
      }
      {
        name: 'spoke-NEU-2'
        addressPrefix: '10.100.100.0/24'
      }]
  }
  {
    name:'hub-WEU'
    location: 'westeurope'
    address:'10.0.0.0/16'
    subnets:[
      {
        name: 'default'
        addressPrefix: '10.0.0.0/24'
      }]
  }
  ]

targetScope='subscription'
resource new_group 'Microsoft.Resources/resourceGroups@2024-03-01' = [for network in networks: {
  name: '${network.name}-grp'
  location:network.location
}
]  

module vm_template '../atoms/vnet.bicep' = [for (network, i) in networks: {
  name: network.name
  scope: new_group[i]
  params: {
    network_name:network.name
    address_prefix:network.address
    subnets: network.subnets
    location: network.location
  }
}]

module vmback '../atoms/vm-with-nsg.bicep' = {
  name: 'vm-back'
  scope: new_group[0]
  params: {
    network_name: networks[0].name
    location:networks[0].location
    vm_name:'vm-back'
    subnet_name:networks[0].subnets[0].name
    with_public_ip:false
  }
  dependsOn:[vm_template]
}
module vmfront '../atoms/vm-with-nsg.bicep' = {
  name: 'vm-front'
  scope: new_group[1]
  params: {
    network_name: networks[1].name
    location: networks[1].location
    vm_name:'vm-front'
    subnet_name:networks[1].subnets[0].name
    with_public_ip:true
  }
  dependsOn:[vm_template]
}

module nva '../atoms/vm-server.bicep' = {
  name: 'nva'
  scope: new_group[2]
  params: {
    network_name: networks[2].name
    location: networks[2].location
    vm_name:'nva'
    subnet_name:networks[2].subnets[0].name
    with_public_ip:true
    with_iis:false
  }
  dependsOn:[vm_template]
}

