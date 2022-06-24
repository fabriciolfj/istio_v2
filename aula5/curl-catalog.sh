URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');

for i in {1..10}; do curl http://$URL/items -H "Host: catalog.istioinaction.io" -H "x-istio-cohort: internal"; done