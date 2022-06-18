curl -v -H "Host: catalog.istioinaction.io" \
https://catalog.istioinaction.io:443/items \
--cacert /Users/fabriciojacob/Documents/repositorios/istio_v2/aula4/certs2/2_intermediate/certs/ca-chain.cert.pem \
--resolve catalog.istioinaction.io:443:10.102.146.250