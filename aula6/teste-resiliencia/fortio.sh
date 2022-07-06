URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');
fortio curl -H "Host: simple-web.istioinaction.io" http://$URL/;