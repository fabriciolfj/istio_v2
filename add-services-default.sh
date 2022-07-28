kubectl label namespace istioinaction istio-injection=enabled
kubectl apply -f services/catalog/kubernetes/catalog.yaml
kubectl apply -f services/webapp/kubernetes/webapp.yaml
kubectl apply -f services/webapp/istio/webapp-catalog-gw-vs.yaml