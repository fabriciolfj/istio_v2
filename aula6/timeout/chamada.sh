URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');

for in in {1..10}; do time curl -s \
-H "Host: simple-web.istioinaction.io" http://$URL/ \
| jq .code; printf "\n"; done