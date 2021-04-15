# App Development with Kubernetes and AKS

This demo starts from an empty folder and talks though building and deploying a dotnet api to Docker/Kind/AKS.  The project contained in this repo adds a vuejs web app for a more advanced demo.

## Pre-req

Make sure the kind cluster has no deployments in it.
Set kind cluster as current
`kubectl delete deployment weather-deployment -n weather`

## Explain tech

Docker - Works on my machine
Kubernetes vs AKS
Terms - Image (specific version or tag), Registry, Namespace, Pod, Deployment, Service, Ingress

## Explain local setup

Local windows machine running WSL2 - Ubuntu distribution, can be run on windows too but just to highlight as an option.
Docker for windows (WSL2 mode)
VSCode with a couple of extensions (Docker, Kubernetes, RestClient, Azure)
Kind - Local K8S cluster (runs in containers)
Windows Terminal

## Show remote setup

Simple AKS cluster deployed to Azure 
ACR 


# Lets create an API to test

Open Ubuntu in terminal
create aksdemo folder in ~/dev/aks
`cd ~/dev/aks && mkdir aksdemo && cd aksdemo`
`code .`
Opens local VSCode client connected to remote WSL process as the backend (show terminal)

Create .net web api
`dotnet new webapi`

Amend WeatherController to load summary from app settings/Environment variables
Class should look like this..

    public class WeatherForecastController : ControllerBase
    {
        private readonly ILogger<WeatherForecastController> _logger;
        private readonly IConfiguration _configuration;

        public WeatherForecastController(ILogger<WeatherForecastController> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
        }

        [HttpGet]
        public IEnumerable<WeatherForecast> Get()
        {
            var rng = new Random();
            return Enumerable.Range(1, 5).Select(index => new WeatherForecast
            {
                Date = DateTime.Now.AddDays(index),
                TemperatureC = rng.Next(-20, 55),
                Summary = _configuration.GetValue<string>("CurrentHost"),
            })
            .ToArray();
        }
    }

Add the `using Microsoft.Extensions.Configuration;` namespace to the top of the file

Add CurrentHost to appsettings.Development.json

    {
        "Logging": {
            "LogLevel": {
            "Default": "Information",
            "Microsoft": "Warning",
            "Microsoft.Hosting.Lifetime": "Information"
            }
        },
        "CurrentHost" : "Local Machine"
    }


build and run the application to make sure it is working.
`dotnet run`

create a file tests.http and add the following..

    GET http://localhost:5000/WeatherForecast
    Content-Type: application/json

call it and show the response containing "Local Machine"
Stop debugging

## Lets wrap this application in a docker container

Press F1, add docker files to workspace

ASPNET Core, Linux, 80, No to Docker Compose

Talk through create docker file
Using image from trusted public repository
restores and build the project
produces a final container with only the built assets (no SDKs)

When we publish the dotapp, the app settings isn't included (is for dev only) so we need to pass the parameter in.
Modify the docker file to change the CurrentHost value (Just after the final WORKDIR command)

    ENV CurrentHost="Local WSL Docker"

Build and tag the container image

    docker build -t simpledemo/weather:v1 .

Note: if layers arn't cached may take a couple of mintes while they are downloaded, if so may need to make the changes to ENV , start the build and then talk about the docker file

Run the image

    docker run -it --rm -p 5005:80 simpledemo/weather:v1

Show the container running in the VSCode extension, explain port mapping, explain commands, -it for interactive mode (to see the logs), --rm to stop the container when I close the shell

