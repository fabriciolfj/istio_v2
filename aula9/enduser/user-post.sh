URL=$(kubectl -n istio-system get svc istio-ingressgateway \
-o jsonpath='{.status.loadBalancer.ingress[0].ip}');

USER_TOKEN=$(< user.jwt); \
curl -H "Host: webapp.istioinaction.io" \
             -H "Authorization: Bearer $USER_TOKEN" \
             -XPOST $URL/api/catalog \
             --data '{"id": 2, "name": "Shoes", "price": "84.00"}'