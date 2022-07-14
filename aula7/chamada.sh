URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');

curl -H "Host: webapp.istioinaction.io" http://10.100.82.226/api/catalog