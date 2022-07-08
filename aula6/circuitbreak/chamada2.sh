URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');

fortio load -H "Host: simple-web.istioinaction.io" \
-allow-initial-errors -quiet -jitter -t 30s -c 10 -qps 20 http://$URL/