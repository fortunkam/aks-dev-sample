## Local Run

    dotnet run

## Docker Run

To run as a docker container, build first with

    docker build . -t aksdemo/api:v1

then run 

    docker run -d -p 5005:80 aksdemo/api:v1

api now available on port 5005 (http://localhost:5005/WeatherForecast)

## Kind run

To create the kind cluster

    kind create cluster


To see the kind cluster

    kubectl cluster-info --context kind-kind

Load the docker image into the cluster

    kind load docker-image aksdemo/api:v1

To see the images installed on the cluster

    docker exec -it kind-control-plane crictl images

Create a deployment

    kubectl apply -f "deploy-local.yaml"

Forward the service port

    kubectl port-forward -n api service/api-service 5010:80

and call on port 5010

## ACR Push (from developer machine)

    az acr login -n acrdevdemo -g aks-dev
    docker tag aksdemo/api:v1 acrdevdemo.azurecr.io/aksdemo/api:v1
    docker push acrdevdemo.azurecr.io/aksdemo/api:v1

Image should now be in the ACR (repositories tab of ACR)

## AKS Deploy (from developer machine)

Setup the ingress controller

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.45.0/deploy/static/provider/cloud/deploy.yaml

API will also be available as http://<ingres_public_ip>/api/WeatherForecast
Note `api/deploy-aks.yaml` will need to be updated with the correct acr name
If not created at same time will need to attach ACR to AKS (az aks attach-acr?)

    kubectl apply -f "deploy-aks.yaml"
    kubectl port-forward -n api service/api-service 5015:80

## ACR Deploy from CI/CD

## AKS deploy from CI/CD










