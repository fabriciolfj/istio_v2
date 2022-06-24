URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');

curl http://$URL/api/catalog -H "Host: webapp.istioinaction.io" # -H "x-istio-cohort: internal"