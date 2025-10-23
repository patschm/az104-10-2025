param location string = resourceGroup().location
param vm_names array = ['vm-1', 'vm-2']
param network_name string = 'network-lb'
param address_prefix string = '192.168.0.0/16'
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

var winsvr = {
  publisher: 'microsoftwindowsserver'
  offer:'windowsserver'
  sku:'2019-datacenter-gensecond'
  version:'latest'
  license: 'Windows_Server'
}

module vnet '../atoms/vnet.bicep' = {
  name: network_name
  params: {
    network_name:network_name
    address_prefix:address_prefix
    subnets: subnets
    location: location
  }
}

module vmres '../atoms/vm.bicep' = [for name in vm_names: {
  name:name
  params: {
    location:location
    image:winsvr
    vm_name: name
    network_name:network_name
    subnet_name:subnets[1].name
    with_public_ip:true
    with_iis:true
  }
  dependsOn:[vnet]
}]