In tests.http add a new record (seperated by ###)

    GET http://localhost:5005/WeatherForecast
    Content-Type: application/json

## Run on a local cluster

Kind is a local K8S cluster running in docker containers (minikube is an alternative)
[Show the kind container running in the Docker extension]
It shows up as a full K8S cluster (see the kubernetes extension)

In order to run our container on kind we can either upload the image to a public docker registry or load the image directly onto the cluster (which acts as it's own repository)

    kind load docker-image simpledemo/weather:v1

create our yaml file (api-kind.yml)

    apiVersion: v1
    kind: Namespace
    metadata:
    name: weather

    ---

    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: weather-deployment
    namespace: weather
    labels:
        app: weather
    spec:
    replicas: 2
    selector:
        matchLabels:
        app: weather
    template:
        metadata:
        labels:
            app: weather
        spec:
        containers:
        - name: weather
            image: "simpledemo/weather:v1"
            ports:
            - containerPort: 80
            env:
            - name: CurrentHost
            value: 'Kind-Cluster'
    ---
    apiVersion: v1
    kind: Service
    metadata:
    name: weather-service
    namespace: weather
    spec:
    selector:
        app: weather
    ports:
    - protocol: TCP
        port: 80
        targetPort: 80
    type: ClusterIP

Talk through what we are creating 
A weather namespace for logical segregation of content/layers
A deployment of pods (multiple running replicas of the target container)
A service (effectively an internal load balancer for the pods)

Deploy the yaml file

    kubectl apply -f "api-kind.yml"

Show running pods using kubectl 

    kubectl get pods -n weather

To test the api I can either create an ingress controller or using the tooling to forward the internal port to a port on my local machine using ...

    kubectl port-forward -n weather service/weather-service 5010:80

Now back to tests.http and add 

    GET http://localhost:5010/WeatherForecast
    Content-Type: application/json

In a real work scenario you would use the kind cluster cluster to test how the various microservices interact before you deploy to a cloud AKS cluster.  Each of the internal services can be accessed inside the cluster using the K8S dns resolution (e.g. http://weatherserivce)

[Ctrl+C to stop the port forwarding]

# Finally lets deploy to AKS

First we need to upload our container to a container registry
We need to login to the registry (might need to az login first)

    az acr login -n acrdevdemo -g aks-dev

We then need to tag our image with the acr name 

    docker tag simpledemo/weather:v1 acrdevdemo.azurecr.io/simpledemo/weather:v1

Then we push our image to the registry

    docker push acrdevdemo.azurecr.io/simpledemo/weather:v1

Show the image in the repository in ACR.

Now that the image is available in a repo we can use that to deploy to AKS.

Create a new deployment file (api-aks.yml) - copy the local one and change the image name and the CurrentHost

    apiVersion: v1
    kind: Namespace
    metadata:
    name: weather

    ---

    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: weather-deployment
    namespace: weather
    labels:
        app: weather
    spec:
    replicas: 2
    selector:
        matchLabels:
        app: weather
    template:
        metadata:
        labels:
            app: weather
        spec:
        containers:
        - name: weather
            image: "acrdevdemo.azurecr.io/simpledemo/weather:v1"
            ports:
            - containerPort: 80
            env:
            - name: CurrentHost
            value: 'AKS-Cluster'
    ---
    apiVersion: v1
    kind: Service
    metadata:
    name: weather-service
    namespace: weather
    spec:
    selector:
        app: weather
    ports:
    - protocol: TCP
        port: 80
        targetPort: 80
    type: ClusterIP

Before we deploy we need to switch from our kind cluster to our AKS (do this via the extension or az aks get-credentials) - confirm the switch using `kubectl get nodes` or `kubectl get ns`
Deploy the yaml file

    kubectl apply -f "api-aks.yml"

Show running pods using kubectl 

    kubectl get pods -n weather

To test the api I can either create an ingress controller or using the tooling to forward the internal port to a port on my local machine using ...

    kubectl port-forward -n weather service/weather-service 5015:80    

Now back to tests.http and add 

    GET http://localhost:5015/WeatherForecast
    Content-Type: application/json

The Summary should now show that is running from the AKS cluster
Lets looks at that running in the portal
Open portal.azure.com and look at running AKS cluster.
Talk through weather namespace events, workloads (drill into pods), show insights and how it links with log analytics/azure monitor
Show the recommendations
Show the existing web/apis pod and ingress controller
Show the github repo these came from and show the github actions that were used to deploy it.
https://github.com/fortunkam/aks-dev-sample

Highlight the 2 phase approach (ACR => AKS)
Highlight the tasks using the hash values to create a new container version on each deploy.

Questions
























