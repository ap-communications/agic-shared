targetScope = 'subscription'

param appName string = 'agicdemo'
param location string = 'japaneast'

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rg-${appName}'
  location: location
  tags: {
      app: appName
  }
}

module vnet 'bicep/vn.bicep' = {
  name: 'vnet'
  scope: rg
}

module aks1 'bicep/aks.bicep' = {
  name: 'aks-cluster-1'
  params: {
    clusterName: '${appName}-aks1'
    subnetName: 'aks1-subnet'
  }
  dependsOn: [
    vnet
  ]
  scope: rg
}

module aks2 'bicep/aks.bicep' = {
  name: 'aks-cluster-2'
  params: {
    clusterName: '${appName}-aks2'
    subnetName: 'aks2-subnet'
  }
  dependsOn: [
    vnet
    aks1
  ]
  scope: rg
}

module ag 'bicep/ag.bicep' = {
  name: 'application-gateway'
  dependsOn: [
    aks1
    aks2
  ]
  scope: rg
}
