minikube config set driver hyperkit
minikube start
istioctl install --set profile=demo -y
kubectl apply -f ./istio-1.14.0/samples/addons

kubectl create ns istioinaction
kubectl label namespace istioinaction istio-injection=enabled