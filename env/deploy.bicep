param aksName string = 'mf-aks-demo'
param acrName string = 'acrdevdemo'

var rg_location = resourceGroup().location
var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acr 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  name: acrName
  location: rg_location
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: true    
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  name: aksName
  location: rg_location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.20.5'
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        mode: 'System'
        count: 1
        vmSize: 'Standard_D2_v2'
      }
    ]
    networkProfile: {
      networkPlugin:'kubenet'
    }
    enableRBAC:true
    dnsPrefix: '${aksName}-dns'
  }
}

resource aks_acr_pull 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, acrName)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRole    
    principalType: 'ServicePrincipal'
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
  }
}
