@description('Application name')
param appName string = 'agicdemo'
@description('vnet name')
param vnetName string = '${appName}-vnet'

// AKS-1 subnet
@description('aks1 subnet name')
param aks1SubnetName string = 'aks1-subnet'
@description('aks1 subnet address prefix')
param aks1Prefix string = '10.1.0.0/16'
@allowed([
  'Enabled'
  'Disabled'
])
@description('private endpoint network pocilies of aks1 subnet')
param aksEndpointPolicy string = 'Enabled'
@allowed([
  'Enabled'
  'Disabled'
])
@description('private link service pocilies of aks1 subnet')
param aksServicePolicy string = 'Enabled'

// AKS-2 subnet
@description('aks2 subnet name')
param aks2SubnetName string = 'aks2-subnet'
@description('aks2 subnet address prefix')
param aks2Prefix string = '10.2.0.0/16'

// Private Link subnet
@description('private link subnet name')
param privateLinkSubnetName string = '${vnetName}-private-link-subnet'
@description('private link subnet address prefix')
param privateLinkPrefix string = '10.3.0.0/16'
@allowed([
  'Enabled'
  'Disabled'
])
@description('private endpoint network pocilies of private link subnet')
param privateLinkEndpointPolicy string = 'Disabled'
@allowed([
  'Enabled'
  'Disabled'
])
@description('private link service pocilies of private link subnet')
param privateLinkServicePolicy string = 'Enabled'

// Bastion subnet
@description('bastion subnet name')
param bastionSubnetName string = '${vnetName}-bastion-subnet'
@description('bastion subnet address prefix')
param bastionPrefix string = '10.4.0.0/16'
@allowed([
  'Enabled'
  'Disabled'
])
@description('private endpoint network pocilies of bastion subnet')
param bastionEndpointPolicy string = 'Enabled'
@allowed([
  'Enabled'
  'Disabled'
])
@description('private link service pocilies of bastion subnet')
param bastionServicePolicy string = 'Enabled'

var subnets = [
  {
    name: aks1SubnetName
    prefix: aks1Prefix
    endpointPolicy: aksEndpointPolicy
    servicePolicy: aksServicePolicy
  }
  {
    name: aks2SubnetName
    prefix: aks2Prefix
    endpointPolicy: aksEndpointPolicy
    servicePolicy: aksServicePolicy
  }
  {
    name: privateLinkSubnetName
    prefix: privateLinkPrefix
    endpointPolicy: privateLinkEndpointPolicy
    servicePolicy: privateLinkServicePolicy
  }
  {
    name: bastionSubnetName
    prefix: bastionPrefix
    endpointPolicy: bastionEndpointPolicy
    servicePolicy: bastionServicePolicy
  }
]

module vn 'bicep-templates/networks/vnet.bicep' = {
  name: 'deploy-${vnetName}'
  params: {
    virtualNetworkName: vnetName
    subnets: subnets
    tags: {
      app: appName
    }
  }
}
