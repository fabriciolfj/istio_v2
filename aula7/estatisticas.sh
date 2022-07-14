 kubectl exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/stats | grep catalog