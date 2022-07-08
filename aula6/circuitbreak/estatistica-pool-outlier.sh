kubectl exec -it deploy/simple-web -c istio-proxy -- \
curl localhost:15000/stats | grep simple-backend | grep outlier
