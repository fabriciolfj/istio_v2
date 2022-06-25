CATALOG_V1=$(kubectl get pod -l app=catalog -l version=v1 \
-o jsonpath={.items..metadata.name});

kubectl logs $CATALOG_V1 -c catalog

echo '=============='

CATALOG_V2=$(kubectl get pod -l app=catalog -l version=v2 \
-o jsonpath={.items..metadata.name});

kubectl logs $CATALOG_V2 -c catalog