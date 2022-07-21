URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');

curl -H "x-envoy-force-trace: true"  \
-H "Host: webapp.istioinaction.io" http://$URL/api/catalog