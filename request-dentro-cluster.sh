kubectl run -i -n default - -rm --restart=Never dummy --image=curlimages/curl --command -- sh -c 'curl -s http://catalog.istioinaction/items'