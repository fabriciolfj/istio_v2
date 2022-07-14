URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');

#for i in {1..100}; do curl http://$URL/api/catalog -H "Host: webapp.istioinaction.io" | grep -i imageUrl; done | wc -l # -H "x-istio-cohort: internal"
for i in {1..100}; do curl http://$URL/api/catalog -H "Host: webapp.istioinaction.io"; sleep .5s; done
#while true; do curl http://$URL/api/catalog -H "Host: webapp.istioinaction.io" ; sleep 1; done