kubectl -n default exec deploy/sleep -c sleep -- \
     curl -s webapp.istioinaction/api/catalog
