URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');
curl -s -H "Host: simple-web.istioinaction.io" http://$URL/;
#for in in {1..10}; do \
#curl -s -H "Host: simple-web.istioinaction.io" http://$URL/; done