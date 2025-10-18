param service_name_a string = 'ps-videos'
param service_name_b string = 'ps-media'

param network object = {
  name:'network'
  address:'10.0.0.0/16'
  subnets:[
    {
      name: 'subnet-a'
      addressPrefix: '10.0.100.0/24'
    }
    {
      name: 'subnet-b'
      addressPrefix: '10.0.200.0/24'
    }]
  }

param location string = resourceGroup().location

module vnet_template '../atoms/vnet.bicep' = {
  name: '${network.name}-deployment'
  params: {
    network_name:network.name
    address_prefix:network.address
    subnets: network.subnets
    location: location
  }
}

module videos '../atoms/webapp-container.bicep' = {
  name: '${service_name_a}-deployment'
  params: {
    app_name: service_name_a
    location: location
    repository: 'psrepo.azurecr.io'
    image_name: 'videoservice:latest'
    managed_identity: 'psrepo-access'
    public_access: false
  }
}

module media '../atoms/webapp-container.bicep' = {
  name: '${service_name_b}-deployment'
  params: {
    app_name: service_name_b
    location: location
    repository: 'psrepo.azurecr.io'
    image_name: 'mediaservice:latest'
    managed_identity: 'psrepo-access'
    public_access: false
  }
}

module private_ep_videos '../atoms/private-ep.bicep' = {
  name: '${service_name_a}-pip-deployment'
  params: {
    private_ep_name: '${service_name_a}-pip'
    resource_external_name: videos.outputs.app_service.app_name
    network_name: vnet_template.outputs.network.network_name
    subnet_name: vnet_template.outputs.network.subnets[0].name
    location: location
  }
}

module private_ep '../atoms/private-ep.bicep' = {
  name: '${service_name_b}-pip-deployment'
  params: {
    private_ep_name: '${service_name_b}-pip'
    resource_external_name: media.outputs.app_service.app_name
    network_name: vnet_template.outputs.network.network_name
    subnet_name: vnet_template.outputs.network.subnets[1].name
    location: location
  }
  dependsOn: [
    private_ep_videos // wait for first private endpoint to complete
  ]
}
