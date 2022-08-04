URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');

   curl -H "Host: webapp.istioinaction.io" \
        -sSl -o /dev/null -w "%{http_code}" $URL/api/catalog