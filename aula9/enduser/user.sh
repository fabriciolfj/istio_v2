URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');

USER_TOKEN=$(< user.jwt); \
   curl -H "Host: webapp.istioinaction.io" \
        -H "Authorization: Bearer $USER_TOKEN" \
        -sSl -o /dev/null -w "%{http_code}" $URL/api/catalog