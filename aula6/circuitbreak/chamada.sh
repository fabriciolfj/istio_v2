URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');

fortio load -H "Host: simple-web.istioinaction.io" \
-quiet -jitter -t 30s -c 2 -qps 1 http://$URL/