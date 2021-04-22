az group create -n aks-demo --location uksouth
az deployment group create -f ./deploy.bicep -g aks-dev
